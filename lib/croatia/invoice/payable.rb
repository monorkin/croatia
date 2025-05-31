# frozen_string_literal: true

module Croatia::Invoice::Payable
  def self.included(base)
    base.include InstanceMethods
  end

  module InstanceMethods
  end
end
