# frozen_string_literal: true

require "uri"

module Croatia::Invoice::Fiscalizable
  QR_CODE_BASE_URL = "https://porezna.gov.hr/rn"

  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
    def fiscalize!(**options)
      Croatia::Invoice::Fiscalizer.new(**options).fiscalize(self)
    end

    def reverse!(**options)
      line_items.each(&:reverse)
      Croatia::Invoice::Fiscalizer.new(**options).fiscalize(self)
    end

    def issuer_protection_code(**options)
      Croatia::Invoice::Fiscalizer
        .new(**options)
        .generate_issuer_protection_code(self)
    end

    def fiscalization_qr_code(**options)
      Croatia::QRCode.ensure_supported!


      params = {
        datv: options.fetch(:issue_date) { issue_date }.strftime("%Y%m%d_%H%M"),
        izn: options.fetch(:total_cents) { total_cents }.to_i.to_s
      }

      if params[:izn].length > 10
        raise ArgumentError, "Total amount exceeds 10 digits: #{params[:izn]}"
      end

      uii = options.fetch(:unique_invoice_identifier) { unique_invoice_identifier }

      if uii
        params[:jir] = uii
      elsif !params[:zki]
        ipc = options.fetch(:issuer_protection_code) { issuer_protection_code(**options) }
        params[:zki] = ipc if ipc
      end

      raise ArgumentError, "Either unique_invoice_identifier or issuer_protection_code must be provided" unless params[:jir] || params[:zki]

      query_string = URI.encode_www_form(params)
      url = "#{QR_CODE_BASE_URL}?#{query_string}"

      Croatia::QRCode.new(url)
    end
  end
end
