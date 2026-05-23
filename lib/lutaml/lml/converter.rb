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

      private

      def add_members(model, hash)
        MEMBER_FACTORIES.each do |key, factory|
          data = hash.delete(key)
          next if data.nil?

          member = public_send(factory, data)
          collection = model.public_send(key)
          if collection.nil?
            model.public_send("#{key}=", [])
            collection = model.public_send(key)
          end
          collection << member
        end
      end

      def add_member(model, key, member)
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
