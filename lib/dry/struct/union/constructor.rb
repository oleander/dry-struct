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
        attribute(:cache, Types::Instance(Concurrent::Map).default do
          Concurrent::Map.new do |store, key|
            store.fetch_or_store(key, Concurrent::Map.new)
          end
        end)

        schema schema.strict

        # Calls {#bind} and returns and instance of {Constructor}
        #
        # @return [Constructor]
        def self.call(**options)
          super(**options).tap(&:bind)
        end

        # Creates {Dry::Struct::Sum} type from types found in {#scope}
        # Returns a lazy error {Types::Constructor) when {#types} is empty
        # Calls are cached and expires when new constants appears on {#scope}
        #
        # @return [Dry::Struct::Sum]
        def sum
          compute_cache(:sum) do
            types.reduce(:|) || Types.Constructor(Dry::Struct::Sum) do
              raise Error, "No constructors found in [#{scope}]"
            end
          end
        end

        # Excludes constants passed by user via {exclude:}
        # Includes constants passed by user via {include:}
        # Falls back to local constants in {#scope}
        # Uses {#constructor?} to exclude incompatible types
        # @see {Extensions} for information about {#constructor?}
        # @see {#sum} for information about caching
        #
        # @return [Array<#constructor?>]
        def types
          compute_cache(:types) do
            (included - excluded).map(&method(:to_const)).select(&:constructor?)
          end
        end

        # Pretty prints {#types}
        # @see {#sum} for information about caching
        #
        # @return [String]
        def name
          compute_cache(:name) do
            "%<name>s<[%<type>s]>" % {type: joined_types, name: scope}
          end
        end

        # Used by {#types} to filter out usable types
        #
        # @return [Bool]
        def constructor?
          true
        end

        # Delegates calls on {#scope} to {#sum} and {#name}
        # Maps all instance methods on {Dry::Struct::Sum} to {#scope}
        #
        # @return [Void]
        # @private
        def bind(constructor: self)
          %i[__sum__ __types__ name constructor?].each do |name|
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
        end

        private

        # Cache key used to cached calls
        #
        # @return [Array<Symbol>]
        def key
          scope.constants(false)
        end

        # All types to be used by {#types}
        # The order specified will be preserved
        # Falls back to local constants on {#scope}
        #
        # @return [Array<Symbol>]
        def included
          include || scope.constants(false).sort
        end

        # Cache handler used by the public API
        #
        # @name [Symbol] Method name
        # @block [Proc] To be cached
        # @return [Any]
        def compute_cache(name, &block)
          cache[key][name] ||= block.call
        end

        # Renders {#types} on the form "Type2 | Type2 | ..."
        # Falls back to "Unknown" when type has no name
        #
        # @return [String]
        def joined_types
          types.map { |t| t.name || "Unknown" }.join(" | ")
        end

        # Retrieves the given constant from {#scope}
        #
        # @name [Symbol] Constant name
        # @return [Constant] The constant
        # @raise [Error] When {name} cannot be found
        def to_const(name)
          scope.const_get(name)
        rescue NameError
          raise Error, "Constant [#{name}] not defined in [#{scope}]"
        end

        # Renamed to be inline with {#included}
        alias_method :excluded, :exclude
        # Bound to {Union}s public interface
        alias_method :__types__, :types
        alias_method :__sum__, :sum
      end
    end
  end
end
