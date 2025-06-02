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
  DEFAULT_FISCALIZATION = {}

  attr_accessor :tax_rates, :fiscalization

  def initialize(**options)
    self.tax_rates = options.delete(:tax_rates) { deep_dup(DEFAULT_TAX_RATES) }
    self.fiscalization = options.delete(:fiscalization) { deep_dup(DEFAULT_FISCALIZATION) }
  end

  private

    def deep_dup(object)
      Marshal.load(Marshal.dump(object))
    end
end
