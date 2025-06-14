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
          item.margin = 8.0
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
        actual_xml = Croatia::Fiscalizer::XMLBuilder.invoice(
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
                  <tns:Stopa>25.00</tns:Stopa>
                  <tns:Osnovica>20.00</tns:Osnovica>
                  <tns:Iznos>5.00</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>13.00</tns:Stopa>
                  <tns:Osnovica>8.00</tns:Osnovica>
                  <tns:Iznos>1.04</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>0.00</tns:Stopa>
                  <tns:Osnovica>45.00</tns:Osnovica>
                  <tns:Iznos>0.00</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:Pnp>
                <tns:Porez>
                  <tns:Stopa>5.00</tns:Stopa>
                  <tns:Osnovica>8.00</tns:Osnovica>
                  <tns:Iznos>0.40</tns:Iznos>
                </tns:Porez>
                <tns:Porez>
                  <tns:Stopa>5.00</tns:Stopa>
                  <tns:Osnovica>45.00</tns:Osnovica>
                  <tns:Iznos>2.25</tns:Iznos>
                </tns:Porez>
              </tns:Pnp>
              <tns:OstaliPor>
                <tns:Porez>
                  <tns:Naziv/>
                  <tns:Stopa>1.00</tns:Stopa>
                  <tns:Osnovica>45.00</tns:Osnovica>
                  <tns:Iznos>0.45</tns:Iznos>
                </tns:Porez>
              </tns:OstaliPor>
              <tns:IznosOslobPdv>45.00</tns:IznosOslobPdv>
              <tns:IzonsMarza>8.00</tns:IzonsMarza>
              <tns:Naknade>
                <tns:Naknada>
                  <tns:NazivN>Environmental fee</tns:NazivN>
                  <tns:IznosN>1.50</tns:IznosN>
                </tns:Naknada>
              </tns:Naknade>
              <tns:IznosUkupno>87.64</tns:IznosUkupno>
              <tns:NacinPlac>K</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>7ea181735d8ae4098e2a763c2179c811</tns:ZastKod>
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

  def test_supporting_document_with_unique_identifier
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          certificate: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 789,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5,
          sequential_by: :register,
        )

        invoice.issuer do |issuer|
          issuer.pin = "86988477146"
        end

        invoice.seller do |seller|
          seller.pin = "05575695113"
          seller.pays_vat = true
        end

        invoice.add_line_item do |item|
          item.description = "Supporting doc item"
          item.quantity = 1
          item.unit_price = 100.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        message_id = "supporting-doc-test-uuid-12345678901"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.supporting_document(
          invoice: invoice,
          message_id: message_id,
          unique_identifier: "test-jir-unique-identifier-123",
          subsequent_delivery: false
        )

        expected_xml = <<~XML
          <tns:RacunPDZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
            <tns:Zaglavlje>
              <tns:IdPoruke>supporting-doc-test-uuid-12345678901</tns:IdPoruke>
              <tns:DatumVrijemeSlanja>04.06.2025T07:44:31</tns:DatumVrijemeSlanja>
            </tns:Zaglavlje>
            <tns:Racun>
              <tns:Oib>05575695113</tns:Oib>
              <tns:USustPdv>true</tns:USustPdv>
              <tns:DatVrijeme>04.06.2025T07:44:26</tns:DatVrijeme>
              <tns:OznSlijed>N</tns:OznSlijed>
              <tns:BrRac>
                <tns:BrOznRac>789</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
              <tns:Pdv>
                <tns:Porez>
                  <tns:Stopa>25.00</tns:Stopa>
                  <tns:Osnovica>100.00</tns:Osnovica>
                  <tns:Iznos>25.00</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:IznosUkupno>125.00</tns:IznosUkupno>
              <tns:NacinPlac>K</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>ff3812ca784e70ce092a9f9028ba5308</tns:ZastKod>
              <tns:NakDost>false</tns:NakDost>
              <tns:PrateciDokument>
                <tns:JirPD>test-jir-unique-identifier-123</tns:JirPD>
              </tns:PrateciDokument>
            </tns:Racun>
          </tns:RacunPDZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end

  def test_supporting_document_with_issuer_protection_code
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          certificate: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 456,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5,
          sequential_by: :register,
        )

        invoice.issuer do |issuer|
          issuer.pin = "86988477146"
        end

        invoice.seller do |seller|
          seller.pin = "05575695113"
          seller.pays_vat = true
        end

        invoice.add_line_item do |item|
          item.description = "Supporting doc item"
          item.quantity = 2
          item.unit_price = 50.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        message_id = "support-doc-zki-test-uuid-1234567890"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.supporting_document(
          invoice: invoice,
          message_id: message_id,
          issuer_protection_code: "test-issuer-protection-code-zki-456",
          subsequent_delivery: true
        )

        expected_xml = <<~XML
          <tns:RacunPDZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
            <tns:Zaglavlje>
              <tns:IdPoruke>support-doc-zki-test-uuid-1234567890</tns:IdPoruke>
              <tns:DatumVrijemeSlanja>04.06.2025T07:44:31</tns:DatumVrijemeSlanja>
            </tns:Zaglavlje>
            <tns:Racun>
              <tns:Oib>05575695113</tns:Oib>
              <tns:USustPdv>true</tns:USustPdv>
              <tns:DatVrijeme>04.06.2025T07:44:26</tns:DatVrijeme>
              <tns:OznSlijed>N</tns:OznSlijed>
              <tns:BrRac>
                <tns:BrOznRac>456</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
              <tns:Pdv>
                <tns:Porez>
                  <tns:Stopa>25.00</tns:Stopa>
                  <tns:Osnovica>100.00</tns:Osnovica>
                  <tns:Iznos>25.00</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:IznosUkupno>125.00</tns:IznosUkupno>
              <tns:NacinPlac>K</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>a086b4f9eccced0dcb7664ab8e04bae8</tns:ZastKod>
              <tns:NakDost>true</tns:NakDost>
              <tns:PrateciDokument>
                <tns:ZastKodPD>test-issuer-protection-code-zki-456</tns:ZastKodPD>
              </tns:PrateciDokument>
            </tns:Racun>
          </tns:RacunPDZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end

  def test_supporting_document_validation_errors
    config = Croatia::Config.new(
      fiscalization: {
        certificate: file_fixture("fake_fiskal1.p12").read,
        password: file_fixture("fake_fiskal1_password.txt").read.strip
      }
    )

    Croatia.with_config(config) do
      invoice = Croatia::Invoice.new(
        sequential_number: 123,
        business_location_identifier: "POSL1",
        register_identifier: "12",
        issue_date: Time.now,
        sequential_by: :register,
      )

      invoice.issuer { |i| i.pin = "86988477146" }
      invoice.seller { |s| s.pin = "05575695113"; s.pays_vat = true }
      invoice.add_line_item { |i| i.description = "Test"; i.unit_price = 100.0 }

      message_id = "test-validation-uuid-1234567890123456"

      # Test error when both unique_identifier and issuer_protection_code are provided
      assert_raises(ArgumentError, "Either unique_identifier or issuer_protection_code must be provided, not both.") do
        Croatia::Fiscalizer::XMLBuilder.supporting_document(
          invoice: invoice,
          message_id: message_id,
          unique_identifier: "test-jir",
          issuer_protection_code: "test-zki"
        )
      end

      # Test error when neither unique_identifier nor issuer_protection_code are provided
      assert_raises(ArgumentError, "Either unique_identifier or issuer_protection_code must be provided") do
        Croatia::Fiscalizer::XMLBuilder.supporting_document(
          invoice: invoice,
          message_id: message_id
        )
      end
    end
  end

  def test_invoice_payment_method_change
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          certificate: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 111,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5,
          sequential_by: :register,
          payment_method: :cash  # Original payment method
        )

        invoice.issuer do |issuer|
          issuer.pin = "86988477146"
        end

        invoice.seller do |seller|
          seller.pin = "05575695113"
          seller.pays_vat = true
        end

        invoice.add_line_item do |item|
          item.description = "Payment method change item"
          item.quantity = 1
          item.unit_price = 100.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.invoice_payment_method_change(
          :card,  # New payment method
          invoice: invoice,
          message_id: message_id,
          subsequent_delivery: false
        )

        expected_xml = <<~XML
          <tns:PromijeniNacPlacZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
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
                <tns:BrOznRac>111</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
              <tns:Pdv>
                <tns:Porez>
                  <tns:Stopa>25.00</tns:Stopa>
                  <tns:Osnovica>100.00</tns:Osnovica>
                  <tns:Iznos>25.00</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:IznosUkupno>125.00</tns:IznosUkupno>
              <tns:NacinPlac>G</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>a844376b0b6c9cba56f85445f4ced6ac</tns:ZastKod>
              <tns:NakDost>false</tns:NakDost>
              <tns:PromijenjeniNacinPlac>K</tns:PromijenjeniNacinPlac>
            </tns:Racun>
          </tns:PromijeniNacPlacZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end

  def test_supporting_document_payment_method_change
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          certificate: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 222,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5,
          sequential_by: :register,
          payment_method: :transfer  # Original payment method
        )

        invoice.issuer do |issuer|
          issuer.pin = "86988477146"
        end

        invoice.seller do |seller|
          seller.pin = "05575695113"
          seller.pays_vat = true
        end

        invoice.add_line_item do |item|
          item.description = "Supporting doc payment change"
          item.quantity = 2
          item.unit_price = 50.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.supporting_document_payment_method_change(
          :cash,  # New payment method
          invoice: invoice,
          message_id: message_id,
          unique_identifier: "test-jir-payment-change-123",
          subsequent_delivery: true
        )

        expected_xml = <<~XML
          <tns:PromijeniNacPlacZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
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
                <tns:BrOznRac>222</tns:BrOznRac>
                <tns:OznPosPr>POSL1</tns:OznPosPr>
                <tns:OznNapUr>12</tns:OznNapUr>
              </tns:BrRac>
              <tns:Pdv>
                <tns:Porez>
                  <tns:Stopa>25.00</tns:Stopa>
                  <tns:Osnovica>100.00</tns:Osnovica>
                  <tns:Iznos>25.00</tns:Iznos>
                </tns:Porez>
              </tns:Pdv>
              <tns:IznosUkupno>125.00</tns:IznosUkupno>
              <tns:NacinPlac>T</tns:NacinPlac>
              <tns:OibOper>86988477146</tns:OibOper>
              <tns:ZastKod>5dfd19829a93d1cd4faac1b1c0ce6f32</tns:ZastKod>
              <tns:NakDost>true</tns:NakDost>
              <tns:PrateciDokument>
                <tns:JirPD>test-jir-payment-change-123</tns:JirPD>
              </tns:PrateciDokument>
              <tns:PromijenjeniNacinPlac>G</tns:PromijenjeniNacinPlac>
            </tns:Racun>
          </tns:PromijeniNacPlacZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end

  def test_payment_method_change_validation
    config = Croatia::Config.new(
      fiscalization: {
        certificate: file_fixture("fake_fiskal1.p12").read,
        password: file_fixture("fake_fiskal1_password.txt").read.strip
      }
    )

    Croatia.with_config(config) do
      invoice = Croatia::Invoice.new(
        sequential_number: 333,
        business_location_identifier: "POSL1",
        register_identifier: "12",
        issue_date: Time.now,
        sequential_by: :register,
      )

      invoice.issuer { |i| i.pin = "86988477146" }
      invoice.seller { |s| s.pin = "05575695113"; s.pays_vat = true }
      invoice.add_line_item { |i| i.description = "Test"; i.unit_price = 100.0 }

      message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"

      # Test error when invalid payment method is provided
      assert_raises(KeyError) do
        Croatia::Fiscalizer::XMLBuilder.invoice_payment_method_change(
          :invalid_method,
          invoice: invoice,
          message_id: message_id
        )
      end
    end
  end
end
