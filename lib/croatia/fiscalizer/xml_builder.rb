# frozen_string_literal: true

require "rexml/document"

module Croatia::Fiscalizer::XMLBuilder
  TNS = "http://www.apis-it.hr/fin/2012/types/f73"
  XSI = "http://www.w3.org/2001/XMLSchema-instance"
  SEQUENCE_MARK = {
    register: "N", # N - sequential by register
    business_location: "P" # P - sequential by business location
  }.freeze
  PAYMENT_METHODS = {
    cash: "G", # G - gotovina
    card: "K", # K - kartica
    check: "C", # C - ček
    transfer: "T", # T - prijenos
    other: "O" # O - ostalo
  }.freeze

  class << self
    def invoice_request(invoice:, message_id:, timezone: Croatia::Fiscalizer::TZ, **options)
      REXML::Document.new.tap do |doc|
        envelope = doc.add_element("tns:RacunZahtjev", {
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
          payload.add_element("tns:OznSlijed").text = SEQUENCE_MARK[invoice.sequential_by]

          payload.add_element("tns:BrRac").tap do |invoice_number|
            invoice_number.add_element("tns:BrOznRac").text = invoice.sequential_number.to_s
            invoice_number.add_element("tns:OznPosPr").text = invoice.business_location_identifier.to_s
            invoice_number.add_element("tns:OznNapUr").text = invoice.register_identifier.to_s
          end

          # TODO: Add taxes

          payload.add_element("tns:IznosUkupno").text = invoice.total.to_f.to_s
          payload.add_element("tns:NacinPlac").text = PAYMENT_METHODS[invoice.payment_method]
          payload.add_element("tns:OibOper").text = invoice.issuer.pin
          payload.add_element("tns:ZastKod").text = invoice.issuer_protection_code
          payload.add_element("tns:NakDost").text = options[:subsequent_delivery] ? "true" : "false"
          payload.add_element("tns:ParagonBrRac").text = options[:paragon_number] if options[:paragon_number]
          payload.add_element("tns:SpecNamj").text = options[:specific_purpose] if options[:specific_purpose]
        end
      end
    end
  end
end
