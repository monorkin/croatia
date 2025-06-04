# frozen_string_literal: true

module Croatia::Invoice::Fiscalizable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def fiscalize!(**options)
      Croatia::Fiscalizer.new(**options).fiscalize(invoice: self)
    end

    def reverse!(**options)
      line_items.each(&:reverse)
      Croatia::Fiscalizer.new(**options).fiscalize(invoice: self)
    end

    def issuer_protection_code(**options)
      Croatia::Fiscalizer
        .new(**options)
        .generate_issuer_protection_code(self)
    end

    def fiscalization_qr_code(**options)
      Croatia::Fiscalizer
        .new(**options)
        .generate_verification_qr_code(self)
    end
  end
end
