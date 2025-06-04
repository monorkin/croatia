# frozen_string_literal: true

require "test_helper"

class Croatia::Fiscalizer::XMLBuilderTest < Minitest::Test
  include FixturesHelper
  include XMLHelper
  include CertificateHelper

  REFERENCE_TIME = Time.new(2025, 06, 04, 07, 44, 31, "+02:00")

  def test_invoice_request
    config = Croatia::Config.new(
      fiscalization: {
        certificate: file_fixture("fake_fiskal1.p12").read,
        password: file_fixture("fake_fiskal1_password.txt").read.strip
      }
    )

    Timecop.freeze(REFERENCE_TIME) do
      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 123456789,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5, # 5 seconds ago
          sequential_by: :register,
        )

        invoice.due_date = invoice.issue_date + 15 * 24 * 60 * 60 # 15 days later

        invoice.issuer do |issuer|
          issuer.pin = "01234567890"
        end

        invoice.seller do |seller|
          seller.pin = "98765432198"
          seller.pays_vat = true
        end

        invoice.add_line_item do |item|
          item.description = "Dog walking"
          item.quantity = 2
          item.unit = "HRS"
          item.unit_price = 10.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        invoice.add_line_item do |item|
          item.description = "Dog treats"
          item.quantity = 6
          item.unit = "PCS"
          item.unit_price = 2.0
          item.add_tax(type: :value_added_tax, category: :lower_rate)
          item.add_tax(type: :consumption_tax, category: :standard, rate: 0.05)
        end

        invoice.add_line_item do |item|
          item.description = "Dog vitamin drink"
          item.quantity = 1
          item.unit = "PCS"
          item.unit_price = 45.0
          item.add_tax(type: :value_added_tax, category: :exempt)
          item.add_tax(type: :consumption_tax, category: :standard, rate: 0.05)
          item.add_tax(type: :other, category: :standard, rate: 0.01)
        end

        message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.invoice_request(
          invoice: invoice,
          message_id: message_id,
          subsequent_delivery: false,
          specific_purpose: "TEST",
        )

        expected_xml = <<~XML
          <tns:RacunZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
            <tns:Zaglavlje>
              <tns:IdPoruke>c2bb23ad-7044-4b06-b259-04475acecc1e</tns:IdPoruke>
              <tns:DatumVrijemeSlanja>04.06.2025T07:44:31</tns:DatumVrijemeSlanja>
            </tns:Zaglavlje>
            <tns:Racun>
              <tns:Oib>98765432198</tns:Oib>
              <tns:USustPdv>true</tns:USustPdv>
              <tns:DatVrijeme>04.06.2025T07:44:26</tns:DatVrijeme>
              <tns:OznSlijed>N</tns:OznSlijed>
              <tns:BrRac>
                <tns:BrOznRac>123456789</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
            <tns:IznosUkupno>86.86</tns:IznosUkupno>
              <tns:NacinPlac>K</tns:NacinPlac>
              <tns:OibOper>01234567890</tns:OibOper>
              <tns:ZastKod>01ad8d8cf0cb002e28fd68a6db6387f2</tns:ZastKod>
              <tns:NakDost>false</tns:NakDost>
              <tns:ParagonBrRac>123456789/POSL1/12</tns:ParagonBrRac>
              <tns:SpecNamj>TEST</tns:SpecNamj>
            </tns:Racun>
          </tns:RacunZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end
end
