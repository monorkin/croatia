# frozen_string_literal: true

# OIB - Osobni Identifikacijski Broj
# PIN - Personal Identification Number
module Croatia::PIN
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
