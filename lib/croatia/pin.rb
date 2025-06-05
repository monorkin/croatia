# frozen_string_literal: true

# Validates and generates Croatian Personal Identification Numbers (OIB/PIN)
#
# OIB (Osobni Identifikacijski Broj) is the Croatian Personal Identification Number,
# an 11-digit number used to uniquely identify Croatian citizens and legal entities.
# This module provides validation and generation functionality using the official
# checksum algorithm specified by the Croatian Tax Administration.
#
# The validation uses a modulo 10 checksum algorithm with the following steps:
# 1. Start with a checksum value of 10
# 2. For each of the first 10 digits:
#    - Add the digit to the checksum and take modulo 10
#    - If result is 0, set to 10, then multiply by 2 and take modulo 11
# 3. The control digit is (11 - final_checksum) % 10
#
# @example Validating PINs
#   Croatia::PIN.valid?("12345678901")  # => true/false
#   Croatia::PIN.valid?(12345678901)    # => true/false
#   Croatia::PIN.valid?("invalid")      # => false
#   Croatia::PIN.valid?(nil)            # => false
#
# @example Generating PINs
#   Croatia::PIN.random          # => "94062734461"
#   Croatia::PIN.random("1337")  # => "13377073537"
#
# @example Calculating checksums
#   Croatia::PIN.checksum_for("9406273446")   # => 1
#
# @see https://www.porezna-uprava.hr/hr_propisi/_layouts/in2.vuk.sp.propisi.intranet/propisi.aspx
# @author Croatia Gem
# @since 0.1.0
module Croatia::PIN
  # Validates a Croatian Personal Identification Number (OIB/PIN)
  #
  # Checks if the provided PIN has the correct format (11 digits) and
  # validates the checksum using the official Croatian algorithm.
  #
  # @param pin [String, Integer, nil] the PIN to validate (must be 11 digits)
  # @return [Boolean] true if the PIN is valid, false otherwise
  #
  # @example Valid PINs
  #   Croatia::PIN.valid?("12345678901")  # => true (if checksum is correct)
  #   Croatia::PIN.valid?(12345678901)    # => true (integers work too)
  #
  # @example Invalid PINs
  #   Croatia::PIN.valid?("invalid")      # => false
  #   Croatia::PIN.valid?("123456789")    # => false (too short)
  #   Croatia::PIN.valid?("123456789012") # => false (too long)
  #   Croatia::PIN.valid?(nil)            # => false
  def self.valid?(pin)
    return false unless pin

    pin = pin.to_s.strip
    return false unless pin.match?(/\A\d{11}\Z/)

    control = pin[-1].to_i
    checksum = checksum_for(pin[0..-2])

    checksum == control
  end

  # Calculates the checksum digit for a partial PIN (first 10 digits)
  #
  # Uses the official Croatian OIB checksum algorithm to calculate
  # the 11th digit that should be appended to make a valid PIN.
  #
  # @param partial_pin [String] the first 10 digits of the PIN
  # @return [Integer] the calculated checksum digit (0-9)
  # @raise [ArgumentError] if partial_pin is not exactly 10 digits
  #
  # @example Calculate checksum for a partial PIN
  #   Croatia::PIN.checksum_for("9406273446")  # => 1
  #   Croatia::PIN.checksum_for("1234567890")  # => 5
  #
  # @example Use with validation
  #   partial = "9406273446"
  #   full_pin = partial + Croatia::PIN.checksum_for(partial).to_s
  #   Croatia::PIN.valid?(full_pin)  # => true
  def self.checksum_for(partial_pin)
    digits = partial_pin.chars.map(&:to_i)

    if digits.length != 10
      raise ArgumentError, "Partial PIN must be exactly 10 digits long"
    end

    checksum = 10
    digits.each do |digit|
      checksum = (checksum + digit) % 10
      checksum = (checksum == 0 ? 10 : checksum) * 2 % 11
    end

    (11 - checksum) % 10
  end

  # Generates a random valid Croatian PIN/OIB
  #
  # Creates a random 11-digit PIN that passes validation. Useful for testing
  # and development purposes. The generated PIN will have a correct checksum
  # but may not correspond to any real person or entity.
  #
  # @param prefix [String, Integer] optional prefix digits to use as prefix.
  #   If provided, these digits will be used at the start of the PIN,
  #   with remaining positions filled randomly.
  # @return [String] a valid 11-digit PIN with correct checksum
  #
  # @example Generate a completely random PIN
  #   Croatia::PIN.random  # => "94062734461"
  #
  # @example Generate a PIN with specific prefix
  #   Croatia::PIN.random("1337")  # => "13377073537"
  #   Croatia::PIN.random(123)     # => "12356789014"
  #
  # @note The generated PINs are for testing purposes only and should not
  #   be used as real identification numbers.
  def self.random(prefix = "")
    prefix = prefix.to_s.strip.chars.map(&:to_i)
    digits = Array.new(10) { |i| prefix[i] || rand(10) }
    digits << checksum_for(digits.join)

    digits.join
  end
end
