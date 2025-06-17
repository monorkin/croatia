# frozen_string_literal: true

module Croatia::Fiscalizer::Parser
  NAMESPACES = {
    "soap" => "http://schemas.xmlsoap.org/soap/envelope/"
  }.freeze

  class << self
    def parse_echo_response(body)
      document = Nokogiri::XML(body)
      response = document.at_xpath("//soap:Envelope/soap:Body/echoResponse", NAMESPACES)
      result = Croatia::Fiscalizer::Result.new(data: response&.text)

      if fault = document.at_xpath("//soap:Fault/detail", NAMESPACES)
        code = fault.at_xpath("errorCode")&.text
        message = fault.at_xpath("errorMessage")&.text
        result.add_error(code: code, message: message)
      end

      result
    end
  end
end
