# Croatia

Croatia is a gem that contains various utilities for performing Croatia-specific actions:

- [x] PIN _(OIB)_
  - [x] Validation
- [x] UMCN _(JMBG)_
  - [x] Validation
  - [x] Parsing
  - [x] Generation
- [ ] Invoices
- [x] Payment barcodes
  - [x] HUB3 standard 2D barcode generation
- [ ] Fiscalization v2.3 _(Fiskalizacija)_
  - [x] Issuer protection code generation _(ZKI)_
  - [x] QR code generation
  - [x] Reverse _(storno)_
  - [ ] Invoices _(racuni)_
  - [ ] Supporting documents _(prateci dokumenti - otpremnice, radni nalozi, ponude, ugovori, ...)_
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
Croatia::PIN.valid?("12345678903") # => true
Croatia::PIN.valid?("12345678900") # => false
```

### UMCNs / JMBGs

```ruby
# Validation
Croatia::UMCN.valid?("0101990123455") # => true
Croatia::UMCN.valid?("3201990123456") # => false

# Parsing
num = Croatia::UMCN.parse("1407933312355") # => <Croatia::UMCN ...>
num.birthday # => <Date: 1933-07-14>
num.region_of_birth # => "Podravina"
num.sequence_number # => 235
num.sex # => :male
num.checksum # => 5
num.to_s # => "1407933312355"

# Generation
# Full list of region codes is available on Wikipedia:
# https://en.wikipedia.org/wiki/Unique_Master_Citizen_Number
num = Croatia::UMCN.new(
  birthday: Date.new(1988, 3, 14),
  region_code: 33, # Zagreb
  sequence_number: 123
)
num.to_s # => "1403988331237"
```

### Invoices

```ruby
# Values can be set during initialization
invoice = Croatia::Invoice.new(
  sequential_number: 64,
  register_identifier: "123",
  business_location_identifier: "HQ1",
  sequential_by: :business_location,
  payment_method: :card
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
  line_item.add_tax(type: :value_added_tax, category: :standard) # PDV 25%
  # line_item.add_tax(type: :value_added_tax, category: :lower_rate) # PDV 13%
  # line_item.add_tax(type: :value_added_tax, category: :exempt) # PDV 0% - e.g. for invoices to the USA
  # line_item.add_tax(type: :value_added_tax, category: :reverse_charge) # PDV 0% - for invoices to the EU
  # line_item.add_tax(type: :value_added_tax, category: :lower_rate, rate: 0.01) # You can override the default rate

  # Set a custom tax rate
  line_item.add_tax do |tax|
    tax.type = :other
    tax.category = :lower_rate
    tax.rate = 0.05
    tax.name = "Porez na luksuz"
  end

  # Remove a tax
  # line_item.remove_tax(:other)

  # Clear all taxes
  # line_item.clear_taxes
end

invoice.subtotal # => BigDecimal("200.00")
invoice.tax # => BigDecimal("62.50")
invoice.total # => BigDecimal("262.50")
invoice.total_cents # => 26250

invoice.number # => "64/HQ1/123"

```

### Payment barcodes

```ruby
# IMPORTANT: To be able to generate payment barcodes you have to add
# the "ruby-zint" gem to you Gemfile, or have it installed and required!
require "ruby-zint"

# Generate a 2D barcode which can be scanned by Croatian banking apps
# and initiate a payment
barcode = invoice.payment_barcode # => <Croatia::PaymentBarcode ...>

# You can also set the description, model and reference number
barcode = invoice.payment_barcode(
  description: "Dog walking",
  model: "HR00",
  reference_number: "202506030001"
) # => <Croatia::PaymentBarcode ...>

# Or you can create a payment barcode without an invoice
barcode = Croatia::PaymentBarcode.new(
  description: "Dog walking",

  total_cents: 15_00,
  currency: "EUR",
  model: "HR00",
  reference_number: "202506030001",
  payment_purpose_code: "OTHR",

  buyer_name: "Hrvoje Horvat",
  buyer_address: "Ilica 141",
  buyer_postal_code: 10000,
  buyer_city: "Zagreb",

  seller_name: "Example Company Ltd.",
  seller_address: "Example Street 1",
  seller_postal_code: 2100,
  seller_city: "Split",
) # => <Croatia::PaymentBarcode ...>

barcode.to_svg # => "<svg>...</svg>"
barcode.to_png # => "\b..."
```

### Fiscalization

```ruby
# Issuer protection code (ZKI) is generated automatically
invoice.issuer_protection_code # => "abcd1234efgh5678ijkl9012mnop3456"

# Fiscalize an invoice using the certificate from the config
invoice.fiscalize!
# Fiscalize an invoice using a custom certificate and password
invoice.fiscalize!(certificate: "path/to/your/certificate.p12", password: "your_password")

# In case you want to "undo" a fiscalized invoice, you can reverse the invoice
invoice.reverse!

# IMPORTANT: For QR code generation you need to have the "rqrcode" gem in yuor Gemfile
# or installed and required!
require "rqrcode"

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

To lint the code, run `bin/lint`. The linter can also automatically fix some issues, you can run `bin/lint -A` to do so.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Official documentation

Some features of this gem are based on official documentation, which can be found here

**UMCN (JMBG):**
- [Wikipedia - Unique Master Citizen Number](https://en.wikipedia.org/wiki/Unique_Master_Citizen_Number)

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
