# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class Croatia::Invoice::Tax
  include Croatia::Enum

  attr_reader :rate

  enum :type, %i[ value_added_tax consumption_tax other ]
  enum :category, %i[ standard lower_rate exempt zero_rated outside_scope reverse_charge ]

  def initialize(rate: nil, type: :value_added_tax, category: :standard)
    self.type = type
    self.category = category
    self.rate = rate ? rate : Croatia.config.tax_rates[type][category]
  end

  def rate=(value)
    if !value.is_a?(Numeric) || value < 0 || value > 1
      raise ArgumentError, "Tax rate must be a number between 0 and 1"
    end

    @rate = value.to_d
  end

  def name=(value)
    if value.nil?
      @name = nil
      return
    end

    unless values.respond_to?(:to_s)
      raise ArgumentError, "Tax name must be castable to a string"
    end

    value = value.to_s

    if value.length > 100
      raise ArgumentError, "Tax name must not exceed 100 characters"
    end

    @name = value
  end

  def name
    if @name
      @name
    elsif value_added_tax?
      "Porez na dodanu vrijednost"
    elsif consumption_tax?
      "Porez na potrošnju"
    end
  end
end
