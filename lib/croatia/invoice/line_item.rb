# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class Croatia::Invoice::LineItem
  attr_accessor :description
  attr_reader :quantity, :unit, :unit_price, :tax_rate, :tax_category, :discount_rate

  def initialize(**options)
    self.description = options[:description]
    self.quantity = options.fetch(:quantity, 1)
    # self.unit = options[:unit]
    self.unit_price = options.fetch(:unit_price, 0.0)
    self.tax_rate = options.fetch(:tax_rate, 0.25)
    # self.tax_category = options[:tax_category]
  end

  def quantity=(value)
    unless value.is_a?(Numeric)
      raise ArgumentError, "Quantity must be a number"
    end

    @quantity = value.to_d
  end

  def unit_price=(value)
    unless value.is_a?(Numeric) && value >= 0
      raise ArgumentError, "Unit price must be a non-negative number"
    end

    @unit_price = value.to_d
  end

  def tax_rate=(value)
    unless value.is_a?(Numeric) && value >= 0 && value <= 1
      raise ArgumentError, "Tax rate must be a non-negative number between 0 and 1"
    end

    @tax_rate = value.to_d
  end

  def discount_rate=(value)
    if value.nil?
      @discount_rate = nil
      return
    end

    unless value.is_a?(Numeric) && value >= 0 && value <= 1
      raise ArgumentError, "Discount rate must be a non-negative number between 0 and 1"
    end

    @discount_rate = value.to_d
  end

  def discount=(value)
    if value.nil?
      @discount = nil
      return
    end

    unless value.is_a?(Numeric) && value >= 0
      raise ArgumentError, "Discount must be a non-negative number"
    end

    @discount = value.to_d.round(2, BigDecimal::ROUND_HALF_UP)
  end

  def discount
    if @discount
      @discount
    elsif @discount_rate
      (gross * @discount_rate).round(2, BigDecimal::ROUND_HALF_UP)
    else
      BigDecimal("0.0")
    end
  end

  def reverse
    self.quantity *= -1
  end

  def gross
    (quantity * unit_price).round(2, BigDecimal::ROUND_HALF_UP)
  end

  def subtotal
    gross - discount
  end

  def tax
    (subtotal * tax_rate).round(2, BigDecimal::ROUND_HALF_UP)
  end

  def total
    (subtotal + tax).round(2, BigDecimal::ROUND_HALF_UP)
  end
end
