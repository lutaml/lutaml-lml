# frozen_string_literal: true

module Lutaml
  module Lml
    module DataProcessor
      module InstanceProcessing
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
      end
    end
  end
end
