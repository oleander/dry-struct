# frozen_string_literal: true

require "dry/core/memoizable"
require "dry/core/constants"
require "dry/struct"
require "ostruct"

module Dry
  class Struct
    module Structable
      class Config < ::Dry::Struct
        include Dry::Core::Memoizable
        include Dry::Core::Constants

        module Types
          include Dry::Types(default: :strict)

          Module = Types.Instance(Module)
          Array = Coercible::Array
        end

        attribute :scope, Types::Module
        attribute :config do
          attribute? :except, Types::Array.default(EMPTY_ARRAY)
          attribute? :only, Types::Array
        end

        def type
          types.reduce(:|) || throw_no_structs
        end

        def types
          unfiltered_types.reject(&abstract?).sort_by do |el|
            lookup[el]
          end
        end

        private

        def throw_no_structs
          Types.Constructor(Dry::Struct) do
            raise Error, "No struct classes found in module [#{scope}]"
          end
        end

        def unfiltered_types
          configued_constants.select(&inheritable?).select(&type?)
        end

        def lookup
          configued_constants.each_with_index.to_h
        end

        def abstract?
          unfiltered_types.map(&:abstract_class).to_set.method(:include?)
        end

        def inheritable?
          -> value { value.respond_to?(:ancestors) }
        end

        def type?
          -> klass { klass.respond_to?(:|) }
        end

        def configued_constants
          (included - excluded).select(&inheritable?)
        end

        def included
          config.only ? config.only.map(&to_const).to_set : constants
        end

        def excluded
          (config.except.map(&to_const).to_set + EXISTING)
        end

        def constants
          scope.constants.map(&to_const).to_set
        end

        def to_const
          scope.method(:const_get)
        end

        memoize :unfiltered_types, :constants, :type
        memoize :lookup, :types, :configued_constants
      end
    end
  end
end
