# frozen_string_literal: true

class Croatia::Invoice::Fiscalizer
  attr_reader :invoice, :options

  def initialize(invoice:, **options)
    @invoice = invoice
    @options = options
  end

  def fiscalize
    # TODO: Implement the fiscalization logic here
    puts "TODO: Fiscalize invoice #{invoice} with options: #{options}"
  end
end
