# frozen_string_literal: true

class Croatia::Invoice
  autoload :LineItem, "croatia/invoice/line_item"
  autoload :Fiscalizer, "croatia/invoice/fiscalizer"

  attr_accessor :line_items

  def initialize(**options)
    self.line_items = options.fetch(:line_items) { [] }
  end

  def add_line_item(line_item = nil, &block)
    if line_item.nil? && block.nil?
      raise ArgumentError, "You must provide a line item or a block"
    end

    line_item ||= LineItem.new.tap(&block)

    self.line_items ||= []
    line_items << line_item

    line_item
  end

  def fiscalize!(**options)
    Fiscalizer.new(**options, invoice: self).fiscalize
  end

  def reverse!(**options)
    Fiscalizer.new(**options, invoice: self).reverse
  end
end
