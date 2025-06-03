# frozen_string_literal: true

module Croatia::Invoice::Payable
  BARCODE_HEADER = "HRVHUB30"
  BARCODE_EXACT_LENGTH_FIELDS = %i[ header currency total model payment_purpose_code ].freeze
  BARCODE_FIELD_MAX_LENGTHS = {
    header: 8,
    currency: 3,
    total: 15,
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

  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def payment_barcode(description: nil, model: nil, reference_number: nil, payment_purpose_code: nil)
      Croatia::PDF417.ensure_supported!

      if buyer.nil? || seller.nil?
        raise ArgumentError, "Both buyer and seller must be set before generating a payment barcode"
      end

      description ||= "Racun #{number}"

      data = {
        header: BARCODE_HEADER,
        currency: currency,
        total: total_cents.to_s.rjust(BARCODE_FIELD_MAX_LENGTHS[:total], "0"),
        buyer_name: buyer.name,
        buyer_address: buyer.address,
        buyer_postal_code_and_city: "#{buyer.postal_code} #{buyer.city}".strip,
        seller_name: seller.name,
        seller_address: seller.address,
        seller_postal_code_and_city: "#{seller.postal_code} #{seller.city}".strip,
        seller_iban: seller.iban,
        model: model,
        reference_number: reference_number,
        payment_purpose_code: payment_purpose_code,
        description: description
      }

      data.each do |key, value|
        next if value.nil?

        max_length = BARCODE_FIELD_MAX_LENGTHS[key]

        if BARCODE_EXACT_LENGTH_FIELDS.include?(key) && value.length != max_length
          raise ArgumentError, "Value '#{value}' of field '#{key}' must be exactly #{max_length} characters long"
        elsif value.length > max_length
          raise ArgumentError, "Value '#{value}' of field '#{key}' exceeds maximum length of #{max_length} characters"
        end
      end

      if data[:seller_iban] && (!data[:seller_iban].match?(/\A[a-z]{2}\d{19}\Z/i) && !data[:seller_iban].match?(/\A\d{7}-\d{10}\Z/i))
        raise ArgumentError, "Invalid IBAN format '#{data[:seller_iban]}' expected IBAN or account number"
      end

      Croatia::PDF417.new(data.values.join("\n"))
    end
  end
end
