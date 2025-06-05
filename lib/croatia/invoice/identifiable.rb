# frozen_string_literal: true

# Provides validation and management for Croatian invoice identifiers
#
# This concern adds validation and setter methods for the three primary
# identifiers required for Croatian fiscal invoices according to the
# Croatian Tax Administration regulations:
#
# - **Business Location Identifier** (oznaka poslovnog prostora): 1-20 alphanumeric characters
# - **Register Identifier** (oznaka naplatnog uređaja): 1-20 digits without leading zeros
# - **Sequential Number** (redni broj računa): 1-20 digits without leading zeros
#
# These identifiers are combined to form the complete invoice number in the
# format: `sequential_number/business_location_identifier/register_identifier`
#
# @example Basic usage
#   class MyInvoice
#     include Croatia::Invoice::Identifiable
#   end
#
#   invoice = MyInvoice.new
#   invoice.business_location_identifier = "OFFICE01"
#   invoice.register_identifier = "1"
#   invoice.sequential_number = "123"
#   invoice.number  # => "123/OFFICE01/1"
#
# @example Validation examples
#   # Valid values
#   invoice.business_location_identifier = "LOC123"     # ✓ Alphanumeric, 1-20 chars
#   invoice.register_identifier = "5"                   # ✓ Digits, no leading zeros
#   invoice.sequential_number = "999"                   # ✓ Digits, no leading zeros
#
#   # Invalid values
#   invoice.business_location_identifier = nil          # ✗ Cannot be nil
#   invoice.business_location_identifier = "LOC-123"    # ✗ Special characters not allowed
#   invoice.register_identifier = "01"                  # ✗ Leading zeros not allowed
#   invoice.sequential_number = "0123"                  # ✗ Leading zeros not allowed
#
# @author Croatia Gem
# @since 0.3.0
module Croatia::Invoice::Identifiable
  def self.included(base)
    base.extend ClassMethods
    base.include InstanceMethods
  end

  # Validates that a value is a valid integer identifier
  #
  # Checks that the value is numeric, has no leading zeros (except for single "0"),
  # and doesn't exceed the maximum length.
  #
  # @param value [String, Integer, nil] the value to validate
  # @param max_length [Integer] maximum allowed length in digits
  # @return [Boolean] true if valid, false otherwise
  #
  # @example Valid identifiers
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("1", max_length: 20)      # => true
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("123", max_length: 20)    # => true
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("999", max_length: 3)     # => true
  #
  # @example Invalid identifiers
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?(nil, max_length: 20)      # => false
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("01", max_length: 20)     # => false
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("abc", max_length: 20)    # => false
  #   Croatia::Invoice::Identifiable.valid_integer_identifier?("12345", max_length: 3)   # => false
  def self.valid_integer_identifier?(value, max_length:)
    return false if value.nil?
    value = value.to_s
    !value.start_with?("0") && value.match?(/\A\d+\z/) && value.length.between?(1, max_length)
  end

  module ClassMethods
    # Regular expression for validating business location identifiers
    # Allows alphanumeric characters (a-z, A-Z, 0-9) with length 1-20
    BUSINESS_LOCATION_IDENTIFIER_REGEX = /\A[a-zA-Z0-9]{1,20}\z/.freeze

    # Validates a business location identifier
    #
    # Business location identifiers must be 1-20 alphanumeric characters.
    # No special characters, spaces, or empty values are allowed.
    #
    # @param value [String, nil] the value to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example Valid business location identifiers
    #   valid_business_location_identifier?("OFFICE")      # => true
    #   valid_business_location_identifier?("LOC123")      # => true
    #   valid_business_location_identifier?("A1B2C3")      # => true
    #
    # @example Invalid business location identifiers
    #   valid_business_location_identifier?(nil)           # => false
    #   valid_business_location_identifier?("")            # => false
    #   valid_business_location_identifier?("LOC-123")     # => false
    #   valid_business_location_identifier?("A" * 21)      # => false
    def valid_business_location_identifier?(value)
      value&.match?(BUSINESS_LOCATION_IDENTIFIER_REGEX)
    end

    # Validates a sequential number
    #
    # Sequential numbers must be 1-20 digits without leading zeros.
    # This represents the sequential invoice number within the
    # register or business unit.
    #
    # @param value [String, Integer, nil] the value to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example Valid sequential numbers
    #   valid_sequential_number?("1")          # => true
    #   valid_sequential_number?("123")        # => true
    #   valid_sequential_number?(999)          # => true
    #
    # @example Invalid sequential numbers
    #   valid_sequential_number?(nil)          # => false
    #   valid_sequential_number?("01")         # => false
    #   valid_sequential_number?("0123")       # => false
    #   valid_sequential_number?("abc")        # => false
    def valid_sequential_number?(value)
      Croatia::Invoice::Identifiable.valid_integer_identifier?(value, max_length: 20)
    end

    # Validates a register identifier
    #
    # Register identifiers must be 1-20 digits without leading zeros.
    # This represents the cash register or payment device identifier.
    #
    # @param value [String, Integer, nil] the value to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example Valid register identifiers
    #   valid_register_identifier?("1")        # => true
    #   valid_register_identifier?("5")        # => true
    #   valid_register_identifier?(123)        # => true
    #
    # @example Invalid register identifiers
    #   valid_register_identifier?(nil)        # => false
    #   valid_register_identifier?("01")       # => false
    #   valid_register_identifier?("REG1")     # => false
    def valid_register_identifier?(value)
      Croatia::Invoice::Identifiable.valid_integer_identifier?(value, max_length: 20)
    end
  end

  module InstanceMethods
    # Sets the business location identifier with validation
    #
    # The business location identifier (oznaka poslovnog prostora) identifies
    # the physical or logical location where the invoice is issued.
    #
    # @param value [String, Integer] the business location identifier (1-20 alphanumeric chars)
    # @raise [ArgumentError] if value is nil or invalid format
    # @return [String] the validated and stored identifier
    #
    # @example Valid assignments
    #   invoice.business_location_identifier = "OFFICE"    # => "OFFICE"
    #   invoice.business_location_identifier = "LOC123"    # => "LOC123"
    #   invoice.business_location_identifier = 123         # => "123"
    #
    # @example Invalid assignments (will raise ArgumentError)
    #   invoice.business_location_identifier = nil
    #   invoice.business_location_identifier = ""
    #   invoice.business_location_identifier = "LOC-123"
    #   invoice.business_location_identifier = "A" * 21
    def business_location_identifier=(value)
      if value.nil?
        raise ArgumentError, "Business location identifier cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_business_location_identifier?(value)
        raise ArgumentError, "Business location identifier must be a non-empty string with a maximum length of 20 characters (only letters and digits are allowed)"
      end

      @business_location_identifier = value
    end

    # Sets the register identifier with validation
    #
    # The register identifier (oznaka naplatnog uređaja) identifies the specific
    # cash register or payment device used to issue the invoice.
    #
    # @param value [String, Integer] the register identifier (1-20 digits, no leading zeros)
    # @raise [ArgumentError] if value is nil, has leading zeros, or invalid format
    # @return [String] the validated and stored identifier
    #
    # @example Valid assignments
    #   invoice.register_identifier = "1"       # => "1"
    #   invoice.register_identifier = "123"     # => "123"
    #   invoice.register_identifier = 5         # => "5"
    #
    # @example Invalid assignments (will raise ArgumentError)
    #   invoice.register_identifier = nil
    #   invoice.register_identifier = "01"      # Leading zero
    #   invoice.register_identifier = "REG1"    # Non-numeric
    #   invoice.register_identifier = "0"       # Leading zero (special case)
    def register_identifier=(value)
      if value.nil?
        raise ArgumentError, "Register identifier cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_register_identifier?(value)
        raise ArgumentError, "Register identifier must be a number no longer than 20 digits and without leading zeros"
      end

      @register_identifier = value
    end

    # Sets the sequential number with validation
    #
    # The sequential number (redni broj računa) is the sequential invoice number
    # within the register or business unit, incremented for each new invoice.
    #
    # @param value [String, Integer] the sequential number (1-20 digits, no leading zeros)
    # @raise [ArgumentError] if value is nil, has leading zeros, or invalid format
    # @return [String] the validated and stored sequential number
    #
    # @example Valid assignments
    #   invoice.sequential_number = "1"         # => "1"
    #   invoice.sequential_number = "999"       # => "999"
    #   invoice.sequential_number = 123         # => "123"
    #
    # @example Invalid assignments (will raise ArgumentError)
    #   invoice.sequential_number = nil
    #   invoice.sequential_number = "01"        # Leading zero
    #   invoice.sequential_number = "0123"      # Leading zeros
    #   invoice.sequential_number = "abc"       # Non-numeric
    def sequential_number=(value)
      if value.nil?
        raise ArgumentError, "Sequential number cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_sequential_number?(value)
        raise ArgumentError, "Sequential number must be a number no longer than 20 digits and without leading zeros"
      end

      @sequential_number = value
    end

    # Generates the complete invoice number
    #
    # Combines all three identifiers into the standard Croatian invoice number format.
    # The format follows the pattern: `sequential_number/business_location_identifier/register_identifier`
    #
    # @return [String] the complete invoice number
    # @raise [NoMethodError] if any of the required identifiers are not set
    #
    # @example
    #   invoice.sequential_number = "123"
    #   invoice.business_location_identifier = "OFFICE"
    #   invoice.register_identifier = "1"
    #   invoice.number  # => "123/OFFICE/1"
    def number
      [ sequential_number, business_location_identifier, register_identifier ].join("/")
    end
  end
end
