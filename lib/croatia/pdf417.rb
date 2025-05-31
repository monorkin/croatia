# frozen_string_literal: true

class Croatia::Invoice::PDF417
  def self.ensure_supported!
    return if supported?

    raise LoadError, "PDF417 library is not loaded. Please ensure you have either the pdf417 or the pdf-417 gem installed."
  end

  def self.supported?
    defined?(PDF417)
  end

  attr_reader :data, :options

  def initialize(data, **options)
    @data = data
    @options = options
  end
end
