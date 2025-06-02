# frozen_string_literal: true

require "rexml/document"

module Croatia::Invoice::Fiscalizer::XMLBuilder
  TNS = "http://www.apis-it.hr/fin/2012/types/f73"
  XSI = "http://www.w3.org/2001/XMLSchema-instance"

  class << self
    def invoice_request(invoice:, message_id:, timezone: Croatia::Invoice::Fiscalizer::TZ)
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
        end
      end
    end
  end
end
