# frozen_string_literal: true

require "test_helper"
require "croatia/invoice"

class Croatia::Invoice::LineItemTest < Minitest::Test
  def test_initialize_with_defaults
    line_item = Croatia::Invoice::LineItem.new(description: "Test item")

    assert_equal "Test item", line_item.description
    assert_equal 1, line_item.quantity
    assert_equal 0.0, line_item.unit_price
    assert_equal 0.25, line_item.tax_rate
  end

  def test_initialize_with_custom_values
    line_item = Croatia::Invoice::LineItem.new(
      description: "Custom item",
      quantity: 3,
      unit_price: 10.50,
      tax_rate: 0.20
    )

    assert_equal "Custom item", line_item.description
    assert_equal 3, line_item.quantity
    assert_equal 10.50, line_item.unit_price
    assert_equal 0.20, line_item.tax_rate
  end

  def test_quantity_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(ArgumentError, "Quantity must be a positive number") do
      line_item.quantity = -1
    end

    assert_raises(ArgumentError, "Quantity must be a positive number") do
      line_item.quantity = "invalid"
    end
  end

  def test_unit_price_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(ArgumentError, "Unit price must be a non-negative number") do
      line_item.unit_price = -5.0
    end

    assert_raises(ArgumentError, "Unit price must be a non-negative number") do
      line_item.unit_price = "invalid"
    end
  end

  def test_tax_rate_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(ArgumentError, "Tax rate must be a non-negative number between 0 and 1") do
      line_item.tax_rate = -0.1
    end

    assert_raises(ArgumentError, "Tax rate must be a non-negative number between 0 and 1") do
      line_item.tax_rate = 1.5
    end

    assert_raises(ArgumentError, "Tax rate must be a non-negative number between 0 and 1") do
      line_item.tax_rate = "invalid"
    end
  end

  def test_subtotal_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 3,
      unit_price: 10.0
    )

    assert_equal 30.0, line_item.subtotal
  end

  def test_tax_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0,
      tax_rate: 0.25
    )

    assert_equal 5.0, line_item.tax
  end

  def test_total_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0,
      tax_rate: 0.25
    )

    assert_equal 25.0, line_item.total
  end

  def test_bigdecimal_precision
    line_item = Croatia::Invoice::LineItem.new(
      description: "Precision test",
      quantity: 3,
      unit_price: 1.23
    )

    assert_instance_of BigDecimal, line_item.quantity
    assert_instance_of BigDecimal, line_item.unit_price
    assert_instance_of BigDecimal, line_item.tax_rate
  end

  def test_description_setter
    line_item = Croatia::Invoice::LineItem.new(description: "Original")
    line_item.description = "Updated"

    assert_equal "Updated", line_item.description
  end

  def test_zero_values
    line_item = Croatia::Invoice::LineItem.new(
      description: "Free item",
      quantity: 0,
      unit_price: 0.0,
      tax_rate: 0.0
    )

    assert_equal 0, line_item.subtotal
    assert_equal 0, line_item.tax
    assert_equal 0, line_item.total
  end

  def test_floating_point_calculation_errors
    # Test various scenarios that would cause floating point precision errors
    # without BigDecimal usage

    # Case 1: Small decimal multiplication
    item1 = Croatia::Invoice::LineItem.new(
      description: "Small decimals",
      quantity: 0.1,
      unit_price: 0.2
    )
    assert_equal BigDecimal("0.02"), item1.subtotal

    # Case 2: Repeating decimal calculations
    item2 = Croatia::Invoice::LineItem.new(
      description: "Repeating decimals",
      quantity: 1.0 / 3.0,
      unit_price: 3.0,
      tax_rate: 1.0 / 3.0
    )
    assert_kind_of BigDecimal, item2.subtotal
    assert_kind_of BigDecimal, item2.tax
    assert_kind_of BigDecimal, item2.total

    # Case 3: Complex calculation with potential precision loss
    item3 = Croatia::Invoice::LineItem.new(
      description: "Complex calculation",
      quantity: 3.33,
      unit_price: 1.11,
      tax_rate: 0.22
    )
    expected_subtotal = BigDecimal("3.33") * BigDecimal("1.11")
    expected_tax = expected_subtotal * BigDecimal("0.22")
    expected_total = expected_subtotal + expected_tax
    assert_equal expected_subtotal, item3.subtotal
    assert_equal expected_tax, item3.tax
    assert_equal expected_total, item3.total

    # Case 4: Large numbers maintaining precision
    item4 = Croatia::Invoice::LineItem.new(
      description: "Large numbers",
      quantity: 999999.99,
      unit_price: 999999.99,
      tax_rate: 0.25
    )
    expected_large_subtotal = BigDecimal("999999.99") * BigDecimal("999999.99")
    assert_equal expected_large_subtotal, item4.subtotal
  end
end
