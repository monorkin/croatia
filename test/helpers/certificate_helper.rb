# frozen_string_literal: true

module CertificateHelper
  DEFAULT_PASSWORD = "test?password123"

  def generate_test_certificate(path = nil, password: DEFAULT_PASSWORD)
    key = OpenSSL::PKey::RSA.new(2048)

    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = Random.rand(100_000)
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test Certificate")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + 36500 * 24 * 60 * 60

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.add_extension ef.create_extension("basicConstraints", "CA:FALSE", true)
    cert.add_extension ef.create_extension("keyUsage", "digitalSignature,keyEncipherment", true)

    cert.sign(key, OpenSSL::Digest::SHA256.new)

    p12 = OpenSSL::PKCS12.create(password, "Test Certificate", key, cert)

    if path
      dir = File.dirname(path)
      Dir.mkdir_p(dir) unless File.exist?(dir)
      File.write(path, p12.to_der)
    end

    {
      key: key,
      cert: cert,
      p12: p12,
      path: path,
      password: password
    }
  end
end
