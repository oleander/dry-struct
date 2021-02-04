# frozen_string_literal: true

require "dry/core/memoizable"
require "dry/types"
require "dry/struct"

require_relative "structable/sum"

module Dry
  class Struct
    module Structable
      EXISTING = constants.map(&method(:const_get)).to_set.freeze

      def self.included(base)
        super
        base.include(Sum.new(base, EMPTY_HASH))
      end
    end
  end
end
