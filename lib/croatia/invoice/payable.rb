# frozen_string_literal: true

module Croatia::Invoice::Payable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def payment_barcode(description: nil, model: nil, reference_number: nil, payment_purpose_code: nil)
      if buyer.nil? || seller.nil?
        raise ArgumentError, "Both buyer and seller must be set before generating a payment barcode"
      end

      description ||= "Racun #{number}"

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
