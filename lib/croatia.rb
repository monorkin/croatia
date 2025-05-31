# frozen_string_literal: true

require_relative "croatia/version"

module Croatia
  class Error < StandardError; end

  autoload :Enum, "croatia/utils/enum"
  autoload :PIN, "croatia/pin"
  autoload :Invoice, "croatia/invoice"
end
