# frozen_string_literal: true

module Croatia::Invoice::Payable
  BARCODE_HEADER = "HRVHUB30"

  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def payment_barcode(description: nil, model: nil, reference_number: nil)
      Croatia::PDF417.ensure_supported!

      if currency.length != 3
        raise ArgumentError, "Currency code must be 3 characters long"
      end

      amount = total_cents.to_s.rjust(12, "0")
      if amount.length > 12
        raise ArgumentError, "Total amount exceeds 12 digits: #{amount}"
      end

      iban ||= seller.iban
      if iban.length != 21
        raise ArgumentError, "IBAN must be 21 characters: #{iban}"
      end

      description ||= "Racun #{number}"
      if description.length > 35
        raise ArgumentError, "Description must be 35 characters or less: #{description}"
      end

      if model && model.length != 4
        raise ArgumentError, "Model must be 4 characters long: #{model}"
      end

      if reference_number && reference_number.length > 22
        raise ArgumentError, "Reference number must be 22 characters or less: #{reference_number}"
      end

      data = [
        BARCODE_HEADER,
        currency,
        amount,
        buyer.name,
        buyer.address,
        "#{buyer.postal_code} #{buyer.city}".strip,
        seller.name,
        seller.address,
        "#{seller.postal_code} #{seller.city}".strip,
        iban,
        "#{model} #{reference_number}".strip,
        description
      ]

      Croatia::PDF417.new(data.join("\n"))
    end
  end
end
