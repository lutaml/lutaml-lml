# frozen_string_literal: true

module Lutaml
  module Lml
    module DataProcessor
      module CollectionProcessing
        def process_collections(obj)
          obj.each_with_object({}) do |(key, value), result|
            result[key] = process_value(value).last
          end
        end

        def process_imports(obj)
          obj.map do |item|
            item.each_with_object({}) do |(key, value), result|
              result[key] = if key == :attributes
                              process_attributes(value)
                            else
                              process_value(value).last
                            end
            end
          end
        end

        def process_exports(obj)
          obj.map do |item|
            item.each_with_object({}) do |(key, value), result|
              result[key] = if key == :attributes
                              process_attributes(value)
                            else
                              process_value(value).last
                            end
            end
          end
        end
      end
    end
  end
end
