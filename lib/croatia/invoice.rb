# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class Croatia::Invoice
  autoload :Fiscalizable, "croatia/invoice/fiscalizable"
  autoload :EInvoicable, "croatia/invoice/e_invoicable"
  autoload :Payable, "croatia/invoice/payable"
  autoload :Party, "croatia/invoice/party"
  autoload :LineItem, "croatia/invoice/line_item"
  autoload :Fiscalizer, "croatia/invoice/fiscalizer"
  autoload :QRCode, "croatia/invoice/qr_code"
  autoload :PDF417, "croatia/invoice/pdf417"

  include Croatia::Enum
  include Fiscalizable
  include EInvoicable
  include Payable

  attr_reader :issue_date, :due_date
  attr_accessor \
    :business_location_identifier, # oznaka poslovnog prostora
    :currency,
    :issuer_protection_code, # zki
    :line_items,
    :register_identifier, # oznaka naplatnog uredaja
    :sequential_number, # redni broj racuna
    :unique_invoice_identifier # jir

  enum :payment_method, {
    cash: "G",
    card: "K",
    check: "C",
    transfer: "T",
    other: "O"
  }.freeze, allow_nil: true, prefix: :payment_method

  def initialize(**options)
    self.line_items = options.delete(:line_items) { [] }

    options.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def number
    [ sequential_number, business_location_identifier, register_identifier ].join("/")
  end

  def subtotal
    line_items.sum(&:subtotal).to_d
  end

  def tax
    line_items.sum(&:tax).to_d
  end

  def total
    line_items.sum(&:total).to_d
  end

  def total_cents
    (total * 100).to_i
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

  def buyer(&block)
    if block_given?
      self.buyer = Party.new.tap(&block)
    else
      @buyer
    end
  end

  def buyer=(value)
    unless value.is_a?(Party)
      raise ArgumentError, "Buyer must be an instance of Party"
    end

    @buyer = value
  end

  def seller(&block)
    if block_given?
      self.seller = Party.new.tap(&block)
    else
      @seller
    end
  end

  def seller=(value)
    unless value.is_a?(Party)
      raise ArgumentError, "Seller must be an instance of Party"
    end

    @seller = value
  end

  def issue_date=(value)
    @issue_date = value.nil? ? nil : parse_date(value)
  end

  def due_date=(value)
    @due_date = value.nil? ? nil : parse_date(value)
  end

  private

    def parse_date(value)
      case value
      when Date, DateTime
        value
      else
        DateTime.parse(value.to_s)
      end
    end
end
