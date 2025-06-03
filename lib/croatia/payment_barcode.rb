# frozen_string_literal: true

class Croatia::PaymentBarcode
  HEADER = "HRVHUB30"
  EXACT_LENGTH_FIELDS = %i[ header currency total_cents model payment_purpose_code ].freeze
  FIELD_MAX_LENGTHS = {
    header: 8,
    currency: 3,
    total_cents: 15,
    buyer_name: 30,
    buyer_address: 27,
    buyer_postal_code_and_city: 27,
    seller_name: 25,
    seller_address: 25,
    seller_postal_code_and_city: 27,
    seller_iban: 21,
    model: 4,
    reference_number: 22,
    payment_purpose_code: 4,
    description: 35
  }.freeze

  attr_accessor \
    :buyer_address,
    :buyer_city,
    :buyer_name,
    :buyer_postal_code,
    :currency,
    :description,
    :model,
    :payment_purpose_code,
    :reference_number,
    :seller_address,
    :seller_city,
    :seller_iban,
    :seller_name,
    :seller_postal_code,
    :total_cents

  def initialize(**options)
    options.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def data
    data = {
      header: HEADER,
      currency: currency,
      total_cents: total_cents.to_s.rjust(FIELD_MAX_LENGTHS[:total_cents], "0"),
      buyer_name: buyer_name,
      buyer_address: buyer_address,
      buyer_postal_code_and_city: "#{buyer_postal_code} #{buyer_city}".strip,
      seller_name: seller_name,
      seller_address: seller_address,
      seller_postal_code_and_city: "#{seller_postal_code} #{seller_city}".strip,
      seller_iban: seller_iban,
      model: model,
      reference_number: reference_number,
      payment_purpose_code: payment_purpose_code,
      description: description
    }

    data.each do |key, value|
      next if value.nil?

      max_length = FIELD_MAX_LENGTHS[key]

      if EXACT_LENGTH_FIELDS.include?(key) && value.length != max_length
        raise ArgumentError, "Value '#{value}' of field '#{key}' must be exactly #{max_length} characters long"
      elsif value.length > max_length
        raise ArgumentError, "Value '#{value}' of field '#{key}' exceeds maximum length of #{max_length} characters"
      end
    end

    if data[:seller_iban] && (!data[:seller_iban].match?(/\A[a-z]{2}\d{19}\Z/i) && !data[:seller_iban].match?(/\A\d{7}-\d{10}\Z/i))
      raise ArgumentError, "Invalid IBAN format '#{data[:seller_iban]}' expected IBAN or account number"
    end

    data.values.join("\n")
  end

  def barcode
    Croatia::PDF417.ensure_supported!
    Croatia::PDF417.new(data)
  end

  def to_png(...)
    barcode.to_png(...)
  end

  def to_svg(...)
    barcode.to_svg(...)
  end
end
