# frozen_string_literal: true

module Croatia::Invoice::Identifiable
  def self.included(base)
    base.extend ClassMethods
    base.include InstanceMethods
  end

  def self.valid_integer_identifier?(value, max_length:)
    return false if value.nil?
    value = value.to_s
    !value.start_with?("0") && value.match?(/\A\d+\z/) && value.length.between?(1, max_length)
  end

  module ClassMethods
    BUSINESS_LOCATION_IDENTIFIER_REGEX = /\A[a-zA-Z0-9]{1,20}\z/.freeze

    def valid_business_location_identifier?(value)
      value&.match?(BUSINESS_LOCATION_IDENTIFIER_REGEX)
    end

    def valid_sequential_number?(value)
      Croatia::Invoice::Identifiable.valid_integer_identifier?(value, max_length: 20)
    end

    def valid_register_identifier?(value)
      Croatia::Invoice::Identifiable.valid_integer_identifier?(value, max_length: 20)
    end
  end

  module InstanceMethods
    def business_location_identifier=(value)
      if value.nil?
        raise ArgumentError, "Business location identifier cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_business_location_identifier?(value)
        raise ArgumentError, "Business location identifier must be a non-empty string with a maximum length of 20 characters (only letters and digits are allowed)"
      end

      @business_location_identifier = value
    end

    def register_identifier=(value)
      if value.nil?
        raise ArgumentError, "Register identifier cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_register_identifier?(value)
        raise ArgumentError, "Register identifier must be a number no longer than 20 digits and without leading zeros"
      end

      @register_identifier = value
    end

    def sequential_number=(value)
      if value.nil?
        raise ArgumentError, "Sequential number cannot be nil"
      end

      value = value.to_s.strip

      unless self.class.valid_sequential_number?(value)
        raise ArgumentError, "Sequential number must be a number no longer than 20 digits and without leading zeros"
      end

      @sequential_number = value
    end

    def number
      [ sequential_number, business_location_identifier, register_identifier ].join("/")
    end
  end
end
