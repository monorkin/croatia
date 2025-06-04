# frozen_string_literal: true

require "pathname"

module FixturesHelper
  def file_fixture(filename)
    Pathname.new(File.expand_path("../fixtures/#{filename}", __dir__))
  end
end
