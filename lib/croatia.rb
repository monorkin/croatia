# frozen_string_literal: true

require_relative "croatia/version"

module Croatia
  class Error < StandardError; end

  autoload :Enum, "croatia/utils/enum"
  autoload :QRCode, "croatia/qr_code"
  autoload :PDF417, "croatia/pdf417"
  autoload :PIN, "croatia/pin"
  autoload :Invoice, "croatia/invoice"
end
