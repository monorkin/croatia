# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "croatia"

require "date"
require "openssl"
require "rqrcode"
require "pdf-417"
require "minitest/autorun"

require_relative "./helpers/certificate_helper"
