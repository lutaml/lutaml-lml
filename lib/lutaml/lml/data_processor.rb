# frozen_string_literal: true

require_relative "data_processor/value_processing"
require_relative "data_processor/attribute_processing"
require_relative "data_processor/instance_processing"
require_relative "data_processor/collection_processing"

module Lutaml
  module Lml
    module DataProcessor
      include ValueProcessing
      include AttributeProcessing
      include InstanceProcessing
      include CollectionProcessing

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
    end
  end
end
