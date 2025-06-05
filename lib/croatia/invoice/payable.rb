# frozen_string_literal: true

# Provides payment barcode generation functionality for Croatian invoices
#
# This concern adds the ability to generate HUB-3 compatible payment barcodes
# for Croatian bank transfers. The generated barcodes can be scanned by banking
# applications to pre-fill payment forms with invoice details.
#
# The payment barcode includes:
# - Currency and total amount
# - Buyer and seller information (names, addresses, postal codes, cities)
# - Seller's IBAN or account number
# - Optional payment reference details (model, reference number, purpose code)
# - Payment description (defaults to "Račun {invoice_number}")
#
# @example Basic usage
#   invoice = Croatia::Invoice.new
#   invoice.buyer = Croatia::Invoice::Party.new(name: "John Doe", address: "Address 1")
#   invoice.seller = Croatia::Invoice::Party.new(name: "Company", iban: "HR1234567890123456789")
#
#   barcode = invoice.payment_barcode
#   png_data = barcode.to_png
#
# @example With custom parameters
#   barcode = invoice.payment_barcode(
#     description: "Payment for services",
#     model: "HR01",
#     reference_number: "123-456-789",
#     payment_purpose_code: "SALA"
#   )
#
# @see Croatia::PaymentBarcode
# @author Croatia Gem
# @since 0.2.0
module Croatia::Invoice::Payable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    # Generates a Croatian HUB-3 payment barcode for the invoice
    #
    # Creates a payment barcode that can be scanned by Croatian banking applications
    # to pre-fill payment forms. The barcode contains all necessary payment information
    # including amounts, party details, and optional payment references.
    #
    # @param description [String, nil] payment description (defaults to "Račun {invoice_number}")
    # @param model [String, nil] payment model code (exactly 4 characters, e.g., "HR01")
    # @param reference_number [String, nil] payment reference number (max 22 characters)
    # @param payment_purpose_code [String, nil] payment purpose code (exactly 4 characters, e.g., "SALA")
    # @return [Croatia::PaymentBarcode] the generated payment barcode
    # @raise [ArgumentError] if buyer or seller is not set
    # @raise [ArgumentError] if any parameter exceeds length limits or has invalid format
    #
    # @example Basic payment barcode
    #   barcode = invoice.payment_barcode
    #   # Uses default description "Račun 123/OFFICE/1"
    #
    # @example With custom description
    #   barcode = invoice.payment_barcode(description: "Monthly service fee")
    #
    # @example With full payment reference
    #   barcode = invoice.payment_barcode(
    #     description: "Invoice payment",
    #     model: "HR01",
    #     reference_number: "123-456-789",
    #     payment_purpose_code: "SALA"
    #   )
    #
    # @example Generating different output formats
    #   barcode = invoice.payment_barcode
    #   png_data = barcode.to_png                    # PNG binary data
    #   svg_markup = barcode.to_svg                  # SVG markup string
    #   raw_data = barcode.data                      # Raw barcode data string
    #
    # @note The invoice must have buyer and seller set with complete information
    # @note The seller must have a valid IBAN or Croatian account number
    # @see Croatia::PaymentBarcode
    def payment_barcode(description: nil, model: nil, reference_number: nil, payment_purpose_code: nil)
      if buyer.nil? || seller.nil?
        raise ArgumentError, "Both buyer and seller must be set before generating a payment barcode"
      end

      description ||= "Račun #{number}"

      options = {
        currency: currency,
        total_cents: total_cents,
        buyer_name: buyer.name,
        buyer_address: buyer.address,
        buyer_postal_code: buyer.postal_code,
        buyer_city: buyer.city,
        seller_name: seller.name,
        seller_address: seller.address,
        seller_postal_code: seller.postal_code,
        seller_city: seller.city,
        seller_iban: seller.iban,
        model: model,
        reference_number: reference_number,
        payment_purpose_code: payment_purpose_code,
        description: description
      }

      Croatia::PaymentBarcode.new(**options)
    end
  end
end
