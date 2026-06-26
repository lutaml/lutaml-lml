# frozen_string_literal: true

module Lutaml
  module Lml
    module Format
      module Adapter
        class Mapping < Lutaml::KeyValue::Mapping
          def initialize
            super(:lml)
          end

          def dup_instance
            self.class.new
          end
        end
      end
    end
  end
end
