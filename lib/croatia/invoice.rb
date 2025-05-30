# frozen_string_literal: true

class Croatia::Invoice
  autoload :LineItem, "croatia/invoice/line_item"
  autoload :Fiscalizer, "croatia/invoice/fiscalizer"

  attr_accessor :line_items

  def add_line_item(line_item = nil, &block)
    raise ArgumentError, "You must provide a line item or a block" if line_item.nil? && block.nil?

    line_item ||= LineItem.new.tap(&block)

    self.line_items ||= []
    line_items << line_item
    line_item
  end

  def fiscalize!(**options)
    Fiscalizer.new(**options, invoice: self).fiscalize
  end
end
