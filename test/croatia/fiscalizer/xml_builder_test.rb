# frozen_string_literal: true

require "test_helper"

class Croatia::Fiscalizer::XMLBuilderTest < Minitest::Test
  include FixturesHelper
  include XMLHelper
  include CertificateHelper

  REFERENCE_TIME = Time.new(2025, 06, 04, 07, 44, 31, "+02:00")

  def test_invoice_request
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          certificate: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip
        }
      )

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
          issuer.pin = "86988477146"
        end

        invoice.seller do |seller|
          seller.pin = "05575695113"
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
          item.add_surcharge(name: "Environmental fee", amount: 1.50)
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
          paragon_number: "123/458/5"
        )

        expected_xml = <<~XML
          <tns:RacunZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
            <tns:Zaglavlje>
              <tns:IdPoruke>c2bb23ad-7044-4b06-b259-04475acecc1e</tns:IdPoruke>
              <tns:DatumVrijemeSlanja>04.06.2025T07:44:31</tns:DatumVrijemeSlanja>
            </tns:Zaglavlje>
            <tns:Racun>
              <tns:Oib>05575695113</tns:Oib>
              <tns:USustPdv>true</tns:USustPdv>
              <tns:DatVrijeme>04.06.2025T07:44:26</tns:DatVrijeme>
              <tns:OznSlijed>N</tns:OznSlijed>
              <tns:BrRac>
                <tns:BrOznRac>123456789</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
              <tns:Pdv>
                <tns:Porez>
                  <tns:Stopa>25.0</tns:Stopa>
                  <tns:Osnovica>20.0</tns:Osnovica>
                  <tns:Iznos>5.0</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>13.0</tns:Stopa>
                  <tns:Osnovica>12.0</tns:Osnovica>
                  <tns:Iznos>1.56</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>0.0</tns:Stopa>
                  <tns:Osnovica>45.0</tns:Osnovica>
                  <tns:Iznos>0.0</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:Pnp>
                <tns:Porez>
                  <tns:Stopa>5.0</tns:Stopa>
                  <tns:Osnovica>12.0</tns:Osnovica>
                  <tns:Iznos>0.6</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>5.0</tns:Stopa>
                  <tns:Osnovica>45.0</tns:Osnovica>
                  <tns:Iznos>2.25</tns:Iznos>
                </tns:Porez>
              </tns:Pnp>
              <tns:OstaliPor>
                <tns:Porez>
                  <tns:Naziv/>
                  <tns:Stopa>1.0</tns:Stopa>
                  <tns:Osnovica>45.0</tns:Osnovica>
                  <tns:Iznos>0.45</tns:Iznos>
                </tns:Porez>
              </tns:OstaliPor>
              <tns:IznosOslobPdv>45.0</tns:IznosOslobPdv>
              <tns:Naknade>
                <tns:Naknada>
                  <tns:NazivN>Environmental fee</tns:NazivN>
                  <tns:IznosN>1.5</tns:IznosN>
                </tns:Naknada>
              </tns:Naknade>
              <tns:IznosUkupno>88.36</tns:IznosUkupno>
              <tns:NacinPlac>K</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>0cd027f64499f3683ff97d1a1b62741f</tns:ZastKod>
              <tns:NakDost>false</tns:NakDost>
              <tns:ParagonBrRac>123/458/5</tns:ParagonBrRac>
              <tns:SpecNamj>TEST</tns:SpecNamj>
            </tns:Racun>
          </tns:RacunZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end
end
