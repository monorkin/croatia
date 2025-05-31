# frozen_string_literal: true

require "test_helper"

class Croatia::InvoiceTest < Minitest::Test
  def test_initialize_with_defaults
    invoice = Croatia::Invoice.new

    assert_equal [], invoice.line_items
    assert_nil invoice.business_location_identifier
    assert_nil invoice.currency
    assert_nil invoice.register_identifier
    assert_nil invoice.sequential_number
  end

  def test_initialize_with_options
    invoice = Croatia::Invoice.new(
      business_location_identifier: "LOC001",
      currency: "EUR",
      register_identifier: "REG001",
      sequential_number: 123
    )

    assert_equal "LOC001", invoice.business_location_identifier
    assert_equal "EUR", invoice.currency
    assert_equal "REG001", invoice.register_identifier
    assert_equal 123, invoice.sequential_number
  end

  def test_initialize_with_line_items
    line_items = [
      Croatia::Invoice::LineItem.new(description: "Item 1", unit_price: 10.0),
      Croatia::Invoice::LineItem.new(description: "Item 2", unit_price: 20.0)
    ]

    invoice = Croatia::Invoice.new(line_items: line_items)

    assert_equal 2, invoice.line_items.length
    assert_equal "Item 1", invoice.line_items.first.description
    assert_equal "Item 2", invoice.line_items.last.description
  end

  def test_number_generation
    invoice = Croatia::Invoice.new(
      sequential_number: 123,
      business_location_identifier: "LOC001",
      register_identifier: "REG001"
    )

    assert_equal "123/LOC001/REG001", invoice.number
  end

  def test_calculations_with_line_items
    invoice = Croatia::Invoice.new

    invoice.add_line_item(Croatia::Invoice::LineItem.new(
      description: "Item 1",
      quantity: 2,
      unit_price: 10.0,
      tax_rate: 0.25
    ))

    invoice.add_line_item(Croatia::Invoice::LineItem.new(
      description: "Item 2",
      quantity: 1,
      unit_price: 30.0,
      tax_rate: 0.25
    ))

    # Item 1: gross=20.00, discount=0, subtotal=20.00, tax=5.00, total=25.00
    # Item 2: gross=30.00, discount=0, subtotal=30.00, tax=7.50, total=37.50
    assert_equal BigDecimal("50.00"), invoice.subtotal
    assert_equal BigDecimal("12.50"), invoice.tax
    assert_equal BigDecimal("62.50"), invoice.total
  end

  def test_total_cents
    invoice = Croatia::Invoice.new

    invoice.add_line_item(Croatia::Invoice::LineItem.new(
      description: "Item",
      unit_price: 10.55,
      tax_rate: 0.25
    ))

    # total = 10.55 + (10.55 * 0.25) = 10.55 + 2.64 = 13.19
    assert_equal BigDecimal("13.19"), invoice.total
    assert_equal 1319, invoice.total_cents
  end

  def test_add_line_item_with_object
    invoice = Croatia::Invoice.new
    line_item = Croatia::Invoice::LineItem.new(description: "Test item")

    result = invoice.add_line_item(line_item)

    assert_equal 1, invoice.line_items.length
    assert_equal line_item, invoice.line_items.first
    assert_equal line_item, result
  end

  def test_add_line_item_with_block
    invoice = Croatia::Invoice.new

    result = invoice.add_line_item do |item|
      item.description = "Block item"
      item.unit_price = 15.0
    end

    assert_equal 1, invoice.line_items.length
    assert_equal "Block item", invoice.line_items.first.description
    assert_equal BigDecimal("15.0"), invoice.line_items.first.unit_price
    assert_equal invoice.line_items.first, result
  end

  def test_add_line_item_validation
    invoice = Croatia::Invoice.new

    assert_raises(ArgumentError, "You must provide a line item or a block") do
      invoice.add_line_item
    end
  end

  def test_buyer_with_block
    invoice = Croatia::Invoice.new

    buyer = invoice.buyer do |party|
      party.name = "Test Buyer"
    end

    assert_instance_of Croatia::Invoice::Party, buyer
    assert_equal "Test Buyer", buyer.name
    assert_equal buyer, invoice.buyer
  end

  def test_buyer_getter
    invoice = Croatia::Invoice.new
    party = Croatia::Invoice::Party.new(name: "Test Buyer")

    invoice.buyer = party
    assert_equal party, invoice.buyer
  end

  def test_buyer_validation
    invoice = Croatia::Invoice.new

    assert_raises(ArgumentError, "Buyer must be an instance of Party") do
      invoice.buyer = "not a party"
    end
  end

  def test_seller_with_block
    invoice = Croatia::Invoice.new

    seller = invoice.seller do |party|
      party.name = "Test Seller"
    end

    assert_instance_of Croatia::Invoice::Party, seller
    assert_equal "Test Seller", seller.name
    assert_equal seller, invoice.seller
  end

  def test_seller_getter
    invoice = Croatia::Invoice.new
    party = Croatia::Invoice::Party.new(name: "Test Seller")

    invoice.seller = party
    assert_equal party, invoice.seller
  end

  def test_seller_validation
    invoice = Croatia::Invoice.new

    assert_raises(ArgumentError, "Seller must be an instance of Party") do
      invoice.seller = "not a party"
    end
  end

  def test_issue_date_with_date
    invoice = Croatia::Invoice.new
    date = Date.new(2023, 12, 25)

    invoice.issue_date = date
    assert_equal date, invoice.issue_date
  end

  def test_issue_date_with_datetime
    invoice = Croatia::Invoice.new
    datetime = DateTime.new(2023, 12, 25, 10, 30, 0)

    invoice.issue_date = datetime
    assert_equal datetime, invoice.issue_date
  end

  def test_issue_date_with_string
    invoice = Croatia::Invoice.new

    invoice.issue_date = "2023-12-25"
    assert_instance_of DateTime, invoice.issue_date
    assert_equal 2023, invoice.issue_date.year
    assert_equal 12, invoice.issue_date.month
    assert_equal 25, invoice.issue_date.day
  end

  def test_issue_date_with_nil
    invoice = Croatia::Invoice.new

    invoice.issue_date = nil
    assert_nil invoice.issue_date
  end

  def test_due_date_with_date
    invoice = Croatia::Invoice.new
    date = Date.new(2024, 1, 15)

    invoice.due_date = date
    assert_equal date, invoice.due_date
  end

  def test_due_date_with_string
    invoice = Croatia::Invoice.new

    invoice.due_date = "2024-01-15"
    assert_instance_of DateTime, invoice.due_date
    assert_equal 2024, invoice.due_date.year
    assert_equal 1, invoice.due_date.month
    assert_equal 15, invoice.due_date.day
  end

  def test_due_date_with_nil
    invoice = Croatia::Invoice.new

    invoice.due_date = nil
    assert_nil invoice.due_date
  end

  def test_empty_calculations
    invoice = Croatia::Invoice.new

    assert_equal BigDecimal("0"), invoice.subtotal
    assert_equal BigDecimal("0"), invoice.tax
    assert_equal BigDecimal("0"), invoice.total
    assert_equal 0, invoice.total_cents
  end

  def test_calculations_with_discounts
    invoice = Croatia::Invoice.new

    invoice.add_line_item do |item|
      item.description = "Discounted item"
      item.quantity = 2
      item.unit_price = 10.0
      item.tax_rate = 0.25
      item.discount_rate = 0.1  # 10% discount
    end

    # gross: 2 * 10.0 = 20.00
    # discount: 20.00 * 0.1 = 2.00
    # subtotal: 20.00 - 2.00 = 18.00
    # tax: 18.00 * 0.25 = 4.50
    # total: 18.00 + 4.50 = 22.50

    assert_equal BigDecimal("18.00"), invoice.subtotal
    assert_equal BigDecimal("4.50"), invoice.tax
    assert_equal BigDecimal("22.50"), invoice.total
  end

  def test_calculations_with_negative_line_items
    invoice = Croatia::Invoice.new

    invoice.add_line_item do |item|
      item.description = "Original item"
      item.quantity = 3
      item.unit_price = 10.0
      item.tax_rate = 0.25
    end

    invoice.add_line_item do |item|
      item.description = "Reversal item"
      item.quantity = -1
      item.unit_price = 10.0
      item.tax_rate = 0.25
    end

    # Item 1: subtotal=30.00, tax=7.50, total=37.50
    # Item 2: subtotal=-10.00, tax=-2.50, total=-12.50
    # Total: subtotal=20.00, tax=5.00, total=25.00

    assert_equal BigDecimal("20.00"), invoice.subtotal
    assert_equal BigDecimal("5.00"), invoice.tax
    assert_equal BigDecimal("25.00"), invoice.total
  end

  def test_complex_invoice_calculation
    invoice = Croatia::Invoice.new(
      sequential_number: 1,
      business_location_identifier: "OFFICE",
      register_identifier: "CASH1",
      currency: "EUR"
    )

    # Add multiple line items with different scenarios
    invoice.add_line_item do |item|
      item.description = "Standard item"
      item.quantity = 2
      item.unit_price = 25.50
      item.tax_rate = 0.25
    end

    invoice.add_line_item do |item|
      item.description = "Discounted item"
      item.quantity = 1
      item.unit_price = 100.0
      item.tax_rate = 0.13
      item.discount = 15.0
    end

    # Item 1: gross=51.00, subtotal=51.00, tax=12.75, total=63.75
    # Item 2: gross=100.00, discount=15.00, subtotal=85.00, tax=11.05, total=96.05
    # Total: subtotal=136.00, tax=23.80, total=159.80

    assert_equal "1/OFFICE/CASH1", invoice.number
    assert_equal BigDecimal("136.00"), invoice.subtotal
    assert_equal BigDecimal("23.80"), invoice.tax
    assert_equal BigDecimal("159.80"), invoice.total
    assert_equal 15980, invoice.total_cents
  end

  def test_payment_barcode_with_defaults
    invoice = Croatia::Invoice.new(
      sequential_number: 1,
      business_location_identifier: "OFFICE",
      register_identifier: "CASH1",
      currency: "EUR"
    )

    invoice.seller do |party|
      party.name = "Test Company Ltd"
      party.iban = "HR1234567890123456789"
    end

    invoice.add_line_item do |item|
      item.description = "Test item"
      item.unit_price = 100.0
      item.tax_rate = 0.25
    end


    barcode = invoice.payment_barcode

    assert_instance_of Croatia::PDF417, barcode
    expected_data = [
      "HRVHUB30",
      "EUR",
      "000000012500", # 125.00 EUR in cents, padded to 12 digits
      "Test Company Ltd",
      "HR1234567890123456789",
      "Račun br. 1/OFFICE/CASH1",
      nil,
      nil,
      nil
    ].join("\n")

    assert_equal expected_data, barcode.data
  end

  def test_payment_barcode_with_custom_params
    invoice = Croatia::Invoice.new(
      sequential_number: 1,
      business_location_identifier: "OFFICE",
      register_identifier: "CASH1",
      currency: "EUR",
      due_date: Date.new(2024, 12, 31)
    )

    invoice.seller do |party|
      party.name = "Test Company Ltd"
      party.iban = "HR1234567890123456789"
    end

    invoice.add_line_item do |item|
      item.description = "Test item"
      item.unit_price = 50.0
      item.tax_rate = 0.25
    end


    barcode = invoice.payment_barcode(
      name: "Custom Name",
      iban: "HR9876543210987654321",
      description: "Custom payment description",
      model: "HR01",
      reference_number: "12345-67890"
    )

    expected_data = [
      "HRVHUB30",
      "EUR",
      "000000006250", # 62.50 EUR in cents
      "Custom Name",
      "HR9876543210987654321",
      "Custom payment description",
      "HR01",
      "12345-67890",
      "20241231"
    ].join("\n")

    assert_equal expected_data, barcode.data
  end

  def test_payment_barcode_validation_errors
    invoice = Croatia::Invoice.new(currency: "INVALID")

    assert_raises(ArgumentError, "Currency code must be 3 characters long") do
      invoice.payment_barcode
    end

    invoice.currency = "EUR"
    invoice.seller = Croatia::Invoice::Party.new(name: "X" * 31, iban: "HR1234567890123456789")

    assert_raises(ArgumentError, "Name must be 30 characters or less") do
      invoice.payment_barcode
    end

    invoice.seller.name = "Valid Name"
    invoice.seller.iban = "INVALID_IBAN"

    assert_raises(ArgumentError, "IBAN must be 21 characters") do
      invoice.payment_barcode
    end

    invoice.seller.iban = "HR1234567890123456789"

    assert_raises(ArgumentError, "Description must be 35 characters or less") do
      invoice.payment_barcode(description: "X" * 36)
    end

    assert_raises(ArgumentError, "Model must be 4 characters long") do
      invoice.payment_barcode(model: "INVALID")
    end

    assert_raises(ArgumentError, "Reference number must be 22 characters or less") do
      invoice.payment_barcode(reference_number: "X" * 23)
    end
  end

  def test_fiscalization_qr_code_with_unique_identifier
    invoice = Croatia::Invoice.new(
      unique_invoice_identifier: "12345678-1234-1234-1234-123456789012",
      issue_date: DateTime.new(2024, 1, 15, 14, 30, 0)
    )

    invoice.add_line_item do |item|
      item.description = "Test item"
      item.unit_price = 123.45
      item.tax_rate = 0.25
    end


    qr_code = invoice.fiscalization_qr_code

    assert_instance_of Croatia::QRCode, qr_code

    expected_url = "https://porezna.gov.hr/rn?datv=20240115_1430&izn=15431&jir=12345678-1234-1234-1234-123456789012"
    assert_equal expected_url, qr_code.data
  end

  def test_fiscalization_qr_code_with_protection_code
    invoice = Croatia::Invoice.new(
      issuer_protection_code: "abcd1234efgh5678",
      issue_date: DateTime.new(2024, 1, 15, 14, 30, 0)
    )

    invoice.add_line_item do |item|
      item.description = "Test item"
      item.unit_price = 100.0
      item.tax_rate = 0.25
    end


    qr_code = invoice.fiscalization_qr_code

    expected_url = "https://porezna.gov.hr/rn?datv=20240115_1430&izn=12500&zki=abcd1234efgh5678"
    assert_equal expected_url, qr_code.data
  end

  def test_fiscalization_qr_code_validation_errors
    invoice = Croatia::Invoice.new(issue_date: DateTime.new(2024, 1, 15, 14, 30, 0))

    assert_raises(ArgumentError, "Either unique_invoice_identifier or issuer_protection_code must be provided") do
      invoice.fiscalization_qr_code
    end
  end
end
