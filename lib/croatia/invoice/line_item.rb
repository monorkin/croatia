# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class Croatia::Invoice::LineItem
  include Croatia::Enum

  attr_accessor :description, :unit, :taxes, :surcharges
  attr_reader :quantity, :unit_price, :discount_rate, :margin

  def initialize(**options)
    self.description = options[:description]
    self.quantity = options.fetch(:quantity, 1)
    self.unit = options[:unit]
    self.unit_price = options.fetch(:unit_price, 0.0)
    self.taxes = options.fetch(:taxes, {})
    self.surcharges = options.fetch(:surcharges, {})
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

  def margin=(value)
    if margin.nil?
      @margin = nil
      return
    end

    unless value.is_a?(Numeric) && value >= 0
      raise ArgumentError, "Margin must be a non-negative number"
    end

    @margin = value.to_d.round(2, BigDecimal::ROUND_HALF_UP)
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

  def taxable_base
    margin ? margin : subtotal
  end

  def tax_breakdown
    taxes.filter_map do |type, tax|
      next if tax.nil?

      {
        rate: tax.rate,
        base: taxable_base,
        margin: margin,
        tax: (taxable_base * tax.rate).round(2, BigDecimal::ROUND_HALF_UP),
        taxable: !tax.exempt?,
        name: tax.other? ? tax.name : tax.type,
        type: tax.type,
        category: tax.category
      }
    end
  end

  def tax
    tax_breakdown.sum { |breakdown| breakdown[:tax] }
  end

  def surcharge
    surcharges.values.sum(&:amount).to_d.round(2, BigDecimal::ROUND_HALF_UP)
  end

  def total
    (subtotal + tax + surcharge).round(2, BigDecimal::ROUND_HALF_UP)
  end

  def add_tax(tax = nil, **options, &block)
    if tax.nil?
      tax = Croatia::Invoice::Tax.new(**options)
    end

    tax.tap(&block) if block_given?

    taxes[tax.type] = tax
    tax
  end

  def remove_tax(type)
    taxes.delete(type)
  end

  def clear_taxes
    taxes.clear
  end

  def vat_exempt?
    !!taxes[:value_added_tax]&.exempt?
  end

  def outside_vat_scope?
    !!taxes[:value_added_tax]&.outside_scope?
  end

  def add_surcharge(surcharge = nil, **options, &block)
    if surcharge.nil?
      surcharge = Croatia::Invoice::Surcharge.new(**options)
    end

    surcharge.tap(&block) if block_given?

    surcharges[surcharge.name] = surcharge
    surcharge
  end

  def remove_surcharge(name)
    surcharges.delete(name)
  end

  def clear_surcharges
    surcharges.clear
  end
end
