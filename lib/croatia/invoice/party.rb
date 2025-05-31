# frozen_string_literal: true

class Croatia::Invoice::Party
  attr_accessor \
    :address,
    :city,
    :country_code,
    :einvoice_id,
    :name,
    :pin,
    :postal_code

  def initialize(**options)
    options.each do |key, value|
      public_send("#{key}=", value)
    end
  end
end
