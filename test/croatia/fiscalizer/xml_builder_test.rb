# frozen_string_literal: true

require "test_helper"
require "rexml/document"

class Croatia::Fiscalizer::XMLBuilderTest < Minitest::Test
  include FixturesHelper
  include XMLHelper
  include FiscalizationCredentialsHelper

  REFERENCE_TIME = Time.new(2025, 06, 04, 07, 44, 31, "+02:00")

  def test_invoice_request
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
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
          <tns:RacunZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='c2bb23ad-7044-4b06-b259-04475acecc1e'>
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
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
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
          <tns:RacunPDZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='supporting-doc-test-uuid-12345678901'>
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
              <tns:ZastKod>2b9b3878cdc423b3d767c53cc77ff47c</tns:ZastKod>
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
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
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
          <tns:RacunPDZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='support-doc-zki-test-uuid-1234567890'>
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
              <tns:ZastKod>186d169769f6ba87f0cc103da793fad7</tns:ZastKod>
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
        credential: file_fixture("fake_fiskal1.p12").read,
        password: file_fixture("fake_fiskal1_password.txt").read.strip,
        endpoint: :test
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
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
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
          <tns:PromijeniNacPlacZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='c2bb23ad-7044-4b06-b259-04475acecc1e'>
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
              <tns:ZastKod>f890d7da7eafb868dcd60671b8f3724e</tns:ZastKod>
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
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
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
          <tns:PromijeniNacPlacZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='c2bb23ad-7044-4b06-b259-04475acecc1e'>
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
              <tns:ZastKod>4074af68975fb56c3b567614ecf2bb05</tns:ZastKod>
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
        credential: file_fixture("fake_fiskal1.p12").read,
        password: file_fixture("fake_fiskal1_password.txt").read.strip,
        endpoint: :test
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

  def test_verify
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 555,
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
          item.description = "Verify test item"
          item.quantity = 1
          item.unit_price = 100.0
          item.add_tax(type: :value_added_tax, category: :standard)
        end

        message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"
        actual_xml = Croatia::Fiscalizer::XMLBuilder.verify(
          invoice: invoice,
          message_id: message_id,
          subsequent_delivery: false
        )

        expected_xml = <<~XML
          <tns:ProvjeraZahtjev xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' Id='c2bb23ad-7044-4b06-b259-04475acecc1e'>
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
                <tns:BrOznRac>555</tns:BrOznRac>
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
              <tns:ZastKod>de2c11aad4f14744678c513990899f56</tns:ZastKod>
              <tns:NakDost>false</tns:NakDost>
            </tns:Racun>
          </tns:ProvjeraZahtjev>
        XML

        assert_xml_equal expected_xml, actual_xml
      end
    end
  end

  def test_sign_with_valid_document
    credential_data = file_fixture("fake_fiskal1.p12").read
    password = file_fixture("fake_fiskal1_password.txt").read.strip
    credential = OpenSSL::PKCS12.new(credential_data, password)

    # Create a simple XML document with Id attribute
    doc = REXML::Document.new
    root = doc.add_element("TestDocument", { "Id" => "test-id-123" })
    root.add_element("Content").text = "Test content"

    Croatia::Fiscalizer::XMLBuilder.sign(document: doc, credential: credential)

    expected_xml = <<~XML
      <TestDocument Id='test-id-123'>
        <Content>Test content</Content>
        <Signature xmlns='http://www.w3.org/2000/09/xmldsig#'>
          <SignedInfo>
            <CanonicalizationMethod Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/>
            <SignatureMethod Algorithm='http://www.w3.org/2000/09/xmldsig#rsa-sha1'/>
            <Reference URI='#test-id-123'>
              <Transforms>
                <Transform Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/>
                <Transform Algorithm='http://www.w3.org/2000/09/xmldsig#enveloped-signature'/>
              </Transforms>
              <DigestMethod Algorithm='http://www.w3.org/2000/09/xmldsig#sha1'/>
              <DigestValue>xVO05KssA2WQLesc7XXYpLZdoDg=</DigestValue>
            </Reference>
          </SignedInfo>
          <SignatureValue>T/6zG/NqE56T0+p191ZDVVXDFJATq5+DvqUEE7dryqfv4ZCoCZ7R3WR4/ei3QWKgr0SHep0bms84ur3B113q0nclZ+gYXpudiPSI1ESu5rxGf3g+JWj/uqwry/W3MEm3SqgzCG2oQ7NMUh5SIItN3QL7rYOtAlcn3AGp8MuEK2Z7Fmc2f7+vF3N14xmHSM3PDAWfyCX+CY607bPrpYoA4ZV6/uDRIuftS0ND3Zg6c2xS6t/RTny+ssWsR+WraVxDD6NcK99nHYYxdujNPGfSsZwDUZWm5yPvO6SFwbtijX5W7r3xNFFYOOvxpjVppq0taJn9jb/8rNLuGCblngHW4A==</SignatureValue>
          <KeyInfo>
            <X509Data>
              <X509Certificate>MIIC1TCCAb2gAwIBAgIDATf5MA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNVBAMMEFRl
        c3QgQ2VydGlmaWNhdGUwIBcNMjUwNjA0MDc0NDMyWhgPMjEyNTA1MTEwNzQ0MzJa
        MBsxGTAXBgNVBAMMEFRlc3QgQ2VydGlmaWNhdGUwggEiMA0GCSqGSIb3DQEBAQUA
        A4IBDwAwggEKAoIBAQCfeL/gYSOCd5Qmpwn0IcGji/c4Ax96Wep9yoN1KAVUMo5Y
        XbA2a9OCafyrWmSoWFL2ihd+suPIPTdcn+4S9LjLKgTlF00ZjCYUrd0N4zxVy8+q
        t9cYKLzIDMXND5GEc7eEcd7V4Me/6/4Z73FDHd3vE0+PYSLFshm/Sc5CFeV1T67+
        PxFyFpJIZWXtqaUsvrJ2xF4PqsqnhHyra0bgLQA52jTu0wHhmyq/ndpYB/F9QZKv
        VdKwE9vEw3Ffjav5bve8hEzGJpX/2J4fb0aBndXsj/Z3fByIZcEHGuTTxxkl/2+Y
        qt0rnIwXngq+BYKhb02oxppER7b7bZzOrRaiV4jJAgMBAAGjIDAeMAwGA1UdEwEB
        /wQCMAAwDgYDVR0PAQH/BAQDAgWgMA0GCSqGSIb3DQEBCwUAA4IBAQCMsI5Vq6Ii
        t95STHWP0kp3zccabodNAZu1VsCcJVb3elBvvKsoMqr0UQ2SkiQjogOfjfSzNwGG
        o2N0KPb+6JOx2//YGk32boynqTZ8epEUQlgiTe2xb1IyOFoCOHDazpuABLt1VitY
        v0dg18BpBFCq8oxLl4fzLOXnHjSzV6Yz9xJ0GNJ0tt5BFOW3BnN7/EfLNNd7m+Tv
        A7hUawPh4+jdrZMnvJwy9TwsS4SBDqm4d/Toyvkxq+2N0WJ0Tka7oaePiKEt6s36
        EyitLWJBrXgHcgjRHxRa4UrC0h66kIUC814iw5XNC9V9dNcrAjkZCtdYsxhpkOkz
        bKatxi5CFV/v</X509Certificate>
              <X509IssuerSerial>
                <X509IssuerName>CN=Test Certificate</X509IssuerName>
                <X509SerialNumber>79865</X509SerialNumber>
              </X509IssuerSerial>
            </X509Data>
          </KeyInfo>
        </Signature>
      </TestDocument>
    XML

    assert_xml_equal expected_xml, doc
  end

  def test_sign_validation_error_missing_id
    credential_data = file_fixture("fake_fiskal1.p12").read
    password = file_fixture("fake_fiskal1_password.txt").read.strip
    credential = OpenSSL::PKCS12.new(credential_data, password)

    # Create a document without Id attribute
    doc = REXML::Document.new
    doc.add_element("TestDocument")

    assert_raises(ArgumentError, "Document root element must have a non-empty 'Id' attribute") do
      Croatia::Fiscalizer::XMLBuilder.sign(document: doc, credential: credential)
    end
  end

  def test_sign_validation_error_empty_id
    certificate_data = file_fixture("fake_fiskal1.p12").read
    password = file_fixture("fake_fiskal1_password.txt").read.strip
    certificate = OpenSSL::PKCS12.new(certificate_data, password)

    # Create a document with empty Id attribute
    doc = REXML::Document.new
    doc.add_element("TestDocument", { "Id" => "" })

    assert_raises(ArgumentError, "Document root element must have a non-empty 'Id' attribute") do
      Croatia::Fiscalizer::XMLBuilder.sign(document: doc, credential: certificate)
    end
  end

  def test_sign_with_invoice_document
    Timecop.freeze(REFERENCE_TIME) do
      config = Croatia::Config.new(
        fiscalization: {
          credential: file_fixture("fake_fiskal1.p12").read,
          password: file_fixture("fake_fiskal1_password.txt").read.strip,
          endpoint: :test
        }
      )

      Croatia.with_config(config) do
        invoice = Croatia::Invoice.new(
          sequential_number: 777,
          business_location_identifier: "POSL1",
          register_identifier: "12",
          issue_date: Time.now - 5,
          sequential_by: :register,
        )

        invoice.issuer { |i| i.pin = "86988477146" }
        invoice.seller { |s| s.pin = "05575695113"; s.pays_vat = true }
        invoice.add_line_item { |i| i.description = "Sign test"; i.unit_price = 100.0; i.add_tax(type: :value_added_tax, category: :standard) }

        message_id = "c2bb23ad-7044-4b06-b259-04475acecc1e"
        document = Croatia::Fiscalizer::XMLBuilder.invoice(
          invoice: invoice,
          message_id: message_id,
          subsequent_delivery: false
        )

        # Verify the document has an Id attribute (added by build method)
        refute_nil document.root.attributes["Id"], "Document should have Id attribute"
        assert_equal message_id, document.root.attributes["Id"]

        credential_data = file_fixture("fake_fiskal1.p12").read
        password = file_fixture("fake_fiskal1_password.txt").read.strip
        credential = OpenSSL::PKCS12.new(credential_data, password)

        # Sign the document
        Croatia::Fiscalizer::XMLBuilder.sign(document: document, credential: credential)

        # Verify signature was added
        signature = document.root.elements["Signature"]
        refute_nil signature, "Signature should be present in signed document"

        # Verify the reference URI matches the document Id
        reference = signature.elements["SignedInfo/Reference"]
        assert_equal "##{message_id}", reference.attributes["URI"]
      end
    end
  end

  def test_echo
    message = "Hello, World!"
    document = Croatia::Fiscalizer::XMLBuilder.echo(message)

    expected_xml = <<~XML
      <tns:EchoRequest xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>Hello, World!</tns:EchoRequest>
    XML

    assert_xml_equal expected_xml, document
  end

  def test_echo_with_nil
    document = Croatia::Fiscalizer::XMLBuilder.echo(nil)

    expected_xml = <<~XML
      <tns:EchoRequest xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'></tns:EchoRequest>
    XML

    assert_xml_equal expected_xml, document
  end

  def test_soap_envelope
    # Create a simple document to wrap
    inner_doc = Croatia::Fiscalizer::XMLBuilder.echo("Test message")

    # Wrap it in SOAP envelope
    soap_doc = Croatia::Fiscalizer::XMLBuilder.soap_envelope(inner_doc)

    expected_xml = <<~XML
      <?xml version='1.0' encoding='UTF-8'?>
      <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/'>
        <soapenv:Body>
          <tns:EchoRequest xmlns:tns='http://www.apis-it.hr/fin/2012/types/f73' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>Test message</tns:EchoRequest>
        </soapenv:Body>
      </soapenv:Envelope>
    XML

    assert_xml_equal expected_xml, soap_doc
  end

  def test_soap_envelope_with_empty_document
    # Create an empty document
    empty_doc = REXML::Document.new
    empty_doc.add_element("EmptyElement")

    # Wrap it in SOAP envelope
    soap_doc = Croatia::Fiscalizer::XMLBuilder.soap_envelope(empty_doc)

    expected_xml = <<~XML
      <?xml version='1.0' encoding='UTF-8'?>
      <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/'>
        <soapenv:Body>
          <EmptyElement/>
        </soapenv:Body>
      </soapenv:Envelope>
    XML

    assert_xml_equal expected_xml, soap_doc
  end
end
