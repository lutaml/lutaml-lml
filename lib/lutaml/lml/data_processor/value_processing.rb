# frozen_string_literal: true

module Lutaml
  module Lml
    module DataProcessor
      module ValueProcessing
        def process_value(value)
          return [] if value.nil?

          if value.is_a?(Hash)
            process_hash_value(value)
          elsif value.is_a?(Array)
            process_array_value(value)
          else
            [value.class.to_s, value]
          end
        end

        private

        def process_hash_value(value)
          if value.key?(:instance)
            ["Instance", process_instance(value[:instance])]
          elsif value.key?(:list)
            process_list_value(value[:list])
          elsif value.key?(:string)
            ["String", value[:string]]
          elsif value.key?(:boolean)
            ["Boolean", value[:boolean] == "true"]
          elsif value.key?(:key_value_map)
            process_key_value_map(value[:key_value_map])
          elsif value.key?(:number)
            ["Number", value[:number].to_i]
          elsif value.key?(:condition)
            process_value(value[:condition])
          elsif value.key?(:require)
            process_value(value[:require])
          else
            ["Hash", value]
          end
        end

        def process_list_value(list)
          type = "String"
          values = list.map do |item|
            item_type, item_value = process_value(item)
            type = item_type
            item_value
          end
          ["#{type}[]", values]
        end

        def process_array_value(value)
          type = "String"
          values = value.map do |item|
            item_type, item_value = process_value(item)
            type = item_type
            item_value
          end
          ["#{type}[]", values]
        end

        def process_key_value_map(kv_map)
          result = kv_map.each_with_object({}) do |kv, h|
            key, value = kv.values_at(:key, :value)
            h[key.to_sym] = process_value(value).last
          end
          ["Hash", result]
        end
      end
    end
  end
end
