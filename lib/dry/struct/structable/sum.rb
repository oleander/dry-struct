# frozen_string_literal: true

require "dry/core/constants"
require "dry/core/memoizable"

require_relative "config"
require_relative "interface"

module Dry
  class Struct
    module Structable
      class Sum < Module
        include Dry::Core::Memoizable
        include Dry::Core::Constants

        def initialize(scope, options)
          @scope, @options = scope, options
        end

        private

        def included(*)
          super

          if meta.method_defined?(:__type__)
            raise Error, "[__type__] already defined on [#{@scope}]"
          end

          meta.define_method(:__type__, &to_type)
          meta.module_eval { private :__type__ }
          meta.prepend(Interface)
        end

        def config
          Config.call(scope: @scope, config: @options)
        end

        def to_type
          config.method(:type)
        end

        def meta
          @scope.singleton_class
        end
      end
    end
  end
end
