# frozen_string_literal: true

require "test_helper"

class PDF417Test < Minitest::Test
  def test_croatian_diacritics_encoding
    barcode = Croatia::PDF417.new("ŠĐĆŽČĆžšđčž")

    assert barcode.to_svg.start_with?("<svg")
  end
end
