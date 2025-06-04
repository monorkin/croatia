# frozen_string_literal: true

# Represents a QR code
#
# @example Creating a QR code
#   qr = Croatia::QRCode.new("https://example.com")
#   qr.to_png
#   qr.to_svg
#
# @note Requires the rqrcode gem to be installed and available
# @author Croatia Gem
# @since 0.2.0
class Croatia::QRCode
  # Ensures the all required libraries are available for QR code generation
  #
  # @raise [LoadError] if the rqrcode gem is not available
  # @return [void]
  def self.ensure_supported!
    return if supported?

    raise LoadError, "RQRCode library is not loaded. Please ensure you have the rqrcode gem installed and required."
  end

  # Checks if all required libraries are available
  #
  # @return [Boolean] true if RQRCode is available, false otherwise
  def self.supported?
    defined?(RQRCode)
  end

  # @!attribute [r] data
  #   @return [String] the data to encode in the QR code
  # @!attribute [r] options
  #   @return [Hash] QR code generation options
  attr_reader :data, :options

  # Creates a new QR code instance
  #
  # @param data [String] the data to encode in the QR code
  # @param options [Hash] QR code generation options passed to RQRCode
  def initialize(data, **options)
    @data = data
    @options = options
  end

  # Generates the QR code as an SVG image
  #
  # @param options [Hash] rendering options passed to RQRCode
  # @return [String] SVG markup for the QR code
  def to_svg(**options)
    qr_code.as_svg(**options)
  end

  # Generates the QR code as a PNG image
  #
  # @param options [Hash] rendering options passed to RQRCode
  # @return [ChunkyPNG::Image] PNG image object
  def to_png(**options)
    qr_code.as_png(**options)
  end

  private

    def qr_code
      @qr_code ||= RQRCode::QRCode.new(data, **options)
    end
end
