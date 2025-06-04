# frozen_string_literal: true

class Croatia::QRCode
  def self.ensure_supported!
    return if supported?

    raise LoadError, "RQRCode library is not loaded. Please ensure you have the rqrcode gem installed and required."
  end

  def self.supported?
    defined?(RQRCode)
  end

  attr_reader :data, :options

  def initialize(data, **options)
    @data = data
    @options = options
  end

  def to_svg(**options)
    qr_code.as_svg(**options)
  end

  def to_png(**options)
    qr_code.as_png(**options)
  end

  private

    def qr_code
      @qr_code ||= RQRCode::QRCode.new(data, **options)
    end
end
