# frozen_string_literal: true

class Croatia::Fiscalizer::Result
  Error = Data.define(:code, :message, :description, :details)

  attr_reader :message_id, :timestamp, :data, :errors

  def initialize(message_id: nil, timestamp: nil, data: nil, errors: nil)
    @message_id = message_id
    @timestamp = timestamp
    @data = data
    @errors = errors || []
  end

  def success?
    errors.empty?
  end

  alias_method :ok?, :success?

  def failure?
    !success?
  end

  alias_method :error?, :failure?

  def add_error(code:, message:, descriptions: nil)
    description = descriptions[code] if descriptions
    errors << Error.new(code: code, message: message, description: description)
  end
end
