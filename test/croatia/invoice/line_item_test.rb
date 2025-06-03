# frozen_string_literal: true

require "test_helper"

class Croatia::Invoice::LineItemTest < Minitest::Test
  def test_initialize_with_defaults
    line_item = Croatia::Invoice::LineItem.new(description: "Test item")

    assert_equal "Test item", line_item.description
    assert_equal 1, line_item.quantity
    assert_equal 0.0, line_item.unit_price
    assert_equal Hash.new, line_item.taxes
  end

  def test_initialize_with_custom_values
    tax = Croatia::Invoice::Tax.new(rate: 0.20, category: :lower_rate)
    line_item = Croatia::Invoice::LineItem.new(
      description: "Custom item",
      quantity: 3,
      unit_price: 10.50,
      taxes: { tax.type => tax }
    )

    assert_equal "Custom item", line_item.description
    assert_equal 3, line_item.quantity
    assert_equal 10.50, line_item.unit_price
    assert_equal 1, line_item.taxes.length
    assert_equal BigDecimal("0.20"), line_item.taxes.values.first.rate
    assert_equal :lower_rate, line_item.taxes.values.first.category
  end

  def test_quantity_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    # Negative quantities should now be allowed
    line_item.quantity = -1
    assert_equal BigDecimal("-1"), line_item.quantity

    assert_raises(ArgumentError, "Quantity must be a number") do
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

  def test_add_tax_with_options
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    tax = line_item.add_tax(rate: 0.13, category: :lower_rate)

    assert_instance_of Croatia::Invoice::Tax, tax
    assert_equal BigDecimal("0.13"), tax.rate
    assert_equal :lower_rate, tax.category
    assert_equal 1, line_item.taxes.length
  end

  def test_add_tax_with_block
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    tax = line_item.add_tax do |t|
      t.rate = 0.05
      t.category = :exempt
    end

    assert_instance_of Croatia::Invoice::Tax, tax
    assert_equal BigDecimal("0.05"), tax.rate
    assert_equal :exempt, tax.category
    assert_equal 1, line_item.taxes.length
  end

  def test_add_tax_with_object
    line_item = Croatia::Invoice::LineItem.new(description: "Test")
    tax_obj = Croatia::Invoice::Tax.new(rate: 0.22, category: :standard)

    result = line_item.add_tax(tax_obj)

    assert_equal tax_obj, result
    assert_equal 1, line_item.taxes.length
    assert_equal tax_obj, line_item.taxes.values.first
  end

  def test_add_tax_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(NoMethodError, "undefined method 'type'") do
      line_item.add_tax("not a tax")
    end
  end

  def test_subtotal_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 3,
      unit_price: 10.0
    )

    assert_equal BigDecimal("30.0"), line_item.subtotal
  end

  def test_tax_calculation_single_tax
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.25)

    assert_equal BigDecimal("5.0"), line_item.tax
  end

  def test_tax_calculation_multiple_taxes
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.20, type: :value_added_tax)  # 4.0
    line_item.add_tax(rate: 0.05, type: :consumption_tax)  # 1.0

    assert_equal BigDecimal("5.0"), line_item.tax
  end

  def test_tax_calculation_no_taxes
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )

    assert_equal BigDecimal("0"), line_item.tax
  end

  def test_total_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.25)

    assert_equal BigDecimal("25.0"), line_item.total
  end

  def test_bigdecimal_precision
    line_item = Croatia::Invoice::LineItem.new(
      description: "Precision test",
      quantity: 3,
      unit_price: 1.23
    )

    assert_instance_of BigDecimal, line_item.quantity
    assert_instance_of BigDecimal, line_item.unit_price
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
      unit_price: 0.0
    )

    assert_equal BigDecimal("0"), line_item.subtotal
    assert_equal BigDecimal("0"), line_item.tax
    assert_equal BigDecimal("0"), line_item.total
  end

  # Test various scenarios that would cause floating point precision errors
  # and verify proper rounding to 2 decimal places with half-up rounding
  def test_floating_point_calculation_errors_with_rounding
    # Case 1: Small decimal multiplication
    item1 = Croatia::Invoice::LineItem.new(
      description: "Small decimals",
      quantity: 0.1,
      unit_price: 0.2
    )
    assert_equal BigDecimal("0.02"), item1.subtotal

    # Case 2: Repeating decimal calculations with rounding
    item2 = Croatia::Invoice::LineItem.new(
      description: "Repeating decimals",
      quantity: 1.0 / 3.0,
      unit_price: 3.0
    )
    item2.add_tax(rate: 1.0 / 3.0)
    # 1/3 * 3.0 should be exactly 1.0, rounded to 2 decimals
    assert_equal BigDecimal("1.00"), item2.subtotal
    # tax_rate is rounded to 0.33, so tax = 1.00 * 0.33 = 0.33
    assert_equal BigDecimal("0.33"), item2.tax
    assert_equal BigDecimal("1.33"), item2.total

    # Case 3: Complex calculation with rounding
    item3 = Croatia::Invoice::LineItem.new(
      description: "Complex calculation",
      quantity: 3.33,
      unit_price: 1.11
    )
    item3.add_tax(rate: 0.22)
    # 3.33 * 1.11 = 3.6963, rounded to 3.70
    assert_equal BigDecimal("3.70"), item3.subtotal
    # 3.70 * 0.22 = 0.814, rounded to 0.81
    assert_equal BigDecimal("0.81"), item3.tax
    # 3.70 + 0.81 = 4.51
    assert_equal BigDecimal("4.51"), item3.total

    # Case 4: Test half-up rounding behavior specifically
    item4 = Croatia::Invoice::LineItem.new(
      description: "Half-up rounding test",
      quantity: 1,
      unit_price: 1.125
    )
    item4.add_tax(rate: 0.25)
    assert_equal BigDecimal("1.125"), item4.unit_price
    assert_equal BigDecimal("1.13"), item4.subtotal
    assert_equal BigDecimal("0.28"), item4.tax  # 1.13 * 0.25 = 0.2825, rounds to 0.28
    assert_equal BigDecimal("1.41"), item4.total

    # Case 5: Ensure all results are BigDecimal with 2 decimal precision
    assert_kind_of BigDecimal, item1.subtotal
    assert_kind_of BigDecimal, item2.tax
    assert_kind_of BigDecimal, item3.total

    # Verify scale is 2 for currency precision
    assert_equal 2, item1.subtotal.scale
    assert_equal 2, item2.tax.scale
    assert_equal 2, item3.total.scale
  end

  def test_discount_rate_functionality
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.25)

    # Test setting discount rate
    line_item.discount_rate = 0.1
    assert_equal BigDecimal("0.1"), line_item.discount_rate

    # Test discount calculation with discount rate
    assert_equal BigDecimal("20.00"), line_item.gross  # 2 * 10.0
    assert_equal BigDecimal("2.00"), line_item.discount  # 20.0 * 0.1
    assert_equal BigDecimal("18.00"), line_item.subtotal  # 20.0 - 2.0
    assert_equal BigDecimal("4.50"), line_item.tax  # 18.0 * 0.25
    assert_equal BigDecimal("22.50"), line_item.total  # 18.0 + 4.5

    # Test nil discount rate
    line_item.discount_rate = nil
    assert_nil line_item.discount_rate
    assert_equal BigDecimal("0.0"), line_item.discount
  end

  def test_discount_rate_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(ArgumentError, "Discount rate must be a non-negative number between 0 and 1") do
      line_item.discount_rate = -0.1
    end

    assert_raises(ArgumentError, "Discount rate must be a non-negative number between 0 and 1") do
      line_item.discount_rate = 1.5
    end

    assert_raises(ArgumentError, "Discount rate must be a non-negative number between 0 and 1") do
      line_item.discount_rate = "invalid"
    end
  end

  def test_discount_amount_functionality
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.25)

    # Test setting fixed discount amount
    line_item.discount = 3.0
    assert_equal BigDecimal("3.00"), line_item.discount

    # Test calculations with fixed discount
    assert_equal BigDecimal("20.00"), line_item.gross
    assert_equal BigDecimal("17.00"), line_item.subtotal  # 20.0 - 3.0
    assert_equal BigDecimal("4.25"), line_item.tax  # 17.0 * 0.25
    assert_equal BigDecimal("21.25"), line_item.total

    # Test nil discount
    line_item.discount = nil
    assert_equal BigDecimal("0.0"), line_item.discount

    # Test discount rounding
    line_item.discount = 3.126
    assert_equal BigDecimal("3.13"), line_item.discount
  end

  def test_discount_validation
    line_item = Croatia::Invoice::LineItem.new(description: "Test")

    assert_raises(ArgumentError, "Discount must be a non-negative number") do
      line_item.discount = -5.0
    end

    assert_raises(ArgumentError, "Discount must be a non-negative number") do
      line_item.discount = "invalid"
    end
  end

  def test_gross_calculation
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 3.33,
      unit_price: 1.11
    )

    # 3.33 * 1.11 = 3.6963, rounded to 3.70
    assert_equal BigDecimal("3.70"), line_item.gross
    assert_kind_of BigDecimal, line_item.gross
  end

  def test_reverse_method
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 5,
      unit_price: 10.0
    )
    line_item.add_tax(rate: 0.25)

    original_quantity = line_item.quantity
    line_item.reverse

    # Quantity should be negated
    assert_equal -original_quantity, line_item.quantity
    assert_equal BigDecimal("-5"), line_item.quantity

    # All calculations should reflect the negative quantity
    assert_equal BigDecimal("-50.00"), line_item.gross
    assert_equal BigDecimal("-50.00"), line_item.subtotal
    assert_equal BigDecimal("-12.50"), line_item.tax
    assert_equal BigDecimal("-62.50"), line_item.total
  end

  def test_discount_priority_fixed_over_rate
    line_item = Croatia::Invoice::LineItem.new(
      description: "Test item",
      quantity: 2,
      unit_price: 10.0
    )

    # Set both discount rate and fixed discount
    line_item.discount_rate = 0.1  # Would give 2.0 discount
    line_item.discount = 5.0       # Fixed discount takes priority

    assert_equal BigDecimal("5.00"), line_item.discount
    assert_equal BigDecimal("15.00"), line_item.subtotal  # 20.0 - 5.0
  end

  def test_floating_point_with_discounts
    line_item = Croatia::Invoice::LineItem.new(
      description: "Precision test with discount",
      quantity: 3.33,
      unit_price: 1.11
    )
    line_item.add_tax(rate: 0.22)

    line_item.discount_rate = 0.15

    # gross: 3.33 * 1.11 = 3.6963, rounded to 3.70
    assert_equal BigDecimal("3.70"), line_item.gross

    # discount: 3.70 * 0.15 = 0.555, rounded to 0.56
    assert_equal BigDecimal("0.56"), line_item.discount

    # subtotal: 3.70 - 0.56 = 3.14
    assert_equal BigDecimal("3.14"), line_item.subtotal

    # tax: 3.14 * 0.22 = 0.6908, rounded to 0.69
    assert_equal BigDecimal("0.69"), line_item.tax

    # total: 3.14 + 0.69 = 3.83
    assert_equal BigDecimal("3.83"), line_item.total
  end
end
