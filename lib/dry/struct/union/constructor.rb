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
        attribute(:cache, Types::Hash.default { Hash.new(EMPTY_HASH.dup) })
        attribute? :include, Types::Constants.constrained(min_size: 1)
        attribute :exclude, Types::Constants.default(EMPTY_ARRAY)
        attribute :scope, Types::Instance(Module)

        using(Module.new {
          refine Dry::Struct.singleton_class do
            alias_method :__name__, :name
          end
        })

        schema schema.strict

        # Allows calls on {scope} to be dispatched to {self}
        #
        # @see #bind
        # @return [Constructor]
        def self.call(**options)
          super(**options).tap(&:bind)
        end

        # Constructs {Dry::Struct::Sum} from structs found in {#scope}
        #
        # @raises [Dry::Struct::Error] When {#scope} is empty
        # @return [Dry::Struct::Sum | Types::Constructor]
        def sum
          compute_cache(:sum) do
            types.reduce(:|) || Types.Constructor(Dry::Struct::Sum) do
              raise Error, "No constructors found in [#{scope.__name__}]"
            end
          end
        end

        # Excludes constants passed by user via {exclude:}
        # Includes constants passed by user via {include:}
        # Falls back to local constants in {#scope}
        # Uses {#constructor?} to exclude incompatible types
        #
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
            "%<name>s<[%<type>s]>" % {type: joined_types, name: scope.__name__}
          end
        end

        # Used by {#types} to filter out usable types
        #
        # @return [Bool]
        def constructor?
          true
        end

        # Allows {#scope} to behave like a {Dry::Struct}
        # by dispatching calls on {#scope} to {Constructor#sum}
        #
        # @private
        def bind(constructor: self)
          class << scope
            alias_method :__name__, :name
          end

          %i[__sum__ __types__ constructor? name].each do |name|
            scope.define_singleton_method(name, &method(name))
          end

          Sum.instance_methods(true).each do |method|
            next if scope.respond_to?(method)

            scope.define_singleton_method(method) do |*args, &block|
              constructor.sum.__send__(method, *args, &block)
            end
          end
        end

        private

        def key
          scope.constants(false).sort
        end
        alias_method :module_constants, :key

        # All types to be used by {#types}
        # The order specified will be preserved
        # Falls back to local constants on {#scope}
        #
        # @return [Array<Symbol>]
        def included
          include || module_constants
        end

        # Cache handler used by the public API
        #
        # @name [Symbol] Method name
        # @block [Proc] To be cached
        # @return [Any]
        def compute_cache(name, current_key = key, &block)
          cache[current_key][name] ||= block.call
        ensure # Remove old keys to prevent memory leaks
          if @latest_key != current_key
            cache.delete(@latest_key)
          end

          @latest_key = current_key
        end

        # Renders {#types} on the form "Type2 | Type2 | ..."
        # Falls back to "Unknown" when type has no name
        #
        # @return [String]
        def joined_types
          types.map { |t| t.__name__ || "Anonymous" }.join(" | ")
        end

        # Retrieves constant {name} from {#scope}
        #
        # @name [Symbol] Constant name
        # @return [Constant] The constant
        # @raise [Error] When {name} cannot be found
        def to_const(name)
          scope.const_get(name)
        rescue NameError
          raise Error, "Constant [#{name}] not defined in [#{scope.__name__}]"
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
