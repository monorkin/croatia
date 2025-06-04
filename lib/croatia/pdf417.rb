# frozen_string_literal: true

class Croatia::PDF417
  def self.ensure_supported!
    return if supported?

    raise LoadError, "Zint library is not loaded. Please ensure you have the ruby-zint gem installed and required."
  end

  def self.supported?
    defined?(Zint)
  end

  attr_reader :data, :options

  def initialize(data, **options)
    @data = data
    @options = options
  end

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

  def to_png(**options)
    barcode.to_memory_file(extension: ".png")
  end

  private

    def barcode
      @barcode ||= Zint::Barcode.new(**options, value: data, symbology: Zint::BARCODE_PDF417)
    end
end
