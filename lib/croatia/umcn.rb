# frozen_string_literal: true

# JMBG - Jedinstveni Matični Broj Građana
# UMCN - Unique Master Citizen Number
module Croatia::UMCN
  def self.valid?(umcn)
    return false unless umcn =~ /\A\d{13}\Z/

    digits = umcn.chars.map(&:to_i)

    day = digits[0..1].join.to_i
    month = digits[2..3].join.to_i
    year = digits[4..6].join.to_i
    century = case digits[4]
    when 0 then 2000
    when 9 then 1800
    else 1900
    end
    full_year = century + year

    return false unless Date.valid_date?(full_year, month, day)

    weights = [ 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 ]
    sum = digits[0..11].each_with_index.sum { |d, i| d * weights[i] }
    mod = sum % 11
    checksum = mod == 0 || mod == 1 ? 0 : 11 - mod

    digits[12] == checksum
  end
end
