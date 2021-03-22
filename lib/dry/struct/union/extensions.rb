# frozen_string_literal: true

require "dry/struct"

module Dry
  class Struct
    module Union
      # Used by {Constructor} to filter out possible constructors
      # {Dry::Struct} & {Dry::Struct::Union} is currently supported
      module Extensions
        refine Dry::Struct.singleton_class do
          # True only when the class is not abstract
          #
          # @return [Boolean]
          def constructor?
            abstract_class != self
          end
        end

        refine BasicObject do
          # Fallback type for non structs/union
          #
          # @return [Boolean]
          def constructor?
            false
          end
        end
      end
    end
  end
end
