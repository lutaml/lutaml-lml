# frozen_string_literal: true

module Lutaml
  module Lml
    module Node
      class Document < Base
        attr_reader :classes

        def classes=(value)
          @classes = value.to_a.map { |attributes| ClassNode.new(attributes) }
        end
      end
    end
  end
end
