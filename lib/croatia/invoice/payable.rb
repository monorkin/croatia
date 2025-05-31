# frozen_string_literal: true

module Croatia::Invoice::Payable
  BARCODE_HEADER = "HRVHUB30"

  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def payment_barcode(name: nil, iban: nil, description: nil, model: nil, reference_number: nil)
      Croatia::PDF417.ensure_supported!

      if currency.length != 3
        raise ArgumentError, "Currency code must be 3 characters long"
      end

      amount = total_cents.to_s.rjust(12, "0")
      if amount.length > 12
        raise ArgumentError, "Total amount exceeds 12 digits: #{amount}"
      end

      name ||= seller.name
      if name.length > 30
        raise ArgumentError, "Name must be 30 characters or less: #{name}"
      end

      iban ||= seller.iban
      if iban.length != 21
        raise ArgumentError, "IBAN must be 21 characters: #{iban}"
      end

      description ||= "Račun br. #{number}"
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
        name,
        iban,
        description,
        model,
        reference_number,
        due_date&.strftime("%Y%m%d")
      ]

      Croatia::PDF417.new(data.join("\n"))
    end
  end
end
