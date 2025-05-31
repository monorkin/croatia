# frozen_string_literal: true

module Croatia::Enum
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def enum(name, values, **options)
      name = name.to_s.to_sym unless name.is_a?(Symbol)
      values = values.zip(values) if values.is_a?(Array)

      unless values.respond_to?(:to_h)
        raise ArgumentError, "Enum values must be defined as a Hash or as an Array"
      end

      values = values.to_h.freeze
      values_method_name = "#{name}_values".to_sym

      define_singleton_method(values_method_name) do
        values
      end

      define_method("#{name}=") do |value|
        values = self.class.public_send(values_method_name)

        enum_value = values[value]
        enum_value = value if enum_value.nil? && values.has_value?(value)

        if enum_value.nil? && !options[:allow_nil]
          raise ArgumentError, "Invalid value for enum #{name}: #{value.inspect}"
        end

        instance_variable_set("@#{name}", enum_value)
      end

      define_method(name) do
        instance_variable_get("@#{name}")
      end

      prefix = options[:prefix] ? "#{options[:prefix]}_" : ""
      suffix = options[:suffix] ? "_#{options[:suffix]}" : ""

      values.each do |key, value|
        value_method_name = "#{prefix}#{key}#{suffix}"

        define_method("#{value_method_name}?") do
          instance_variable_get("@#{name}") == value
        end

        define_method("#{value_method_name}!") do
          public_send("#{name}=", value)
        end
      end
    end
  end
end
