# frozen_string_literal: true

require "uri"

module Croatia::Invoice::Fiscalizable
  QR_CODE_BASE_URL = "https://porezna.gov.hr/rn"

  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def fiscalize!(**options)
      Croatia::Invoice::Fiscalizer.new(**options, invoice: self).fiscalize
    end

    def reverse!(**options)
      Croatia::Invoice::Fiscalizer.new(**options, invoice: self).reverse
    end

    def qr_code
      unless defined?(RQRCode)
        raise LoadError, "RQRCode is not available. Please add it to your Gemfile or require it."
      end

      params = {
        datv: issue_date.strftime("%Y%m%d_%H%M"),
        izn: total_cents.to_s
      }

      if data[:izn].length > 10
        raise ArgumentError, "Total amount exceeds 10 digits: #{data[:izn]}"
      end

      if unique_invoice_identifier
        data[:jir] = unique_invoice_identifier
      else
        data[:zki] = issuer_protection_code
      end

      query_string = URI.encode_www_form(params)
      url = "#{QR_CODE_BASE_URL}?#{query_string}"

      RQRCode::QRCode.new(url)
    end
  end
end
