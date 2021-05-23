require "dry/struct/union"

module Fixtures
  class Base < Dry::Struct
    abstract
    schema schema.strict
  end

  module Types
    include Dry::Types()
  end

  module Weather
    include Dry::Struct.Union(include: [:Warm])

    MAX_TEMP = 274

    class Base < Base
      abstract
      attribute :temp, "integer"
    end

    class Cold < Base
      attribute :id, Types.Value(:cold)
    end

    class Warm < Base
      attribute :id, Types.Value(:warm)
    end
  end

  module Season
    include Dry::Struct::Union

    class Spring < Base
      attribute :id, Types.Value(:spring)
    end

    module Unused
      class Autum < Base
        attribute :id, Types.Value(:autum)
      end
    end
  end

  module Planet
    include Dry::Struct.Union(exclude: :Pluto)

    class Base < Base
      abstract
      attribute? :closest, Planet
      attribute? :season, Season
      attribute? :weather, Weather
    end

    class Pluto < Base
      attribute :id, Types.Value(:pluto)
    end

    class Earth < Base
      attribute :id, Types.Value(:earth)
    end

    class Mars < Base
      attribute :id, Types.Value(:mars)
    end
  end
end
