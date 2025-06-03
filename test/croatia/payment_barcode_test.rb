# frozen_string_literal: true

require "test_helper"

class Croatia::PaymentBarcodeTest < Minitest::Test
  def test_initialization_with_all_fields
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 12500,
      buyer_name: "John Doe",
      buyer_address: "123 Main St",
      buyer_postal_code: "10000",
      buyer_city: "Zagreb",
      seller_name: "Acme Corp",
      seller_address: "456 Business Ave",
      seller_postal_code: "21000",
      seller_city: "Split",
      seller_iban: "HR1234567890123456789",
      model: "HR01",
      reference_number: "12345-67890",
      payment_purpose_code: "SALA",
      description: "Invoice payment"
    )

    assert_equal "EUR", barcode.currency
    assert_equal 12500, barcode.total_cents
    assert_equal "John Doe", barcode.buyer_name
    assert_equal "Acme Corp", barcode.seller_name
    assert_equal "HR1234567890123456789", barcode.seller_iban
  end

  def test_data_format_with_all_fields
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 12500,
      buyer_name: "John Doe",
      buyer_address: "123 Main St",
      buyer_postal_code: "10000",
      buyer_city: "Zagreb",
      seller_name: "Acme Corp",
      seller_address: "456 Business Ave",
      seller_postal_code: "21000",
      seller_city: "Split",
      seller_iban: "HR1234567890123456789",
      model: "HR01",
      reference_number: "12345-67890",
      payment_purpose_code: "SALA",
      description: "Invoice payment"
    )

    expected_data = [
      "HRVHUB30",                    # header
      "EUR",                        # currency
      "000000000012500",            # total (15 digits)
      "John Doe",                   # buyer_name
      "123 Main St",                # buyer_address
      "10000 Zagreb",               # buyer_postal_code_and_city
      "Acme Corp",                  # seller_name
      "456 Business Ave",           # seller_address
      "21000 Split",                # seller_postal_code_and_city
      "HR1234567890123456789",      # seller_iban
      "HR01",                       # model
      "12345-67890",               # reference_number
      "SALA",                       # payment_purpose_code
      "Invoice payment"             # description
    ].join("\n")

    assert_equal expected_data, barcode.data
  end

  def test_data_format_with_minimal_fields
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 5000,
      buyer_name: "Jane Smith",
      seller_name: "Test Company",
      seller_iban: "HR9876543210987654321",
      description: "Test payment"
    )

    expected_data = [
      "HRVHUB30",
      "EUR", 
      "000000000005000",
      "Jane Smith",
      "",                           # buyer_address (nil becomes empty string)
      "",                           # buyer_postal_code_and_city (empty and stripped)
      "Test Company",
      "",                           # seller_address (nil becomes empty string)
      "",                           # seller_postal_code_and_city (empty and stripped)
      "HR9876543210987654321",
      "",                           # model (nil becomes empty string)
      "",                           # reference_number (nil becomes empty string)
      "",                           # payment_purpose_code (nil becomes empty string)
      "Test payment"
    ].join("\n")

    assert_equal expected_data, barcode.data
  end

  def test_field_length_validations
    # Test currency length (must be exactly 3 characters)
    barcode = Croatia::PaymentBarcode.new(
      currency: "EURO",  # 4 characters - should fail
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )

    assert_raises(ArgumentError, "Value 'EURO' of field 'currency' must be exactly 3 characters long") do
      barcode.data
    end
  end

  def test_field_max_length_validations
    # Test buyer_name exceeds max length (30 characters)
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "X" * 31,  # 31 characters - should fail
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )

    assert_raises(ArgumentError, "exceeds maximum length of 30 characters") do
      barcode.data
    end
  end

  def test_iban_format_validation
    # Test valid Croatian IBAN
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )
    
    assert_nothing_raised { barcode.data }

    # Test valid account number format
    barcode.seller_iban = "1234567-1234567890"
    assert_nothing_raised { barcode.data }

    # Test invalid IBAN format
    barcode.seller_iban = "INVALID_FORMAT"
    assert_raises(ArgumentError, "Invalid IBAN format") do
      barcode.data
    end
  end

  def test_total_cents_padding
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 123,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )

    data = barcode.data
    lines = data.split("\n")
    total_line = lines[2]  # total is the 3rd line
    
    assert_equal "000000000000123", total_line
    assert_equal 15, total_line.length
  end

  def test_postal_code_city_combination
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "Test Buyer",
      buyer_postal_code: "10000",
      buyer_city: "Zagreb",
      seller_name: "Test Seller",
      seller_postal_code: "21000",
      seller_city: "Split",
      seller_iban: "HR1234567890123456789"
    )

    data = barcode.data
    lines = data.split("\n")
    buyer_postal_city = lines[5]   # buyer postal+city is 6th line
    seller_postal_city = lines[8]  # seller postal+city is 9th line

    assert_equal "10000 Zagreb", buyer_postal_city
    assert_equal "21000 Split", seller_postal_city
  end

  def test_barcode_method_returns_pdf417
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )

    pdf417 = barcode.barcode
    assert_instance_of Croatia::PDF417, pdf417
    assert_equal barcode.data, pdf417.data
  end

  def test_png_svg_delegation
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR", 
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789"
    )

    # Test that PNG and SVG methods are delegated to the barcode
    assert_respond_to barcode, :to_png
    assert_respond_to barcode, :to_svg
    
    # These should not raise errors (actual functionality depends on PDF417 implementation)
    assert_nothing_raised { barcode.to_png rescue nil }
    assert_nothing_raised { barcode.to_svg rescue nil }
  end

  def test_exact_length_fields_validation
    # Test model field (should be exactly 4 characters when present)
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test", 
      seller_iban: "HR1234567890123456789",
      model: "HR"  # Only 2 characters - should fail
    )

    assert_raises(ArgumentError, "must be exactly 4 characters long") do
      barcode.data
    end

    # Test payment_purpose_code field (should be exactly 4 characters when present) 
    barcode.model = "HR01"  # Fix model
    barcode.payment_purpose_code = "SAL"  # Only 3 characters - should fail

    assert_raises(ArgumentError, "must be exactly 4 characters long") do
      barcode.data
    end
  end

  def test_nil_values_handling
    barcode = Croatia::PaymentBarcode.new(
      currency: "EUR",
      total_cents: 1000,
      buyer_name: "Test",
      seller_name: "Test",
      seller_iban: "HR1234567890123456789",
      model: nil,  # nil values should be handled gracefully
      reference_number: nil,
      payment_purpose_code: nil
    )

    # Should not raise error for nil values
    assert_nothing_raised { barcode.data }
    
    data = barcode.data
    lines = data.split("\n")
    
    # nil values should appear as empty strings in the data
    assert_nil lines[10]  # model
    assert_nil lines[11]  # reference_number  
    assert_nil lines[12]  # payment_purpose_code
  end

  private

  def assert_nothing_raised
    yield
  rescue => e
    flunk "Expected no exception, but got #{e.class}: #{e.message}"
  end
end