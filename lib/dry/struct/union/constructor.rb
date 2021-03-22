# frozen_string_literal: true

require "dry/core/constants"
require "concurrent/map"
require "dry/struct"
require "dry/types"

module Dry
  class Struct
    module Union
      autoload :Extensions, "dry/struct/union/extensions"
      # @private
      class Constructor < Struct
        using Extensions

        module Types
          include Dry::Types(default: :coercible)
          Constants = Array.of(Symbol)
        end

        # @see Dry::Struct::Union
        attribute? :include, Types::Constants.constrained(min_size: 1)
        attribute :exclude, Types::Constants.default(EMPTY_ARRAY)
        attribute :scope, Types::Instance(Module)
        attribute :cache, Types::Instance(Concurrent::Map).default {
          Concurrent::Map.new do |store, key|
            store.fetch_or_store(key, Concurrent::Map.new)
          end
        }

        schema schema.strict

        # Binds {self} to {#scope} and returns an instance
        #
        # @return [Constructor]
        def self.call(**options)
          super(**options).tap(&:bind)
        end

        # Creates sum type from {#types}
        # Returns a lazy error when no types are found
        #
        # @return [Dry::Struct::Sum]
        def sum
          compute_cache(:sum) do
            types.reduce(:|) || Types.Constructor(Dry::Struct::Sum) do
              raise Error, "No constructors found in [#{scope}]"
            end
          end
        end

        # Retrieves types in {scope}, filteres out the non-types using {#constructor?}
        #
        # @return [Array<Dry::Struct, Dry::Struct::Union>]
        def types
          compute_cache(:types) do
            (included - excluded).map(&method(:to_const)).select(&:constructor?)
          end
        end

        # Cache key used for {#types}
        #
        # @return [Array<Symbol>]
        def key
          scope.constants(false)
        end

        # Pretty prints module using {#types}
        #
        # @return [String]
        def name
          compute_cache(:name) do
            "%<name>s<[%<type>s]>" % {type: joined_names, name: scope}
          end
        end

        # Used by {#types} to filter out usable types
        #
        # @return [Bool]
        def constructor?
          true
        end

        # Delegates calls on {#scope} to {#sum} and {self}
        # Uses methods found in {Dry::Struct::Sum} to determine which ones
        def bind(constructor: self)
          %i[__sum__ __types__ name constructor? clear_cache].each do |name|
            scope.define_singleton_method(name) do |*args, &block|
              constructor.__send__(name, *args, &block)
            end
          end

          Sum.instance_methods(true).each do |method|
            next if scope.respond_to?(method)

            scope.define_singleton_method(method) do |*args, &block|
              constructor.sum.__send__(method, *args, &block)
            end
          end

          # Used for the {#constructor?} method
          unless scope.include?(Union)
            scope.extend(Union)
          end
        end

        private

        # All types to be included
        # The order is preserved
        #
        # @return [Array<Symbol>]
        def included
          include || scope.constants(false).sort
        end

        # Cache handler used by heavy internal methods
        def compute_cache(name, &block)
          cache[key][name] ||= block.call
        end

        # @return [String]
        def joined_names
          types.map { |t| t.name || "Unknown" }.join(" | ")
        end

        # Fetches {name} constant from {scope}
        #
        # @param name [Symbol]
        # @return [Constant]
        def to_const(name)
          scope.const_get(name)
        rescue NameError
          raise Error, "Constant [#{name}] not defined in [#{scope}]"
        end

        alias_method :excluded, :exclude
        alias_method :__types__, :types
        alias_method :__sum__, :sum
      end
    end
  end
end
