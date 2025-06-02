# frozen_string_literal: true

require_relative "croatia/version"

module Croatia
  class Error < StandardError; end

  autoload :Config, "croatia/config"
  autoload :Enum, "croatia/utils/enum"
  autoload :QRCode, "croatia/qr_code"
  autoload :PDF417, "croatia/pdf417"
  autoload :PIN, "croatia/pin"
  autoload :Invoice, "croatia/invoice"

  class << self
    def config
      @config ||= Croatia::Config.new
    end

    def configure(config = nil, &block)
      if config.is_a?(Croatia::Config)
        @config = config
      elsif block
        self.config.tap(&block)
      else
        raise ArgumentError, "Either a Croatia::Config instance or a block is required"
      end
    end
  end
end
