# frozen_string_literal: true

module Lutaml
  module Lml
    class DocumentBuilder
      # Default registry: builder keys → LML model classes.
      # Callers needing a different mapping can pass their own registry
      # to `new`; this constant documents the default composition.
      DEFAULT_REGISTRY = {
        document: ::Lutaml::Lml::Document,
        package: ::Lutaml::Lml::Package,
        class: ::Lutaml::Lml::UmlClass,
        enum: ::Lutaml::Lml::Enum,
        data_type: ::Lutaml::Lml::DataType,
        diagram: ::Lutaml::Lml::Diagram,
        attribute: ::Lutaml::Lml::TopElementAttribute,
        cardinality: ::Lutaml::Lml::Cardinality,
        association: ::Lutaml::Lml::Association,
        operation: ::Lutaml::Lml::Operation,
        constraint: ::Lutaml::Lml::Constraint,
        value: ::Lutaml::Lml::Value,
        view_import: ::Lutaml::Lml::ViewImport,
        view_filter: ::Lutaml::Lml::ViewFilter
      }.freeze

      attr_reader :registry

      def initialize(registry = DEFAULT_REGISTRY)
        @registry = registry
      end

      FACTORY_KEYS = %i[
        document package class enum data_type diagram view_import view_filter
        attribute association operation constraint value cardinality
      ].freeze

      MEMBER_KEY_MAP = {
        packages: :package,
        classes: :class,
        enums: :enum,
        data_types: :data_type,
        diagrams: :diagram,
        view_imports: :view_import,
        attributes: :attribute,
        associations: :association,
        operations: :operation,
        constraints: :constraint,
        values: :value
      }.freeze

      FACTORY_KEYS.each do |key|
        define_method(:"build_#{key}") { |hash| build(key, hash) }
      end

      def build(key, hash)
        @registry.fetch(key).new.tap { |model| set_model(model, hash) }
      end

      private

      def set_model(model, hash)
        hash = build_members(model, hash)
        set_model_attributes(model, hash)
      end

      def set_model_attributes(model, hash)
        hash.each do |key, value|
          value = sanitize_definition(value) if key == :definition
          apply_attribute(model, key, value)
        end
      end

      def build_members(model, hash)
        members = hash.delete(:members)
        members.to_a.each do |member_hash|
          add_members(model, member_hash)
          set_model_attributes(model, member_hash)
        end
        hash
      end

      def sanitize_definition(value)
        value.to_s.gsub(/\\}/, '}').gsub(/\\{/, '{')
             .split("\n").map(&:strip).join("\n")
      end

      def apply_attribute(model, key, value)
        return unless model.class.attributes.key?(key.to_sym)

        if model.class.attributes[key.to_sym].options[:collection]
          append_collection(model, key, value)
        else
          model.public_send("#{key}=", value)
        end
      end

      def append_collection(model, key, value)
        values = model.public_send(key).to_a
        value.is_a?(Array) ? values.concat(value) : values << value
        model.public_send("#{key}=", values)
      end

      def add_members(model, hash)
        MEMBER_KEY_MAP.each do |plural_key, singular_key|
          data = hash.delete(plural_key)
          next if data.nil?

          member = build(singular_key, data)
          ensure_collection(model, plural_key) << member
        end

        remap_filter_keys(hash, model)
      end

      def ensure_collection(model, key)
        model.public_send(key) || begin
          model.public_send("#{key}=", [])
          model.public_send(key)
        end
      end

      def remap_filter_keys(hash, model)
        return unless model.is_a?(Document)

        if hash.key?(:show_list)
          hash[:show_filter] = build_view_filter(hash.delete(:show_list))
        end
        if hash.key?(:hide_list)
          hash[:hide_filter] = build_view_filter(hash.delete(:hide_list))
        end
      end

      def build_view_filter(entity_names)
        names = entity_names.is_a?(Array) ? entity_names : [entity_names]
        ViewFilter.new(entity_names: names.map(&:to_s))
      end
    end
  end
end
