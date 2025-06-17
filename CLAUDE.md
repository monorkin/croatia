# Croatia Gem - Claude Context

This document provides comprehensive context about the Croatia gem for future Claude sessions.

**Note:** This file should be updated by Claude whenever noteworthy changes or learnings occur during development sessions.

## Project Overview

The Croatia gem provides utilities for performing Croatia-specific actions, primarily focused on Croatian fiscalization (tax reporting) requirements. It includes PIN validation, UMCN (JMBG) handling, invoice generation, payment barcodes, and XML digital signing for tax authorities.

## Project Structure

```
croatia/
├── lib/croatia/
│   ├── config.rb                    # Configuration management
│   ├── enum.rb                      # Enum utility module
│   ├── fiscalizer.rb               # Main fiscalization class
│   ├── fiscalizer/
│   │   └── xml_builder.rb          # XML generation and signing
│   ├── invoice.rb                  # Invoice management
│   ├── invoice/
│   │   ├── fiscalizable.rb         # Fiscalization concern
│   │   ├── identifiable.rb         # ID generation concern
│   │   ├── line_item.rb            # Invoice line items
│   │   ├── party.rb                # Buyer/seller/issuer entities
│   │   ├── payable.rb              # Payment methods concern
│   │   ├── surcharge.rb            # Surcharges (naknade)
│   │   └── tax.rb                  # Tax handling
│   ├── payment_barcode.rb          # HUB3 2D barcodes
│   ├── pin.rb                      # OIB validation
│   ├── qr_code.rb                  # QR code generation
│   ├── umcn.rb                     # JMBG validation/generation
│   └── version.rb                  # Gem version
├── test/
│   ├── croatia/
│   │   ├── fiscalizer/
│   │   │   └── xml_builder_test.rb # XML builder tests
│   │   └── invoice/
│   │       ├── line_item_test.rb   # Line item tests
│   │       └── surcharge_test.rb   # Surcharge tests
│   ├── fixtures/files/
│   │   ├── fake_fiskal1.p12        # Test certificate
│   │   └── fake_fiskal1_password.txt # Certificate password
│   └── helpers/
│       ├── fiscalization_credentials_helper.rb   # Credential test utilities
│       └── xml_helper.rb           # XML comparison utilities
├── README.md                       # User documentation
└── CLAUDE.md                       # This file
```

## Key Components

### 1. Croatia::Invoice
Central invoice management class with the following features:

**Core Properties:**
- `sequential_number` - Invoice sequence number
- `business_location_identifier` - Business location ID (oznaka poslovnog prostora)
- `register_identifier` - Register device ID (oznaka naplatnog uredaja)
- `issue_date` / `due_date` - Invoice dates
- `payment_method` - `:cash`, `:card`, `:check`, `:transfer`, `:other`
- `sequential_by` - `:register` or `:business_location`

**Entities:**
- `issuer` - Invoice issuer (Croatia::Invoice::Party)
- `seller` - Seller entity (Croatia::Invoice::Party)  
- `buyer` - Buyer entity (Croatia::Invoice::Party)

**Line Items:**
- `line_items` - Array of Croatia::Invoice::LineItem objects
- `add_line_item` - Method to add items with block syntax

**Calculations:**
- `subtotal` - Sum of line item subtotals
- `tax` - Sum of all taxes
- `surcharge` - Sum of all surcharges
- `margin` - Sum of all margins
- `total` - Final invoice total

### 2. Croatia::Invoice::LineItem
Individual invoice line items with:

**Basic Properties:**
- `description`, `quantity`, `unit`, `unit_price`
- `discount` (fixed amount) or `discount_rate` (percentage)

**Tax System:**
- `add_tax(type:, category:, rate: nil)` - Add tax with type (:value_added_tax, :consumption_tax, :other)
- `remove_tax(type)`, `clear_taxes`
- `tax_breakdown` - Detailed tax calculation

**Surcharges (Naknade):**
- `add_surcharge(name:, amount:)` or block syntax
- `remove_surcharge(name)`, `clear_surcharges`
- Aggregated by name across line items

**Margins:**
- `margin` - Affects tax calculation via `taxable_base` method
- When margin is set: tax calculated on margin instead of subtotal

### 3. Croatia::Invoice::Surcharge
Represents surcharges (naknade) with:
- `name` - Max 100 characters, required
- `amount` - BigDecimal, required
- Validation for nil values

### 4. Croatia::Fiscalizer
Main fiscalization interface:

**Certificate Management:**
- `initialize(credential:, password:)` - Loads PKCS12 credentials
- `load_credential` - Handles .p12 files and private keys
- Returns private key for signing operations

**Core Methods:**
- `fiscalize(invoice:, message_id:)` - Generate fiscalization XML
- `generate_issuer_protection_code(invoice)` - ZKI generation (MD5 of SHA1 signature)
- `generate_verification_qr_code(invoice)` - QR codes for verification

### 5. Croatia::Fiscalizer::XMLBuilder
XML generation and digital signing:

**Document Generation:**
- `invoice(invoice:, message_id:, **options)` - Standard invoice XML
- `supporting_document(invoice:, message_id:, unique_identifier: nil, issuer_protection_code: nil, **options)` - Supporting documents
- `verify(invoice:, message_id:, **options)` - Verification requests
- `invoice_payment_method_change(new_payment_method, **options)` - Payment method changes
- `supporting_document_payment_method_change(new_payment_method, **options)` - Supporting doc payment changes

**XML Envelopes:**
- `INVOICE_ENVELOPE = "RacunZahtjev"`
- `SUPPORTING_DOCUMENT_ENVELOPE = "RacunPDZahtjev"`
- `PAYMENT_METHOD_CAHNGE_ENVELOPE = "PromijeniNacPlacZahtjev"`
- `VERIFY_ENVELOPE = "ProvjeraZahtjev"`

**Digital Signing:**
- `sign(document:, credential:)` - XML digital signatures
- Expects PKCS12 objects (credential.key for signing, credential.certificate for cert info)
- Uses SHA1 with RSA, C14N canonicalization, enveloped signatures
- Embeds X.509 credentials with issuer and serial number

**XML Structure:**
- All documents have `Id` attribute on root element (set to message_id)
- Uses TNS namespace: "http://www.apis-it.hr/fin/2012/types/f73"
- Includes header (Zaglavlje) with message ID and timestamp
- Main content in Racun element

## Configuration

```ruby
Croatia.configure do |config|
  config.tax_rates = {
    value_added_tax: {
      standard: 0.25,      # 25% PDV
      lower_rate: 0.13,    # 13% PDV  
      exempt: 0.0,         # 0% PDV
      zero_rated: 0.0,
      outside_scope: 0.0,
      reverse_charge: 0.0
    },
    consumption_tax: Hash.new(0.0),
    other: Hash.new(0.0)
  }
  
  config.fiscalization = {
    credential: "path/to/cert.p12",
    password: "cert_password"
  }
end
```

## Testing

**Test Framework:** Minitest
**Documentation:** YARD format
**Test Commands:**
- `bin/test` - Run all tests
- `bin/lint` - Run linter
- `bin/lint -A` - Auto-fix linting issues

**Key Test Helpers:**
- `FixturesHelper` - File fixture loading
- `XMLHelper` - XML comparison with `assert_xml_equal`
- `FiscalizationCredentialsHelper` - Credential test utilities

**Test Certificates:**
- `test/fixtures/files/fake_fiskal1.p12` - Test PKCS12 credential
- `test/fixtures/files/fake_fiskal1_password.txt` - Certificate password

**Test Patterns:**
- Use `Timecop.freeze(REFERENCE_TIME)` for consistent timestamps
- Use `assert_xml_equal expected_xml, actual_xml` for XML comparisons
- Test both validation and integration scenarios
- Use proper UUID format for message IDs (36 characters)

## Key Implementation Details

### Tax Calculation
- Base calculation: `quantity * unit_price - discount`
- With margin: tax calculated on `margin` instead of `subtotal`
- `taxable_base` method returns `margin || subtotal`

### Certificate Handling
- Fiscalizer expects PKCS12 objects for signing
- XMLBuilder.sign method uses `credential.key` and `credential.certificate`
- Protection code generation uses private key directly

### XML Digital Signatures
- XMLDSIG enveloped signatures
- SHA1 digest algorithm
- RSA-SHA1 signature method
- Exclusive C14N canonicalization
- Embeds full X.509 credential chain

### BigDecimal Usage
- All financial calculations use BigDecimal for precision
- `.to_d` conversion for user inputs
- `format_decimal` helper formats to 2 decimal places

## Recent Development History

1. **Surcharges Implementation** - Added surcharge support with aggregation and validation
2. **Margins Implementation** - Added margin support affecting tax calculation base
3. **XML Builder Enhancements** - Added support for supporting documents, payment method changes, verification
4. **Digital Signing** - Implemented XMLDSIG signatures with PKCS12 credential support
5. **Test Coverage** - Comprehensive test suite with XML comparison and validation testing

## Common Issues and Solutions

1. **Certificate vs Private Key Confusion**
   - XMLBuilder.sign expects PKCS12 objects
   - Use `credential.key` for signing, `credential.certificate` for cert info

2. **BigDecimal Precision**
   - Always use `.to_d` for financial inputs
   - Use `format_decimal` for XML output

3. **XML Testing**
   - Use `assert_xml_equal` for XML comparisons
   - Include `Id` attributes in expected XML (set to message_id)

4. **Tax Calculation Edge Cases**
   - Handle nil margins: `line_items.sum { |item| item.margin || 0 }`
   - Use `taxable_base` method for tax calculation base

## Dependencies

- `rexml` - XML document manipulation
- `nokogiri` - XML canonicalization for signatures
- `openssl` - Cryptographic operations
- `base64` - Encoding for signatures and credentials
- `bigdecimal` - Precise financial calculations
- `timecop` (test) - Time manipulation for testing
- `minitest` (test) - Testing framework