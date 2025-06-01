# frozen_string_literal: true

require "openssl"

class Croatia::Invoice::Fiscalizer
  ATTRIBUTES = %i[invoice certificate password].freeze

  attr_reader(*ATTRIBUTES)

  def initialize(invoice:, certificate:, **options)
    @invoice = invoice

    options.each do |key, value|
      if ATTRIBUTES.include?(key.to_sym)
        instance_variable_set("@#{key}", value)
      else
        raise ArgumentError, "Unknown option: #{key}"
      end
    end

    self.certificate = certificate
  end

  def fiscalize
    # TODO: Implement the fiscalization logic here
    puts "TODO: Fiscalize invoice #{invoice} with options: #{options}"
  end

  def reverse
    # TODO: Implement the reverse logic here
    puts "TODO: Storno invoice #{invoice} with options: #{options}"
  end

  def issuer_protection_code(**options)
    buffer = []
    buffer << options.fetch(:issuer_pin) { invoice.issuer.pin }
    buffer << options.fetch(:issue_date) { invoice.issue_date }.strftime("%d.%m.%Y %H:%M:%S")
    buffer << options.fetch(:sequential_number) { invoice.sequential_number }
    buffer << options.fetch(:business_location_identifier) { invoice.business_location_identifier }
    buffer << options.fetch(:register_identifier) { invoice.register_identifier }
    buffer << options.fetch(:total) { invoice.total }.to_f

    digest = OpenSSL::Digest::SHA1.new
    signature = certificate.sign(digest, buffer.join)

    Digest::MD5.hexdigest(signature).downcase
  end

  def invoice_xml
  end

  protected

    def certificate=(value)
      @certificate = if value.is_a?(OpenSSL::PKCS12)
        value.key
      elsif value.is_a?(OpenSSL::PKey::PKey)
        value
      else
        begin
          OpenSSL::PKey.read(value)
        rescue OpenSSL::PKey::PKeyError
          OpenSSL::PKCS12.new(value, password).key
        end
      end
    end
end
