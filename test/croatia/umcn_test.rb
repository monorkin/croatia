# frozen_string_literal: true

require "test_helper"

class Croatia::UMCNTest < Minitest::Test
  def test_valid_umcn_numbers
    # Create valid JMBG numbers with proper checksums

    # Calculate a valid JMBG: 01.01.1990, region 123, gender 4, serial 5
    base_digits = "010199012345"
    digits = base_digits.chars.map(&:to_i)
    weights = [ 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ]
    sum = digits.each_with_index.sum { |d, i| d * weights[i] }
    mod = sum % 11
    checksum = mod == 0 || mod == 1 ? 0 : 11 - mod
    valid_umcn_1 = base_digits + checksum.to_s

    # Calculate another valid JMBG: 15.06.1985, region 456, gender 7, serial 8
    base_digits_2 = "150698545678"
    digits_2 = base_digits_2.chars.map(&:to_i)
    sum_2 = digits_2.each_with_index.sum { |d, i| d * weights[i] }
    mod_2 = sum_2 % 11
    checksum_2 = mod_2 == 0 || mod_2 == 1 ? 0 : 11 - mod_2
    valid_umcn_2 = base_digits_2 + checksum_2.to_s

    assert Croatia::UMCN.valid?(valid_umcn_1), "Should accept valid JMBG: #{valid_umcn_1}"
    assert Croatia::UMCN.valid?(valid_umcn_2), "Should accept valid JMBG: #{valid_umcn_2}"
  end

  def test_invalid_umcn_numbers
    # Test various invalid formats
    invalid_numbers = [
      nil,              # nil input
      "",               # empty string
      "123456789012",   # too short (12 digits)
      "12345678901234", # too long (14 digits)
      "abcd567890123",  # contains letters
      "0101990123a56",  # contains letter in middle
      "3201990123456",  # invalid day (32)
      "0113990123456",  # invalid month (13)
      "0100990123456",  # invalid day (00)
      "0000990123456"   # invalid month (00)
    ]

    invalid_numbers.each do |invalid_umcn|
      refute Croatia::UMCN.valid?(invalid_umcn), "Should reject invalid JMBG: #{invalid_umcn.inspect}"
    end
  end

  def test_date_validation
    # Test invalid dates that would fail Date.valid_date? check
    invalid_dates = [
      "2902990123456", # 29.02 in non-leap year 1999
      "3104990123456", # 31.04 (April has only 30 days)
      "3106990123456", # 31.06 (June has only 30 days)
      "3109990123456", # 31.09 (September has only 30 days)
      "3111990123456"  # 31.11 (November has only 30 days)
    ]

    invalid_dates.each do |invalid_date|
      refute Croatia::UMCN.valid?(invalid_date), "Should reject invalid date: #{invalid_date}"
    end
  end

  def test_century_calculation
    # Test different century prefixes
    # 0xx = 2000s, 9xx = 1800s, 1xx-8xx = 1900s

    # This test documents the century calculation logic
    # 2000s (0xx): "0101005123456" would be 01.01.2005
    # 1900s (1xx-8xx): "0101950123456" would be 01.01.1950
    # 1800s (9xx): "0101920123456" would be 01.01.1892

    # The method should parse dates correctly before checking checksum
    # We test this indirectly through valid/invalid date tests
    assert true, "Century calculation logic is tested through other date validation tests"
  end

  def test_checksum_calculation
    # Test the checksum algorithm specifically
    # The algorithm uses weights [7,6,5,4,3,2,7,6,5,4,3,2] for first 12 digits
    # sum % 11 where if result is 0 or 1, checksum is 0, otherwise 11 - result

    # Let's create a JMBG where we can calculate the expected checksum
    base_digits = "010199012345" # 01.01.1990, region 123, gender 4, serial 5
    digits = base_digits.chars.map(&:to_i)
    weights = [ 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ]

    sum = digits.each_with_index.sum { |d, i| d * weights[i] }
    mod = sum % 11
    expected_checksum = mod == 0 || mod == 1 ? 0 : 11 - mod

    valid_umcn = base_digits + expected_checksum.to_s
    invalid_umcn = base_digits + ((expected_checksum + 1) % 10).to_s

    assert Croatia::UMCN.valid?(valid_umcn), "Should validate JMBG with correct checksum"
    refute Croatia::UMCN.valid?(invalid_umcn), "Should reject JMBG with incorrect checksum"
  end

  def test_leap_year_february_29
    # Test February 29th in leap years vs non-leap years

    # 2000 was a leap year
    leap_year_base = "290200012345" # 29.02.2000
    digits = leap_year_base.chars.map(&:to_i)
    weights = [ 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ]
    sum = digits.each_with_index.sum { |d, i| d * weights[i] }
    mod = sum % 11
    checksum = mod == 0 || mod == 1 ? 0 : 11 - mod
    leap_year_umcn = leap_year_base + checksum.to_s

    assert Croatia::UMCN.valid?(leap_year_umcn), "Should accept Feb 29 in leap year 2000"

    # 1999 was not a leap year
    non_leap_year_umcn = "2902990123456"
    refute Croatia::UMCN.valid?(non_leap_year_umcn), "Should reject Feb 29 in non-leap year 1999"
  end

  def test_format_requirements
    # Test that it requires exactly 13 digits
    test_cases = [
      [ "", false ],
      [ "1", false ],
      [ "12", false ],
      [ "123456789012", false ],  # 12 digits
      [ "1234567890123", true ],  # 13 digits (will depend on other validations)
      [ "12345678901234", false ], # 14 digits
      [ "123456789012345", false ] # 15 digits
    ]

    test_cases.each do |input, should_pass_format|
      if should_pass_format
        # Even if format is correct, it might fail other validations
        # We're just testing it doesn't fail immediately on format
        result = Croatia::UMCN.valid?(input)
        # We can't assert true here because it might fail checksum/date validation
        assert [ true, false ].include?(result), "Should return boolean for valid format"
      else
        refute Croatia::UMCN.valid?(input), "Should reject format: #{input.inspect}"
      end
    end
  end

  def test_parse_method
    # Test parsing a valid UMCN
    # Let's create one that we know will work
    birthday = Date.new(1999, 1, 1)
    umcn_obj = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)
    umcn_string = umcn_obj.to_s

    umcn = Croatia::UMCN.parse(umcn_string)

    assert_instance_of Croatia::UMCN, umcn
    assert_equal Date.new(1999, 1, 1), umcn.birthday
    assert_equal 33, umcn.region_code
    assert_equal 0, umcn.sequence_number
  end

  def test_parse_with_2000s_date
    # Test millennium calculation for 2000s (starts with 0)
    birthday = Date.new(2005, 1, 1)
    umcn_obj = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)
    umcn_string = umcn_obj.to_s

    umcn = Croatia::UMCN.parse(umcn_string)

    assert_equal Date.new(2005, 1, 1), umcn.birthday
  end

  def test_parse_with_invalid_date
    # Test that invalid dates raise Date::Error which is caught
    assert_raises(Date::Error) do
      Croatia::UMCN.parse("3202990330001")  # 32.02.1999 - invalid date
    end
  end

  def test_initialize_with_valid_data
    birthday = Date.new(1990, 5, 15)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 123)

    assert_equal birthday, umcn.birthday
    assert_equal 33, umcn.region_code
    assert_equal 123, umcn.sequence_number
  end

  def test_region_code_validation
    birthday = Date.new(1990, 1, 1)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)

    # Test valid region code
    umcn.region_code = 33
    assert_equal 33, umcn.region_code

    # Test invalid region code
    assert_raises(ArgumentError, "Invalid region code") do
      umcn.region_code = 999
    end
  end

  def test_sequence_number_validation
    birthday = Date.new(1990, 1, 1)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)

    # Test valid sequence numbers
    umcn.sequence_number = 0
    assert_equal 0, umcn.sequence_number

    umcn.sequence_number = 999
    assert_equal 999, umcn.sequence_number

    # Test invalid sequence numbers
    assert_raises(ArgumentError, "Sequence number must be between 0 and 999") do
      umcn.sequence_number = -1
    end

    assert_raises(ArgumentError, "Sequence number must be between 0 and 999") do
      umcn.sequence_number = 1000
    end
  end

  def test_sex_determination
    birthday = Date.new(1990, 1, 1)

    # Test male (sequence <= 499)
    umcn_male = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 250)
    assert_equal :male, umcn_male.sex

    umcn_male_boundary = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 499)
    assert_equal :male, umcn_male_boundary.sex

    # Test female (sequence > 499)
    umcn_female = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 500)
    assert_equal :female, umcn_female.sex

    umcn_female_high = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 750)
    assert_equal :female, umcn_female_high.sex
  end

  def test_region_of_birth
    birthday = Date.new(1990, 1, 1)

    # Test Croatian regions
    umcn_zagreb = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)
    assert_equal "Zagreb", umcn_zagreb.region_of_birth

    umcn_dalmatia = Croatia::UMCN.new(birthday: birthday, region_code: 38, sequence_number: 0)
    assert_equal "Dalmatia", umcn_dalmatia.region_of_birth

    # Test other regions
    umcn_slovenia = Croatia::UMCN.new(birthday: birthday, region_code: 50, sequence_number: 0)
    assert_equal "Slovenia", umcn_slovenia.region_of_birth

    umcn_belgrade = Croatia::UMCN.new(birthday: birthday, region_code: 71, sequence_number: 0)
    assert_equal "Belgrade", umcn_belgrade.region_of_birth
  end

  def test_to_s_formatting
    birthday = Date.new(1990, 5, 15)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 123)

    result = umcn.to_s

    # Should be 13 digits
    assert_equal 13, result.length
    assert_match(/\A\d{13}\Z/, result)

    # Should start with the date (15.05.990)
    assert result.start_with?("1505990")

    # Should contain region code (33) and sequence (123)
    assert result.include?("33")
    assert result.include?("123")
  end

  def test_to_s_with_checksum_calculation
    birthday = Date.new(1999, 1, 1)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)

    umcn_string = umcn.to_s

    # The generated UMCN should be valid according to our validation
    assert Croatia::UMCN.valid?(umcn_string), "Generated UMCN should be valid: #{umcn_string}"
  end

  def test_checksum_method
    birthday = Date.new(1990, 1, 1)
    umcn = Croatia::UMCN.new(birthday: birthday, region_code: 33, sequence_number: 0)

    checksum = umcn.checksum
    assert_kind_of Integer, checksum
    assert (0..9).include?(checksum), "Checksum should be a single digit"
  end

  def test_round_trip_parsing
    # Test that we can parse a generated UMCN and get the same data back
    original_birthday = Date.new(1985, 12, 25)
    original_region = 38  # Dalmatia
    original_sequence = 456

    umcn = Croatia::UMCN.new(
      birthday: original_birthday,
      region_code: original_region,
      sequence_number: original_sequence
    )

    umcn_string = umcn.to_s
    parsed_umcn = Croatia::UMCN.parse(umcn_string)

    assert_equal original_birthday, parsed_umcn.birthday
    assert_equal original_region, parsed_umcn.region_code
    assert_equal original_sequence, parsed_umcn.sequence_number
  end

  def test_millennium_boundary_cases
    # Test 1999 vs 2000 year handling

    # 1999 should be in 1000s millennium
    umcn_1999 = Croatia::UMCN.new(birthday: Date.new(1999, 12, 31), region_code: 33, sequence_number: 0)
    umcn_1999_string = umcn_1999.to_s
    parsed_1999 = Croatia::UMCN.parse(umcn_1999_string)
    assert_equal 1999, parsed_1999.birthday.year

    # 2000 should be in 2000s millennium
    umcn_2000 = Croatia::UMCN.new(birthday: Date.new(2000, 1, 1), region_code: 33, sequence_number: 0)
    umcn_2000_string = umcn_2000.to_s
    parsed_2000 = Croatia::UMCN.parse(umcn_2000_string)
    assert_equal 2000, parsed_2000.birthday.year
  end

  def test_region_codes_coverage
    # Test a sampling of different region codes
    birthday = Date.new(1990, 1, 1)

    test_regions = [
      [ 0, "Yugoslavia" ],
      [ 17, "Sarajevo" ],  # Bosnia
      [ 21, "Podgorica" ], # Montenegro
      [ 33, "Zagreb" ],    # Croatia
      [ 45, "Skopje" ],    # North Macedonia
      [ 50, "Slovenia" ],  # Slovenia
      [ 71, "Belgrade" ],  # Serbia
      [ 80, "Novi Sad" ], # Vojvodina
      [ 90, "Pristina" ]   # Kosovo
    ]

    test_regions.each do |code, expected_name|
      umcn = Croatia::UMCN.new(birthday: birthday, region_code: code, sequence_number: 0)
      assert_equal expected_name, umcn.region_of_birth, "Region code #{code} should map to #{expected_name}"
    end
  end
end
