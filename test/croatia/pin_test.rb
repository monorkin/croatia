# frozen_string_literal: true

require "test_helper"

class PinTest < Minitest::Test
  def test_valid_oibs
    valid_oibs = [
      "12345678903",
      "71481280786",
      "64217529143"
    ]

    valid_oibs.each do |oib|
      assert Croatia::PIN.valid?(oib), "Expected OIB #{oib} to be valid"
    end
  end

  def test_invalid_oibs
    invalid_oibs = [
      "12345678901", # Invalid control digit
      "1234567890",  # Too short
      "123456789012", # Too long
      "abcdefghijk", # Non-numeric
      "",            # Empty string
      nil            # Nil value
    ]

    invalid_oibs.each do |oib|
      refute Croatia::PIN.valid?(oib), "Expected OIB #{oib.inspect} to be invalid"
    end
  end
end
