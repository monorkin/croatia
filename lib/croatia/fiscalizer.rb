# frozen_string_literal: true

require "digest/md5"
require "openssl"
require "securerandom"
require "tzinfo"

class Croatia::Fiscalizer
  autoload :XMLBuilder, "croatia/fiscalizer/xml_builder"

  TZ = TZInfo::Timezone.get("Europe/Zagreb")

  attr_reader :certificate

  def initialize(certificate: nil, password: nil)
    certificate ||= Croatia.config.fiscalization[:certificate]
    password ||= Croatia.config.fiscalization[:password]

    @certificate = load_certificate(certificate, password)
  end

  def fiscalize(invoice)
    document = XMLBuilder.invoice_request(invoice: invoice, message_id: SecureRandom.uuid, timezone: TZ)

    # TODO: Implement the fiscalization logic here
    puts "TODO: Fiscalize invoice #{invoice}"
    puts "GENERATED XML:\n#{document}"
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

  private

    def load_certificate(cert, password)
      if cert.is_a?(OpenSSL::PKCS12)
        cert.key
      elsif cert.is_a?(OpenSSL::PKey::PKey)
        cert
      else
      cert = File.read(cert) if cert.respond_to?(:to_s) && File.exist?(cert.to_s)

        begin
          OpenSSL::PKey.read(cert)
        rescue OpenSSL::PKey::PKeyError
          OpenSSL::PKCS12.new(cert, password).key
        end
      end
    end
end
