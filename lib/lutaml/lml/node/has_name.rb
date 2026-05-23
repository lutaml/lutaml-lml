# frozen_string_literal: true

module Lutaml
  module Lml
    module Node
      module HasName
        attr_reader :name

        def name=(value)
          @name = value.to_s
        end
      end
    end
  end
end
