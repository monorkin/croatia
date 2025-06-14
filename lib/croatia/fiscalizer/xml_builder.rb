# frozen_string_literal: true

require "rexml/document"

module Croatia::Fiscalizer::XMLBuilder
  TNS = "http://www.apis-it.hr/fin/2012/types/f73"
  XSI = "http://www.w3.org/2001/XMLSchema-instance"
  INVOICE_ENVELOPE = "RacunZahtjev"
  SUPPORTING_DOCUMENT_ENVELOPE = "RacunPDZahtjev"
  SEQUENCE_MARK = {
    register: "N", # N - sequential by register
    business_location: "P" # P - sequential by business location
  }.freeze
  PAYMENT_METHODS = {
    cash: "G", # G - gotovina
    card: "K", # K - kartica
    check: "C", # C - ček
    transfer: "T", # T - prijenos / virmansko placanje
    other: "O" # O - ostalo
  }.freeze

  class << self
    def invoice(invoice:, message_id:, timezone: Croatia::Fiscalizer::TZ, **options)
      build(
        invoice: invoice,
        message_id: message_id,
        timezone: timezone,
        envelope: INVOICE_ENVELOPE,
        **options.except(:supporting_document)
      )
    end

    def supporting_document(invoice:, message_id:, unique_identifier: nil, issuer_protection_code: nil, timezone: Croatia::Fiscalizer::TZ, **options)
      build(
        invoice: invoice,
        message_id: message_id,
        timezone: timezone,
        envelope: SUPPORTING_DOCUMENT_ENVELOPE,
        supporting_document: {
          unique_identifier: unique_identifier,
          issuer_protection_code: issuer_protection_code
        },
        **options
      )
    end

    private

      def build(envelope:, invoice:, message_id:, timezone: Croatia::Fiscalizer::TZ, **options)
        if message_id.nil? || message_id.length != 36
          raise ArgumentError, "Message ID must be a valid UUID (36 characters long)"
        end

        if options[:paragon_number] && options[:paragon_number].to_s.length > 100
          raise ArgumentError, "Paragon number must be less than 100 characters long"
        end

        if options[:specific_purpose] && options[:specific_purpose].length > 1000
          raise ArgumentError, "Specific purpose must be less than 1000 characteres long"
        end

        REXML::Document.new.tap do |doc|
          envelope = doc.add_element("tns:#{envelope}", {
            "xmlns:tns" => TNS,
            "xmlns:xsi" => XSI
          })

          envelope.add_element("tns:Zaglavlje").tap do |header|
            header.add_element("tns:IdPoruke").text = message_id
            header.add_element("tns:DatumVrijemeSlanja").text = timezone.now.strftime("%d.%m.%YT%H:%M:%S")
          end

          envelope.add_element("tns:Racun").tap do |payload|
            payload.add_element("tns:Oib").text = invoice.seller.pin
            payload.add_element("tns:USustPdv").text = invoice.seller.pays_vat ? "true" : "false"
            payload.add_element("tns:DatVrijeme").text = timezone.to_local(invoice.issue_date).strftime("%d.%m.%YT%H:%M:%S")
            payload.add_element("tns:OznSlijed").text = SEQUENCE_MARK.fetch(invoice.sequential_by)

            payload.add_element("tns:BrRac").tap do |invoice_number|
              invoice_number.add_element("tns:BrOznRac").text = invoice.sequential_number.to_s
              invoice_number.add_element("tns:OznPosPr").text = invoice.business_location_identifier.to_s
              invoice_number.add_element("tns:OznNapUr").text = invoice.register_identifier.to_s
            end

            tax_breakdown = invoice.tax_breakdown

            if tax_breakdown.key?(:value_added_tax)
              payload.add_element("tns:Pdv").tap do |taxes|
                add_tax_breakdowns(taxes, tax_breakdown[:value_added_tax], name: false)
              end
            end

            if tax_breakdown.key?(:consumption_tax)
              payload.add_element("tns:Pnp").tap do |taxes|
                add_tax_breakdowns(taxes, tax_breakdown[:consumption_tax], name: false)
              end
            end

            if tax_breakdown.key?(:other)
              payload.add_element("tns:OstaliPor").tap do |taxes|
                add_tax_breakdowns(taxes, tax_breakdown[:other], name: true)
              end
            end

            if invoice.vat_exempt_amount.positive?
              payload.add_element("tns:IznosOslobPdv").text = format_decimal(invoice.vat_exempt_amount)
            end

            if invoice.margin.positive?
              payload.add_element("tns:IzonsMarza").text = format_decimal(invoice.margin)
            end

            if invoice.amount_outside_vat_scope.positive?
              payload.add_element("tns:IznosNePodlOpor").text = format_decimal(invoice.amount_outside_vat_scope)
            end

            surcharges = invoice.surcharges

            if surcharges.any?
              payload.add_element("tns:Naknade").tap do |group|
                surcharges.each do |surcharge|
                  group.add_element("tns:Naknada").tap do |item|
                    item.add_element("tns:NazivN").text = surcharge.name
                    item.add_element("tns:IznosN").text = format_decimal(surcharge.amount)
                  end
                end
              end
            end

            payload.add_element("tns:IznosUkupno").text = format_decimal(invoice.total)
            payload.add_element("tns:NacinPlac").text = PAYMENT_METHODS.fetch(invoice.payment_method)
            payload.add_element("tns:OibOper").text = invoice.issuer.pin
            payload.add_element("tns:ZastKod").text = invoice.issuer_protection_code
            payload.add_element("tns:NakDost").text = options[:subsequent_delivery] ? "true" : "false"
            payload.add_element("tns:ParagonBrRac").text = options[:paragon_number] if options[:paragon_number]
            payload.add_element("tns:SpecNamj").text = options[:specific_purpose] if options[:specific_purpose]

            if options[:supporting_document]
              add_supporting_document_elements(payload, **options[:supporting_document])
            end
          end
        end
      end

      def format_decimal(value)
        format("%.2f", value.to_f)
      end

      def add_tax_breakdowns(taxes, breakdowns, name: false)
        breakdowns.each do |breakdown|
          taxes.add_element("tns:Porez").tap do |tax|
            tax.add_element("tns:Naziv").text = breakdown[:name] if name
            tax.add_element("tns:Stopa").text = format_decimal(breakdown[:rate] * 100.0)
            tax.add_element("tns:Osnovica").text = format_decimal(breakdown[:base])
            tax.add_element("tns:Iznos").text = format_decimal(breakdown[:tax])
          end
        end
      end

      def add_supporting_document_elements(payload, unique_identifier: nil, issuer_protection_code: nil)
        if unique_identifier.nil? && issuer_protection_code.nil?
          raise ArgumentError, "Either unique_identifier or issuer_protection_code must be provided"
        end

        if unique_identifier && issuer_protection_code
          raise ArgumentError, "Either unique_identifier or issuer_protection_code must be provided, not both."
        end

        payload.add_element("tns:PrateciDokument").tap do |document|
          document.add_element("tns:JirPD").text = unique_identifier if unique_identifier
          document.add_element("tns:ZastKodPD").text = issuer_protection_code if issuer_protection_code
        end
      end
  end
end
