# frozen_string_literal: true

require "digest/md5"
require "net/http"
require "openssl"
require "securerandom"
require "tzinfo"
require "uri"

class Croatia::Fiscalizer
  autoload :XMLBuilder, "croatia/fiscalizer/xml_builder"

  TZ = TZInfo::Timezone.get("Europe/Zagreb")
  QR_CODE_BASE_URL = "https://porezna.gov.hr/rn"
  DEFAULT_PORT = 443
  DEFAULT_TIMEOUT = 30
  USER_AGENT = "Croatia/#{Croatia::VERSION} Ruby/#{RUBY_VERSION} (Fiscalization Client; +https://github.com/monorkin/croatia)"

  class << self
    attr_accessor :http_clients

    def with_http_client_for(**options, &block)
      client = http_client_for(**options)
      retrying = false

      begin
        block.call(client)
      rescue IOError, EOFError, Errno::ECONNRESET
        raise if retrying

        retrying = true
        client.finish rescue nil
        client.start

        retry
      end
    end

    def http_client_for(host:, credential:, port: DEFAULT_PORT, timeout: DEFAULT_TIMEOUT)
      self.http_clients ||= {}

      # MD5 is fast, but not cryptographically secure.
      # So the fingerprint is computed on less sensitive information.
      fingerprint = Digest::MD5.hexdigest("#{credential.certificate.serial}:#{credential.certificate.subject}")
      key = "#{host}:#{port}/#{fingerprint}?timeout=#{timeout}"

      client = http_clients[key]

      if client&.active?
        return client
      end

      client&.finish rescue nil
      http_clients[key] = Net::HTTP.new(host, port).tap do |client|
        client.use_ssl = true
        client.verify_mode = OpenSSL::SSL::VERIFY_PEER
        client.cert = credential.certificate
        client.key = credential.key
        client.keep_alive_timeout = timeout
        client.start
      end
    end

    def shutdown_all_clients
      http_clients&.each_value { |c| c.finish rescue nil }
      self.http_clients = {}
    end
  end

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
