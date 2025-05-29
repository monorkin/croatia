# Croatia

Croatia is a gem that contains various utilities for performing Croatia-specific actions:
- [x] Validating PINs (aka. OIBs)
- [ ] Fiscalization
- [ ] E-Invoice

## Installation

You can install the gem into your app using the `bundle` command

```bash
bundle add croatia
```

or you can add it manually to your Gemfile

```bash
gem "croatia"
```

## Usage

This gem doesn't load anything by default, so you need to require the specific module you want to use.

### PINs / OIBs

```ruby
require "croatia/pin"

Croatia::Pin.valid?("12345678903") # => true
Croatia::Pin.valid?("12345678900") # => false
```

## Development

Make sure you have at least Ruby 3.1 installed. You can check your Ruby version by running `ruby -v`.

After checking out the repo, run `bin/setup` to install dependencies. 

You can start an interactive shell with the gem loaded into it using `bin/console`.

To run the test suite use `bin/test`.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/monorkin/croatia.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
