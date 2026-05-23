# frozen_string_literal: true

module Lutaml
  module Lml
    module DataProcessor
      def process_data(obj)
        case obj
        when Array
          obj.map { |item| process_data(item) }
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            result[key] = case key
                          when :requires
                            process_requires(value)
                          when :instances
                            process_instances(value)
                          when :instance
                            process_instance(value)
                          when :attributes
                            process_attributes(value)
                          else
                            process_data(value)
                          end
          end
        else
          obj
        end
      end

      def process_requires(obj)
        obj.map { |req| process_value(req).last }
      end

      def process_instances(obj)
        return [] unless obj.is_a?(Array)

        obj.each_with_object({}) do |instance, acc|
          acc[:instances] ||= []
          if instance.key?(:instance)
            acc[:instances] << process_instance(instance[:instance])
          elsif instance.key?(:collections)
            acc[:collections] = process_collections(instance[:collections])
          elsif instance.key?(:imports)
            acc[:imports] = process_imports(instance[:imports])
          elsif instance.key?(:exports)
            acc[:exports] = process_exports(instance[:exports])
          end
        end
      end

      def process_instance(hash)
        hash.each_with_object({}) do |(key, value), result|
          case key
          when :instance_type
            result[:type] = process_value(value).last
          when :instance
            result[:instance] = process_instance(value)
          when :attributes
            result[:attributes] = process_attributes(value)
          when :template
            result[:template] = process_attributes(value[:attributes])
          else
            result[key] = process_value(value).last
          end
        end
      end

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

        # Copy remaining keys that weren't explicitly handled
        obj.each do |key, value|
          next if %i[key value comments add attributes properties].include?(key)
          result[key] = value unless result.key?(key)
        end

        result
      end

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
