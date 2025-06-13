# frozen_string_literal: true

require "test_helper"

class Croatia::Invoice::SurchargeTest < Minitest::Test
  def test_initialize
    surcharge = Croatia::Invoice::Surcharge.new(name: "Environmental fee", amount: 2.50)

    assert_equal "Environmental fee", surcharge.name
    assert_equal BigDecimal("2.50"), surcharge.amount
  end

  def test_initialize_with_string_amount
    surcharge = Croatia::Invoice::Surcharge.new(name: "Handling fee", amount: "3.75")

    assert_equal "Handling fee", surcharge.name
    assert_equal BigDecimal("3.75"), surcharge.amount
  end

  def test_initialize_with_integer_amount
    surcharge = Croatia::Invoice::Surcharge.new(name: "Service fee", amount: 5)

    assert_equal "Service fee", surcharge.name
    assert_equal BigDecimal("5"), surcharge.amount
  end

  def test_name_validation_nil
    assert_raises(ArgumentError, "Name cannot be nil") do
      Croatia::Invoice::Surcharge.new(name: nil, amount: 1.0)
    end
  end

  def test_amount_validation_nil
    assert_raises(ArgumentError, "Amount cannot be nil") do
      Croatia::Invoice::Surcharge.new(name: "Test", amount: nil)
    end
  end

  def test_name_setter
    surcharge = Croatia::Invoice::Surcharge.new(name: "Original", amount: 1.0)
    surcharge.name = "Updated"

    assert_equal "Updated", surcharge.name
  end

  def test_name_setter_with_whitespace
    surcharge = Croatia::Invoice::Surcharge.new(name: "Original", amount: 1.0)
    surcharge.name = "  Trimmed  "

    assert_equal "Trimmed", surcharge.name
  end

  def test_name_setter_with_number
    surcharge = Croatia::Invoice::Surcharge.new(name: "Original", amount: 1.0)
    surcharge.name = 123

    assert_equal "123", surcharge.name
  end

  def test_name_setter_nil_validation
    surcharge = Croatia::Invoice::Surcharge.new(name: "Original", amount: 1.0)

    assert_raises(ArgumentError, "Name cannot be nil") do
      surcharge.name = nil
    end
  end

  def test_amount_setter
    surcharge = Croatia::Invoice::Surcharge.new(name: "Test", amount: 1.0)
    surcharge.amount = 5.25

    assert_equal BigDecimal("5.25"), surcharge.amount
  end

  def test_amount_setter_with_string
    surcharge = Croatia::Invoice::Surcharge.new(name: "Test", amount: 1.0)
    surcharge.amount = "7.50"

    assert_equal BigDecimal("7.50"), surcharge.amount
  end

  def test_amount_setter_with_integer
    surcharge = Croatia::Invoice::Surcharge.new(name: "Test", amount: 1.0)
    surcharge.amount = 10

    assert_equal BigDecimal("10"), surcharge.amount
  end

  def test_amount_setter_nil_validation
    surcharge = Croatia::Invoice::Surcharge.new(name: "Test", amount: 1.0)

    assert_raises(ArgumentError, "Amount cannot be nil") do
      surcharge.amount = nil
    end
  end

  def test_bigdecimal_precision
    surcharge = Croatia::Invoice::Surcharge.new(name: "Precision test", amount: 1.123456789)

    assert_instance_of BigDecimal, surcharge.amount
    assert_equal BigDecimal("1.123456789"), surcharge.amount
  end

  def test_negative_amounts_allowed
    surcharge = Croatia::Invoice::Surcharge.new(name: "Credit", amount: -2.50)

    assert_equal BigDecimal("-2.50"), surcharge.amount
  end

  def test_zero_amount_allowed
    surcharge = Croatia::Invoice::Surcharge.new(name: "Free", amount: 0)

    assert_equal BigDecimal("0"), surcharge.amount
  end

  def test_enum_inclusion
    surcharge = Croatia::Invoice::Surcharge.new(name: "Test", amount: 1.0)

    assert_includes surcharge.class.ancestors, Croatia::Enum
  end
end
