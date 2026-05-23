# frozen_string_literal: true

require "lutaml/uml"

module Lutaml
  module Lml
    module Converter
      MEMBER_FACTORIES = {
        packages: :create_package,
        classes: :create_class,
        enums: :create_enum,
        data_types: :create_data_type,
        diagrams: :create_diagram,
        attributes: :create_attribute,
        associations: :create_association,
        operations: :create_operation,
        constraints: :create_constraint,
        values: :create_value
      }.freeze

      # Override in each converter module to map factory keys to model classes.
      # Must return a Hash with symbol keys and Class values.
      def model_registry
        raise NotImplementedError, "#{self.class}#model_registry must be implemented"
      end

      def set_model(model, hash)
        hash = build_members(model, hash)
        set_model_attribute(model, hash)
      end

      def set_model_attribute(model, hash)
        hash.each do |key, value|
          if key == :definition
            value = value.to_s.gsub(/\\}/, "}").gsub(/\\{/, "{")
              .split("\n").map(&:strip).join("\n")
          end

          next unless model.class.attributes.key?(key.to_sym)

          if model.class.attributes[key.to_sym].options[:collection]
            values = model.public_send(key).to_a
            value.is_a?(Array) ? values.concat(value) : values << value
            model.public_send("#{key}=", values)
          else
            model.public_send("#{key}=", value)
          end
        end
      end

      def build_members(model, hash)
        members = hash.delete(:members)
        members.to_a.each do |member_hash|
          member_hash.each do
            add_members(model, member_hash)
            set_model_attribute(model, member_hash)
          end
        end
        hash
      end

      def create_document(hash)
        model_registry[:document].new.tap { |m| set_model(m, hash) }
      end

      def create_package(hash)
        model_registry[:package].new.tap { |m| set_model(m, hash) }
      end

      def create_class(hash)
        model_registry[:class].new.tap { |m| set_model(m, hash) }
      end

      def create_enum(hash)
        model_registry[:enum].new.tap { |m| set_model(m, hash) }
      end

      def create_data_type(hash)
        model_registry[:data_type].new.tap { |m| set_model(m, hash) }
      end

      def create_diagram(hash)
        model_registry[:diagram].new.tap { |m| set_model(m, hash) }
      end

      def create_attribute(hash)
        model_registry[:attribute].new.tap { |m| set_model(m, hash) }
      end

      def create_operation(hash)
        model_registry[:operation].new.tap { |m| set_model(m, hash) }
      end

      def create_constraint(hash)
        model_registry[:constraint].new.tap { |m| set_model(m, hash) }
      end

      def create_value(hash)
        model_registry[:value].new.tap { |m| set_model(m, hash) }
      end

      def create_cardinality(hash)
        model_registry[:cardinality].new.tap do |c|
          c.min = hash[:min]
          c.max = hash[:max]
        end
      end

      def create_association(hash)
        model_registry[:association].new.tap { |m| set_model(m, hash) }
      end

      private

      def add_members(model, hash)
        MEMBER_FACTORIES.each do |key, factory|
          data = hash.delete(key)
          next if data.nil?

          member = public_send(factory, data)
          append_to_collection(model, key, member)
        end
      end

      def append_to_collection(model, key, member)
        collection = model.public_send(key)
        if collection.nil?
          model.public_send("#{key}=", [])
          collection = model.public_send(key)
        end
        collection << member
      end
    end
  end
end
