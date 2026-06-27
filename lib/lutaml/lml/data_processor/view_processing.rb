# frozen_string_literal: true

module Lutaml
  module Lml
    class DataProcessor
      module ViewProcessing
        def process_show_list(data)
          extract_entity_names(data)
        end

        def process_hide_list(data)
          extract_entity_names(data)
        end

        private

        def extract_entity_names(data)
          return data.map { |d| extract_entity_names(d) } if data.is_a?(Array)
          return data[:entity_name].to_s if data.is_a?(Hash) && data.key?(:entity_name)
          data.to_s
        end
      end
    end
  end
end
