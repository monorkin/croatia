# Croatia

Croatia is a gem that contains various utilities for performing Croatia-specific actions:
- [x] PIN _(OIB)_
  - [x] Validation
- [ ] Invoices
  - [x] 2D payment barcode generation
  - [ ] Fiscalization
    - [x] Issuer protection code generation _(ZKI)_
    - [x] QR code generation
    - [x] Reverse _(storno)_
    - [ ] Invoice registration
    - [ ] Payment method change
  - [ ] E-Invoice _(e-Racun)_

## Installation

You can install the gem into your app using the `bundle` command

```bash
bundle add croatia
```

or you can add it manually to your Gemfile

```bash
gem "croatia"
```

## Usage

This gem doesn't load anything by default, so you need to require the specific module you want to use.

### Configuration

```ruby
Croatia.configure do |config|
  # Default tax rates
  config.tax_rates = {
    value_added_tax: {
      standard: 0.25,
      lower_rate: 0.13,
      exempt: 0.0,
      zero_rated: 0.0,
      outside_scope: 0.0,
      reverse_charge: 0.0
    },
    consumption_tax: Hash.new(0.0),
    other: Hash.new(0.0)
  }

  # Fiscalization defaults
  config.fiscalization = {
    certificate: "path/to/your/certificate.p12", # or File.read("path/to/your/certificate.p12")
    password: ENV["FISCALIZATION_CERTIFICATE_PASSWORD"]
  }
  # You can also use a plain private key (.key) file instead of a full certificate (.p12)
  # if you don't have a .p12 or don't want to store/manage a password.
  # config.fiscalization = {
  #   certificate: "path/to/your/private_key.key", # or ENV["FISCALIZATION_PRIVATE_KEY"],
  # }
end
```

### PINs / OIBs

```ruby
require "croatia/pin"

Croatia::PIN.valid?("12345678903") # => true
Croatia::PIN.valid?("12345678900") # => false
```

### Invoices

```ruby
# Values can be set during initialization
invoice = Croatia::Invoice.new(
  sequential_number: 64,
  register_identifier: "001",
  business_location_identifier: "HQ1"
)

# Or via accessors
invoice.issue_date = Time.now
invoice.due_date = invoice.issue_date + 15 * 24 * 60 * 60 # 15 days later

# Some values accept builders so you don't have to deal with initializing objects
invoice.issuer do |issuer|
  issuer.pin = "12345678903"
end
# If you don't want to use the builder you can also 
# do `invoice.issuer = Croatia::Invoice::Party.new(pin: "12345678903")`
# or set it during initialization

invoice.issuer # => <Croatia::Invoice::Party ...>

invoice.seller do |seller|
  seller.pin = "12345678903"
  seller.name = "Example Company Ltd."
  seller.address = "Example Street 1, Zagreb, Croatia"
  seller.pays_vat = true
end

invoice.buyer do |buyer|
  buyer.pin = "12345678903"
  buyer.name = "Example Client Ltd."
  buyer.address = "Client Street 2, Split, Croatia"
end

invoice.add_line_item do |line_item|
  line_item.description = "Product 1"
  line_item.quantity = 2
  line_item.unit_price = 100.0

  # Looks up the tax rate from the config
  line_item.add_tax(type: :value_added_tax, category: :standard)

  # Set a custom tax rate
  line_item.add_tax do |tax|
    tax.type = :other
    tax.category = :lower_rate
    tax.rate = 0.05
  end
end

invoice.subtotal # => BigDecimal("200.00")
invoice.tax # => BigDecimal("62.50")
invoice.total # => BigDecimal("262.50")
invoice.total_cents # => 26250

invoice.number # => "64/HQ1/001"

```

#### Payments

```ruby
# Generate a 2D barcode which can be scanned by Croatian banking apps
# and initiate a payment
barcode = invoice.payment_barcode # => <Croatia::PDF417 ...>

# You can also set the description, model and reference number
barcode = invoice.payment_barcode(
  description: "Dog walking",
  model: "HR00",
  reference_number: "202506030001"
) # => <Croatia::PDF417 ...>

barcode.to_svg # => "<svg>...</svg>"
barcode.to_png # => "\b..."
```

#### Fiscalization

```ruby
# Issuer protection code (ZKI) is generated automatically
invoice.issuer_protection_code # => "abcd1234efgh5678ijkl9012mnop3456"

# Fiscalize an invoice using the sertificate from the config
invoice.fiscalize!
# Fiscalize an invoice using a custom certificate and password
invoice.fiscalize!(certificate: "path/to/your/certificate.p12", password: "your_password")

# In case you want to "undo" a fiscalized invoice, you can reverse the invoice
invoice.reverse!

# Generate a QR code to check the fiscalization status of the invoice
qr_code = invoice.fiscalization_qr_code # => <Croatia::QRCode ...>
qr_code.to_svg # => "<svg>...</svg>"
barcode.to_png # => "\b..."
```

## Development

Make sure you have at least Ruby 3.1 installed. You can check your Ruby version by running `ruby -v`.

After checking out the repo, run `bin/setup` to install dependencies. 

You can start an interactive shell with the gem loaded into it using `bin/console`.

To run the test suite use `bin/test`.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Official documentation

Some features of this gem are based on official documentation, which can be found here

**Banking/payments:**
- [HUB3 standard documentation (payment barcode generation)](https://www.hub.hr/sites/default/files/inline-files/2dbc_0.pdf)

**Fiscalization:**
- [Fiscalization - Technical specification v2.3](https://porezna-uprava.gov.hr/UserDocsImages/arhiva/HR_Fiskalizacija/Documents/Fiskalizacija%20-%20Tehnicka%20specifikacija%20za%20korisnike_v2.3.pdf)

**E-Invoice:**
- [FINA's E-Invoice documentation](https://www.fina.hr/digitalizacija-poslovanja/e-racun/tehnicka-specifikacija/technical-specifications-invoicing-for-web-services)
- [BIS 3.0 technical specification](https://docs.peppol.eu/poacc/billing/3.0/)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/monorkin/croatia.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
