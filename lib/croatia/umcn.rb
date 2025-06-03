# frozen_string_literal: true

# JMBG - Jedinstveni Matični Broj Građana
# UMCN - Unique Master Citizen Number
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


  attr_accessor :birthday, :region_code, :sequence_number, :checkusm

  def self.valid?(umcn)
    return false if umcn.nil?
    return false unless umcn.match?(/\A\d{13}\Z/)

    parse(umcn).checksum == umcn.strip[-1].to_i
  rescue Date::Error
    false
  end

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

  def initialize(birthday:, region_code:, sequence_number:)
    @birthday = birthday
    @region_code = region_code
    @sequence_number = sequence_number
  end

  def region_code=(value)
    value = value.to_i

    if REGION_CODES.key?(value)
      @region_code = value
    else
      raise ArgumentError, "Invalid region code: #{value}"
    end
  end

  def sequence_number=(value)
    value = value.to_i

    if value < 0 || value > 999
      raise ArgumentError, "Sequence number must be between 0 and 999"
    end

    @sequence_number = value
  end

  def sex
    sequence_number <= 499 ? :male : :female
  end

  def region_of_birth
    REGION_CODES[region_code]
  end

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

  def checksum
    to_s[-1].to_i
  end
end
