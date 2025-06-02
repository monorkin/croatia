# frozen_string_literal: true

class Croatia::Config
  DEFAULT_TAX_RATES = {
    value_added_tax: {
      standard: 0.25,
      lower_rate: 0.13,
      exempt: 0.0,
      zero_rated: 0.0,
      outside_scope: 0.0,
      reverse_charge: 0.0
    },
    consumption_tax: Hash.new(0.0),
    other: Hash.new(0.0)
  }

  attr_accessor :tax_rates

  def initialize(**options)
    self.tax_rates = options.delete(:tax_rates) { DEFAULT_TAX_RATES }
  end
end
