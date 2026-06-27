# frozen_string_literal: true

module Lutaml
  module Lml
    class DataProcessor
      module AttributeProcessing
        EXCLUDED_PASS_THROUGH_KEYS = %i[key value comments add attributes properties].freeze

        def process_attributes(obj)
          case obj
          when Array then process_attributes_array(obj)
          when Hash then process_attributes_hash(obj)
          end
        end

        def process_attributes_array(obj)
          return obj.map { |item| process_attributes(item) } unless single_key_hashes?(obj)

          obj.each_with_object({}) do |item, hash|
            hash[:properties] ||= []
            if item.key?(:properties)
              hash[:properties] << process_attributes(item[:properties])
            else
              hash.merge!(process_attributes(item))
            end
          end
        end

        def process_attributes_hash(obj)
          result = extract_name_and_value(obj)
          convert_instance_type(result)
          result[:extended] = !obj[:add].nil? if obj.key?(:add)
          apply_nested_attributes(result, obj)
          apply_remaining_keys(result, obj)
          result
        end

        private

        def single_key_hashes?(arr)
          arr.all? { |e| e.is_a?(Hash) && e.keys.size == 1 }
        end

        def extract_name_and_value(obj)
          result = {}
          result[:name] = obj[:key] if obj.key?(:key)

          if obj.key?(:comments)
            result[:name] = 'Comment'
            result[:value] = process_value(obj[:comments]).last
          elsif obj.key?(:value)
            result[:type], result[:value] = process_value(obj[:value])
          end

          result
        end

        def convert_instance_type(result)
          return unless result[:type]&.start_with?('Instance')

          value = result.delete(:value)
          result[:instances] = value.is_a?(Array) ? value : [value]
          result.delete(:type)
        end

        def apply_nested_attributes(result, obj)
          result[:attributes] = process_attributes(obj[:attributes]) if obj.key?(:attributes)
          result[:properties] = process_attributes(obj[:properties]) if obj.key?(:properties)
        end

        def apply_remaining_keys(result, obj)
          obj.each do |key, value|
            next if EXCLUDED_PASS_THROUGH_KEYS.include?(key)

            result[key] = value unless result.key?(key)
          end
        end
      end
    end
  end
end
