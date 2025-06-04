# frozen_string_literal: true

# Validates Croatian Personal Identification Numbers (OIB/PIN)
#
# OIB (Osobni Identifikacijski Broj) is the Croatian Personal Identification Number,
# an 11-digit number used to uniquely identify Croatian citizens and legal entities.
# This module provides validation functionality using the official checksum algorithm.
#
# The validation uses a modulo 10 checksum algorithm where:
# - The first 10 digits are multiplied by specific weights
# - A control digit is calculated and compared with the 11th digit
#
# @example Validating a PIN
#   Croatia::PIN.valid?("12345678901")  # => true/false
#   Croatia::PIN.valid?(12345678901)    # => true/false
#
# @author Croatia Gem
# @since 0.1.0
module Croatia::PIN
  # Validates a Croatian Personal Identification Number (OIB/PIN)
  #
  # @param pin [String, Integer] the PIN to validate (11 digits)
  # @return [Boolean] true if the PIN is valid, false otherwise
  #
  # @example
  #   Croatia::PIN.valid?("12345678901")  # => true/false
  #   Croatia::PIN.valid?(12345678901)    # => true/false
  #   Croatia::PIN.valid?("invalid")      # => false
  #   Croatia::PIN.valid?(nil)            # => false
  def self.valid?(pin)
    return false unless pin

    pin = pin.to_s.strip
    return false unless pin.match?(/\A\d{11}\Z/)

    digits = pin.chars.map(&:to_i)
    control = digits.pop

    checksum = 10
    digits.each do |digit|
      checksum = (checksum + digit) % 10
      checksum = (checksum == 0 ? 10 : checksum) * 2 % 11
    end

    expected_control = (11 - checksum) % 10
    control == expected_control
  end
end
