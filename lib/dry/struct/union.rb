# frozen_string_literal: true

require "dry/struct"

module Dry
  class Struct
    # Include {Union} to enable type like behaviour to a module
    #
    # @option include [Array<Symbol>] Constants to be Included
    # @option exclude [Array<Symbol>] Constants to be excluded
    #
    # @return [Dry::Struct::Union::Constructor]
    # @raise [Dry::Struct::Error]
    #
    # @example Constructor responding to 'Dry::Struct::Sum<Earth | Mars>'
    #   module Planet
    #     include Dry::Struct::Union(exclude: 'Pluto')
    #
    #     module Types
    #       include Dry::Types()
    #     end
    #
    #     class Base < Dry::Struct
    #       abstract
    #     end
    #
    #     class Earth < Base
    #       attribute :id, Types.Value(:earth)
    #     end
    #
    #     class Pluto < Base
    #       attribute :id, Types.Value(:pluto)
    #     end
    #
    #     class Mars < Base
    #       attribute :id, Types.Value(:mars)
    #     end
    #   end
    #
    #   Planet.call({ id: :mars }) # => Planet::Mars
    #   Planet.call({ id: :earth }) # => Planet::Earth
    #   Planet.call({ id: :pluto }) # => raises Dry::Struct::Error
    #
    def self.Union(**options)
      Module.new do
        define_singleton_method(:included) do |scope|
          super(scope)
          Union::Constructor.call(scope: scope, **options)
        end
      end
    end

    module Union
      autoload :Constructor, "dry/struct/union/constructor"

      # Include {Union} to add {Struct::Sum} like behavior to a module
      def self.prepended(scope)
        super
        Union::Constructor.call(scope: scope)
      end

      # @private
      def self.included(scope)
        super
        scope.prepend(self)
      end
    end
  end
end
