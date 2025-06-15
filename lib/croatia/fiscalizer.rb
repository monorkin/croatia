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

  attr_reader :credential

  def initialize(credential: nil, password: nil)
    credential ||= Croatia.config.fiscalization[:credential]
    password ||= Croatia.config.fiscalization[:password]

    @credential = load_credential(credential, password)
  end

  def fiscalize(invoice:, message_id: SecureRandom.uuid)
    document = XMLBuilder.invoice(invoice: invoice, message_id: message_id, timezone: TZ)
    document = XMLBuilder.sign(document: document, credential: credential)
    raise NotImplementedError, "Fiscalization XML generation is not implemented yet"
  end

  def generate_issuer_protection_code(invoice)
    buffer = []
    buffer << invoice.issuer.pin
    buffer << TZ.to_local(invoice.issue_date).strftime("%d.%m.%Y %H:%M:%S")
    buffer << invoice.sequential_number
    buffer << invoice.business_location_identifier
    buffer << invoice.register_identifier
    buffer << format("%.2f", invoice.total)

    digest = OpenSSL::Digest::SHA1.new
    signature = credential.key.sign(digest, buffer.join)

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

    def load_credential(credential, password)
      case credential
      in OpenSSL::PKCS12
        credential
      in String if is_a_file_path?(credential)
        OpenSSL::PKCS12.new(File.read(credential), password)
      in String
        OpenSSL::PKCS12.new(credential, password)
      in { private_key: String, certificate: String, **rest }
        private_key_content = is_a_file_path?(credential[:private_key]) ? File.read(credential[:private_key]) : credential[:private_key]
        certificate_content = is_a_file_path?(credential[:certificate]) ? File.read(credential[:certificate]) : credential[:certificate]

        private_key = OpenSSL::PKey::RSA.new(private_key_content)
        certificate = OpenSSL::X509::Certificate.new(certificate_content)

        ca_chain = rest[:ca_chain] # may be nil or missing
        ca_certs = if ca_chain
          ca_chain_content = is_a_file_path?(ca_chain) ? File.read(ca_chain) : ca_chain
          [ OpenSSL::X509::Certificate.new(ca_chain_content) ]
        else
          nil
        end

        OpenSSL::PKCS12.create(password, "FISKAL1", private_key, certificate, ca_certs)
      else
        raise ArgumentError, "Invalid credential format"
      end
    end

    def is_a_file_path?(path)
      File.exist?(path) && File.file?(path) && File.readable?(path)
    rescue ArgumentError
      false
    end
end
