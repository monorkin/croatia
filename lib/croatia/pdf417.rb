# frozen_string_literal: true

class Croatia::PDF417
  def self.ensure_supported!
    return if supported?

    raise LoadError, "PDF417 library is not loaded. Please ensure you have the pdf-417 gem installed."
  end

  def self.supported?
    defined?(PDF417)
  end

  attr_reader :data, :options

  def initialize(data, **options)
    @data = data
    @options = options
  end

  def to_svg(**options)
    ary = bar

    unless ary
      raise ArgumentError, "Data is not valid for PDF417 encoding"
    end

    options[:x_scale] ||= 1
    options[:y_scale] ||= 1
    options[:margin]  ||= 10

    full_width  = (ary.first.size * options[:x_scale]) + (options[:margin] * 2)
    full_height = (ary.size       * options[:y_scale]) + (options[:margin] * 2)

    dots = ary.map { |l| l.chars.map { |c| c == "1" } }

    svg = []
    svg << %Q(<?xml version="1.0" standalone="no"?>)
    svg << %Q(<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="#{full_width}" height="#{full_height}">)
    svg << %Q(<rect width="100%" height="100%" fill="white" />)

    y = options[:margin]
    dots.each do |line|
      x = options[:margin]
      line.each do |bar|
        if bar
          svg << %Q(<rect x="#{x}" y="#{y}" width="#{options[:x_scale]}" height="#{options[:y_scale]}" fill="black" />)
        end
        x += options[:x_scale]
      end
      y += options[:y_scale]
    end

    svg << "</svg>"
    svg.join("\n")
  end

  def to_png(**options)
    barcode.to_png(**options)
  end

  private

    def barcode
      @barcode ||= PDF417.new(data).tap(&:generate)
    end

    def bar
      barcode.instance_variable_get(:@bar)
    end
end
