# frozen_string_literal: true

require_relative "lib/croatia/version"

Gem::Specification.new do |spec|
  spec.name = "croatia"
  spec.version = Croatia::VERSION
  spec.authors = [ "Stanko K.R." ]
  spec.email = [ "hey@stanko.io" ]

  spec.summary = "A gem for performing tasks specific to Croatia"
  spec.description = <<~DESC
  Croatia is a gem that contains various utilities for performing Croatia-specific actions like:
  - PIN/OIB validation
  DESC
  spec.homepage = "https://github.com/monorkin/croatia"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[pkg/ bin/ test/ . Gemfile CHANGELOG README])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "connection_pool"
  spec.add_dependency "nokogiri"
  spec.add_dependency "openssl"
  spec.add_dependency "rexml"
  spec.add_dependency "tzinfo"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
