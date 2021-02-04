# frozen_string_literal: true

require "dry/core/constants"

module Dry
  class Struct
    module Structable
      module Interface
        include Dry::Core::Constants

        def method_missing(method, *args, &block)
          super unless respond_to_missing?(method)

          __type__.public_send(method, *args, &block)
        end

        def respond_to_missing?(method, include_private = false)
          __type__.respond_to?(method, include_private) || super
        end

        def name
          "<%<name>s[%<type>s]>" % {name: super, type: __type__.name}
        end

        def abstract_class
          Undefined
        end
      end
    end
  end
end
