# frozen_string_literal: true

class Croatia::QRCode
  def self.ensure_supported!
    return if supported?

    raise LoadError, "RQRCode library is not loaded. Please ensure you have the rqrcode gem installed."
  end

  def self.supported?
    defined?(RQRCode)
  end

  attr_reader :data, :options

  def initialize(data, **options)
    @data = data
    @options = options
  end
end
