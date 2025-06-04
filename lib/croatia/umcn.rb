# frozen_string_literal: true

# Validates and parses Croatian Unique Master Citizen Numbers (JMBG/UMCN)
#
# JMBG (Jedinstveni Matični Broj Građana) is the Unique Master Citizen Number
# used in former Yugoslav countries including Croatia. This 13-digit number
# encodes birth date, region of birth, sequence number, and includes a checksum.
#
# The format is: DDMMYYYRRSSSC where:
# - DD: day of birth (01-31)
# - MM: month of birth (01-12)
# - YYY: last three digits of birth year
# - RR: region code (see REGION_CODES constant)
# - SSS: sequence number (000-999, where ≤499 = male, ≥500 = female)
# - C: checksum digit
#
# @example Validating a UMCN
#   Croatia::UMCN.valid?("1234567890123")  # => true/false
#
# @example Parsing a UMCN
#   umcn = Croatia::UMCN.parse("1234567890123")
#   umcn.birthday      # => Date object
#   umcn.sex           # => :male or :female
#   umcn.region_of_birth # => "Zagreb"
#
# @example Creating a UMCN instance
#   umcn = Croatia::UMCN.new(
#     birthday: Date.new(1990, 1, 1),
#     sequence_number: 123,
#     region_code: 33
#   )
#   umcn.to_s          # => "0101903301234"
#
# @author Croatia Gem
# @since 0.3.0
class Croatia::UMCN
  WEIGHTS = [ 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ]
  REGION_CODES = {
    # Special / Foreign
    0 => "Yugoslavia",
    1 => "Foreigner in BiH",
    2 => "Foreigner in Montenegro",
    3 => "Foreigner in Croatia",
    4 => "Foreigner in North Macedonia",
    5 => "Foreigner in Slovenia",
    6 => "Foreigner in Serbia",
    7 => "Foreigner in Vojvodina",
    8 => "Foreigner in Kosovo",
    9 => "Yugoslavia",

    # Bosnia and Herzegovina (10–19)
    10 => "Banja Luka",
    11 => "Bihac",
    12 => "Doboj",
    13 => "Gorazde",
    14 => "Livno",
    15 => "Mostar",
    16 => "Prijedor",
    17 => "Sarajevo",
    18 => "Tuzla",
    19 => "Zenica",

    # Montenegro (21–29)
    21 => "Podgorica",
    22 => "Bar",
    23 => "Budva",
    24 => "Herceg Novi",
    25 => "Cetinje",
    26 => "Niksic",
    27 => "Berane",
    28 => "Bijelo Polje",
    29 => "Pljevlja",

    # Croatia (30–39)
    30 => "Slavonia",
    31 => "Podravina",
    32 => "Medimurje",
    33 => "Zagreb",
    34 => "Kordun",
    35 => "Lika",
    36 => "Istria",
    37 => "Banovina",
    38 => "Dalmatia",
    39 => "Zagorje",

    # North Macedonia (41–49)
    41 => "Bitola",
    42 => "Kumanovo",
    43 => "Ohrid",
    44 => "Prilep",
    45 => "Skopje",
    46 => "Strumica",
    47 => "Tetovo",
    48 => "Veles",
    49 => "Stip",

    # Slovenia (50)
    50 => "Slovenia",

    # Serbia (70–79)
    70 => "Serbia Abroad",
    71 => "Belgrade",
    72 => "Sumadija",
    73 => "Nis",
    74 => "Morava",
    75 => "Zajecar",
    76 => "Podunavlje",
    77 => "Kolubara",
    78 => "Kraljevo",
    79 => "Uzice",

    # Vojvodina (80–89)
    80 => "Novi Sad",
    81 => "Sombor",
    82 => "Subotica",
    83 => "Zrenjanin",
    84 => "Kikinda",
    85 => "Pancevo",
    86 => "Vrbas",
    87 => "Sremska Mitrovica",
    88 => "Ruma",
    89 => "Backa Topola",

    # Kosovo (90–99)
    90 => "Pristina",
    91 => "Prizren",
    92 => "Pec",
    93 => "Djakovica",
    94 => "Mitrovica",
    95 => "Gnjilane",
    96 => "Ferizaj",
    97 => "Decan",
    98 => "Klina",
    99 => "Malisevo"
  }.freeze


  # @!attribute [rw] birthday
  #   @return [Date] the birthday extracted from the UMCN
  # @!attribute [rw] region_code
  #   @return [Integer] the region code (see REGION_CODES constant)
  # @!attribute [rw] sequence_number
  #   @return [Integer] the sequence number (0-999)
  # @!attribute [rw] checksum
  #   @return [Integer] the checksum digit
  attr_accessor :birthday, :region_code, :sequence_number, :checksum

  # Validates a Croatian Unique Master Citizen Number (JMBG/UMCN)
  #
  # @param umcn [String] the UMCN to validate (13 digits)
  # @return [Boolean] true if the UMCN is valid, false otherwise
  #
  # @example
  #   Croatia::UMCN.valid?("1234567890123")  # => true/false
  #   Croatia::UMCN.valid?(nil)              # => false
  #   Croatia::UMCN.valid?("invalid")        # => false
  def self.valid?(umcn)
    return false if umcn.nil?
    return false unless umcn.match?(/\A\d{13}\Z/)

    parse(umcn).checksum == umcn.strip[-1].to_i
  rescue Date::Error, ArgumentError
    false
  end

  # Parses a Croatian UMCN and extracts its components
  #
  # @param umcn [String] the UMCN to parse (13 digits)
  # @return [Croatia::UMCN] parsed UMCN instance
  # @raise [Date::Error] if the date is invalid
  # @raise [ArgumentError] if the format is invalid
  #
  # @example
  #   umcn = Croatia::UMCN.parse("1234567890123")
  #   umcn.birthday      # => Date object
  #   umcn.sex           # => :male or :female
  #   umcn.region_of_birth # => "Zagreb"
  def self.parse(umcn)
    digits = umcn.chars.map(&:to_i)

    day = digits[0..1].join.to_i
    month = digits[2..3].join.to_i
    year = digits[4..6].join.to_i
    millenium = case digits[4]
    when 0 then 2000
    else 1000
    end
    full_year = millenium + year

    birthday = Date.new(full_year, month, day)
    region_code = digits[7..8].join.to_i
    sequence_number = digits[9..11].join.to_i

    new(birthday: birthday, region_code: region_code, sequence_number: sequence_number)
  end

  # Creates a new UMCN instance
  #
  # @param birthday [Date] the birthday
  # @param region_code [Integer] the region code (see REGION_CODES)
  # @param sequence_number [Integer] the sequence number (0-999)
  def initialize(birthday:, region_code:, sequence_number:)
    @birthday = birthday
    @region_code = region_code
    @sequence_number = sequence_number
  end

  # Sets the region code with validation
  #
  # @param value [Integer] the region code
  # @raise [ArgumentError] if the region code is invalid
  # @return [Integer] the validated region code
  def region_code=(value)
    value = value.to_i

    if REGION_CODES.key?(value)
      @region_code = value
    else
      raise ArgumentError, "Invalid region code: #{value}"
    end
  end

  # Sets the sequence number with validation
  #
  # @param value [Integer] the sequence number (0-999)
  # @raise [ArgumentError] if the sequence number is out of range
  # @return [Integer] the validated sequence number
  def sequence_number=(value)
    value = value.to_i

    if value < 0 || value > 999
      raise ArgumentError, "Sequence number must be between 0 and 999"
    end

    @sequence_number = value
  end

  # Determines the sex based on the sequence number
  #
  # @return [Symbol] :male if sequence_number <= 499, :female otherwise
  def sex
    sequence_number <= 499 ? :male : :female
  end

  # Gets the region of birth name
  #
  # @return [String] the region name from REGION_CODES
  def region_of_birth
    REGION_CODES[region_code]
  end

  # Converts the UMCN to its string representation
  #
  # @return [String] the 13-digit UMCN string with checksum
  def to_s
    parts = []
    parts << birthday.strftime("%d%m")
    parts << format("%03d", birthday.year % 1000)
    parts << format("%02d", region_code)
    parts << format("%03d", sequence_number)

    digits = parts.join.chars.map(&:to_i)
    sum = digits.each_with_index.sum { |digit, i| digit * WEIGHTS[i] }
    mod = sum % 11

    checksum = (mod == 0 || mod == 1) ? 0 : (11 - mod)

    parts << checksum.to_s
    parts.join
  end

  # Calculates and returns the checksum digit
  #
  # @return [Integer] the checksum digit (0-9)
  def checksum
    to_s[-1].to_i
  end
end
