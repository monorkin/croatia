# frozen_string_literal: true

require "digest/md5"
require "openssl"
require "securerandom"
require "tzinfo"
require "uri"

class Croatia::Fiscalizer
  autoload :XMLBuilder, "croatia/fiscalizer/xml_builder"

  TZ = TZInfo::Timezone.get("Europe/Zagreb")
  QR_CODE_BASE_URL = "https://porezna.gov.hr/rn"

  attr_reader :certificate

  def initialize(certificate: nil, password: nil)
    certificate ||= Croatia.config.fiscalization[:certificate]
    password ||= Croatia.config.fiscalization[:password]

    @certificate = load_certificate(certificate, password)
  end

  def fiscalize(invoice:, message_id: SecureRandom.uuid)
    _document = XMLBuilder.invoice_request(invoice: invoice, message_id: message_id, timezone: TZ)
    raise NotImplementedError, "Fiscalization XML generation is not implemented yet"
  end

  def generate_issuer_protection_code(invoice)
    buffer = []
    buffer << invoice.issuer.pin
    buffer << TZ.to_local(invoice.issue_date).strftime("%d.%m.%Y %H:%M:%S")
    buffer << invoice.sequential_number
    buffer << invoice.business_location_identifier
    buffer << invoice.register_identifier
    buffer << invoice.total.to_f

    digest = OpenSSL::Digest::SHA1.new
    signature = certificate.sign(digest, buffer.join)

    Digest::MD5.hexdigest(signature).downcase
  end

  def generate_verification_qr_code(invoice)
    Croatia::QRCode.ensure_supported!

    params = {
      datv: TZ.to_local(invoice.issue_date).strftime("%Y%m%d_%H%M"),
      izn: invoice.total_cents.to_s
    }

    if params[:izn].length > 10
      raise ArgumentError, "Total amount exceeds 10 digits: #{params[:izn]}"
    end

    if invoice.unique_invoice_identifier
      params[:jir] = invoice.unique_invoice_identifier
    else
      params[:zki] = generate_issuer_protection_code(invoice)
    end

    if params[:jir].nil? && params[:zki].nil?
      raise ArgumentError, "Either unique_invoice_identifier or issuer_protection_code must be provided"
    end

    query_string = URI.encode_www_form(params)
    url = "#{QR_CODE_BASE_URL}?#{query_string}"

    Croatia::QRCode.new(url)
  end

  private

    def load_certificate(cert, password)
      if cert.is_a?(OpenSSL::PKCS12)
        cert.key
      elsif cert.is_a?(OpenSSL::PKey::PKey)
        cert
      else
        begin
          cert = File.read(cert) if cert.respond_to?(:to_s) && File.exist?(cert.to_s)
        rescue ArgumentError
        end

        begin
          OpenSSL::PKey.read(cert)
        rescue OpenSSL::PKey::PKeyError
          OpenSSL::PKCS12.new(cert, password).key
        end
      end
    end
end
