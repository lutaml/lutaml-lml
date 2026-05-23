# frozen_string_literal: true

module Lutaml
  module Lml
    module DataProcessor
      module AttributeProcessing
        def process_attributes(obj)
          case obj
          when Array
            process_attributes_array(obj)
          when Hash
            process_attributes_hash(obj)
          end
        end

        def process_attributes_array(obj)
          if obj.all? { |e| e.is_a?(Hash) && e.keys.size == 1 }
            obj.each_with_object({}) do |item, hash|
              hash[:properties] ||= []
              if item.key?(:properties)
                hash[:properties] << process_attributes(item[:properties])
              else
                hash.merge!(process_attributes(item))
              end
            end
          else
            obj.map { |item| process_attributes(item) }
          end
        end

        def process_attributes_hash(obj)
          result = {}
          result[:name] = obj[:key] if obj.key?(:key)

          if obj.key?(:comments)
            result[:name] = "Comment"
            result[:value] = process_value(obj[:comments]).last
          elsif obj.key?(:value)
            result[:type], result[:value] = process_value(obj[:value])
          end

          if result[:type]&.start_with?("Instance")
            result[:instances] = Array(result.delete(:value))
            result.delete(:type)
          end

          result[:extended] = !!obj[:add] if obj.key?(:add)

          result[:attributes] = process_attributes(obj[:attributes]) if obj.key?(:attributes)
          result[:properties] = process_attributes(obj[:properties]) if obj.key?(:properties)

          obj.each do |key, value|
            next if %i[key value comments add attributes properties].include?(key)
            result[key] = value unless result.key?(key)
          end

          result
        end
      end
    end
  end
end
