# frozen_string_literal: true

# Generates Croatian payment barcodes (HUB-3 format) for bank transfers
#
# This class creates barcodes compatible with Croatian banking standards that can be
# scanned by banking applications to pre-fill payment forms.
#
# @example Creating a basic payment barcode
#   barcode = Croatia::PaymentBarcode.new(
#     currency: "HRK",
#     total_cents: 15000,
#     buyer_name: "John Doe",
#     seller_name: "Company Ltd",
#     seller_iban: "HR1234567890123456789",
#     model: "HR01",
#     reference_number: "123-456-789",
#     payment_purpose_code: "SALA",
#     description: "Monthly salary"
#   )
#   barcode.to_png
#
# @author Croatia Gem
# @since 0.2.0
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

  # @!attribute [rw] buyer_address
  #   @return [String] buyer's street address
  # @!attribute [rw] buyer_city
  #   @return [String] buyer's city
  # @!attribute [rw] buyer_name
  #   @return [String] buyer's full name (max 30 chars)
  # @!attribute [rw] buyer_postal_code
  #   @return [String] buyer's postal code
  # @!attribute [rw] currency
  #   @return [String] 3-letter currency code (e.g., "HRK", "EUR")
  # @!attribute [rw] description
  #   @return [String] payment description (max 35 chars)
  # @!attribute [rw] model
  #   @return [String] reference model code (exactly 4 chars)
  # @!attribute [rw] payment_purpose_code
  #   @return [String] payment purpose code (exactly 4 chars)
  # @!attribute [rw] reference_number
  #   @return [String] payment reference number (max 22 chars)
  # @!attribute [rw] seller_address
  #   @return [String] seller's street address
  # @!attribute [rw] seller_city
  #   @return [String] seller's city
  # @!attribute [rw] seller_iban
  #   @return [String] seller's IBAN or account number
  # @!attribute [rw] seller_name
  #   @return [String] seller's full name (max 25 chars)
  # @!attribute [rw] seller_postal_code
  #   @return [String] seller's postal code
  # @!attribute [rw] total_cents
  #   @return [Integer] payment amount in cents
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

  # Creates a new payment barcode instance
  #
  # @param options [Hash] payment details
  # @option options [String] :buyer_name buyer's full name
  # @option options [String] :buyer_address buyer's street address
  # @option options [String] :buyer_city buyer's city
  # @option options [String] :buyer_postal_code buyer's postal code
  # @option options [String] :seller_name seller's full name
  # @option options [String] :seller_address seller's street address
  # @option options [String] :seller_city seller's city
  # @option options [String] :seller_postal_code seller's postal code
  # @option options [String] :seller_iban seller's IBAN or account number
  # @option options [String] :currency 3-letter currency code
  # @option options [Integer] :total_cents payment amount in cents
  # @option options [String] :model reference model code (4 chars)
  # @option options [String] :reference_number payment reference number
  # @option options [String] :payment_purpose_code payment purpose code (4 chars)
  # @option options [String] :description payment description
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
