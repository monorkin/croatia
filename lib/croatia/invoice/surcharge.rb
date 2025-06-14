# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class Croatia::Invoice::Surcharge
  include Croatia::Enum

  attr_reader :name, :amount

  def initialize(name:, amount:)
    self.name = name
    self.amount = amount
  end

  def name=(value)
    if value.nil?
      raise ArgumentError, "Name cannot be nil"
    end

    value = value.to_s.strip

    if value.length > 100
      raise ArgumentError, "Name must not exceed 100 characters"
    end

    @name = value
  end

  def amount=(value)
    if value.nil?
      raise ArgumentError, "Amount cannot be nil"
    end

    @amount = value.to_d
  end
end
