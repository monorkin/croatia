# frozen_string_literal: true

# Represent a PDF417 barcodes
#
# @example Creating a PDF417 barcode
#   pdf417 = Croatia::PDF417.new("Sample data")
#   pdf417.to_png
#   pdf417.to_svg
#
# @note Requires the ruby-zint gem to be installed and available
# @author Croatia Gem
# @since 0.2.0
class Croatia::PDF417
  # Ensures the all required libraries are available for PDF417 generation
  #
  # @raise [LoadError] if the ruby-zint gem is not available
  # @return [void]
  def self.ensure_supported!
    return if supported?

    raise LoadError, "Zint library is not loaded. Please ensure you have the ruby-zint gem installed and required."
  end

  # Checks if the all required libraries are available
  #
  # @return [Boolean] true if Zint is available, false otherwise
  def self.supported?
    defined?(Zint)
  end

  # @!attribute [r] data
  #   @return [String] the data to encode in the barcode
  # @!attribute [r] options
  #   @return [Hash] barcode generation options
  attr_reader :data, :options

  # Creates a new PDF417 barcode instance
  #
  # @param data [String] the data to encode in the barcode
  # @param options [Hash] barcode generation options passed to Zint
  def initialize(data, **options)
    @data = data
    @options = options
  end

  # Generates the barcode as an SVG image
  #
  # @param options [Hash] rendering options
  # @option options [String] :foreground_color ("black") color for barcode elements
  # @option options [String] :background_color ("white") background color
  # @return [String] SVG markup for the barcode
  def to_svg(**options)
    vec = barcode.to_vector

    foreground_color = options[:foreground_color] || "black"
    background_color = options[:background_color] || "white"

    svg = []
    svg << %Q(<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="#{vec.width.to_i}" height="#{vec.height.to_i}" viewBox="0 0 #{vec.width.to_i} #{vec.height.to_i}">)
    svg << %Q(<rect width="#{vec.width.to_i}" height="#{vec.height.to_i}" fill="#{background_color}" />)

    vec.each_rectangle do |rect|
      svg << %Q(<rect x="#{rect.x.to_i}" y="#{rect.y.to_i}" width="#{rect.width.to_i}" height="#{rect.height.to_i}" fill="#{foreground_color}" />)
    end

    svg << "</svg>"
    svg.join("\n")
  end

  # Generates the barcode as a PNG image
  #
  # @param options [Hash] rendering options passed to Zint
  # @return [String] PNG binary data
  def to_png(**options)
    barcode.to_memory_file(extension: ".png")
  end

  private

    def barcode
      @barcode ||= Zint::Barcode.new(**options, value: data, symbology: Zint::BARCODE_PDF417)
    end
end
