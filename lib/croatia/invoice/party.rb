# frozen_string_literal: true

class Croatia::Invoice::Party
  attr_reader :pin
  attr_accessor \
    :address,
    :city,
    :country_code,
    :einvoice_id,
    :iban,
    :name,
    :pays_vat,
    :postal_code

  def initialize(**options)
    options.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def pin=(value)
    value = value.to_s.strip

    unless Croatia::PIN.valid?(value)
      raise ArgumentError, "Invalid PIN"
    end

    @pin = value
  end
end
