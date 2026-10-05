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
        view_filter: ::Lutaml::Lml::ViewFilter,
        mapping: ::Lutaml::Lml::Mapping,
        string_format: ::Lutaml::Lml::StringFormat,
        derived_field: ::Lutaml::Lml::DerivedField,
        member_field: ::Lutaml::Lml::MemberField
      }.freeze

      attr_reader :registry

      def initialize(registry = DEFAULT_REGISTRY)
        @registry = registry
      end

      FACTORY_KEYS = %i[
        document package class enum data_type diagram view_import view_filter
        attribute association operation constraint value cardinality mapping
        string_format derived_field
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
        values: :value,
        mappings: :mapping,
        member_fields: :member_field
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
        expand_declared_members(model, hash)
        expand_nested_members(model, hash)
        MEMBER_KEY_MAP.each do |plural_key, singular_key|
          data = hash.delete(plural_key)
          next if data.nil?

          member = build(singular_key, data)
          ensure_collection(model, plural_key) << member
        end

        remap_filter_keys(hash, model)
      end

      # RS 3001 §Value: the canonical `value` construct normalizes into
      # the same member shape the bare-identifier shortcut produces.
      def expand_value_declaration(model, hash)
        decl = hash.delete(:value_decl) or return
        apply_attribute(model, :attributes, decl.fetch(:attributes))
      end

      # The document root is a repetition of top-level constructs (RS 3001:
      # documents interleave declarations), so models/packages blocks nest
      # their members one level down; recurse into them.
      def expand_nested_members(model, hash)
        return unless hash.key?(:members)

        members = hash.delete(:members)
        members.to_a.each do |nested|
          add_members(model, nested)
          set_model_attributes(model, nested)
        end
      end

      # Declaration-level member hooks: single-line definitions, canonical
      # `value` members, mapping sections, class declarations, enum
      # member_fields and from_table all arrive as bare member hashes.
      def expand_declared_members(model, hash)
        expand_definition_text(model, hash)
        expand_value_declaration(model, hash)
        expand_mapping_section(model, hash)
        expand_class_declarations(model, hash)
        expand_enum_member_fields(model, hash)
        expand_from_table(model, hash)
      end

      # RS 3001 §Definition single-line form (`definition "text"`) arrives
      # as a quoted-string capture; unwrap it for the entity's definition.
      def expand_definition_text(model, hash)
        return unless hash.key?(:definition) && model.class.attributes.key?(:definition)

        model.definition = unquote(hash.delete(:definition))
      end

      # A mapping section arrives as a bare member hash
      # { format:, maps: [{ wire:, to: }] }; expand to one Mapping entry
      # per map line, each carrying the format, and strip the section keys
      def expand_mapping_section(model, hash)
        section = mapping_section_from(hash)
        return unless section

        section[:maps].to_a.each do |line|
          model.wire_mappings << build(:mapping,
                                       format: section[:format],
                                       wire: unquote(line[:wire]),
                                       to: unquote(line[:to]))
        end
      end

      def mapping_section_from(hash)
        return { format: unquote(hash[:format]), maps: hash.delete(:maps) } if hash.key?(:maps)

        hash.delete(:mappings)
      end

      # quoted_string captures nest their value under :string
      def unquote(value)
        value.is_a?(Hash) && value.key?(:string) ? value[:string] : value
      end

      # L5/L7 declaration members: string_format sections (class- or
      # models-level), derive lines, and enum member_fields blocks
      def expand_class_declarations(model, hash)
        if (section = hash.delete(:string_format))
          model.string_formats << build_string_format(section)
        end
        if (section = hash.delete(:default_string_formats))
          model.default_string_formats << build_string_format(section)
        end
        return unless (derived = hash.delete(:derived_field))

        model.derived_fields << build(:derived_field,
                                      name: derived[:name],
                                      type: unquote(derived[:type]))
      end

      # L7a: from_table declares the enum's members as an artifact table
      # { from_table_name:, from_table_artifact? } — expansion happens at
      # compile time (deterministic materialization, no runtime data dep)
      def expand_from_table(model, hash)
        decl = hash.delete(:from_table_decl)
        return unless decl && model.is_a?(Enum)

        # the members repetition splits the declaration across iteration
        # hashes (name part, artifact part) — merge the parts
        parts = decl.is_a?(Array) ? decl : [decl]
        decl = parts.each_with_object({}) do |part, acc|
          acc.merge!(part) { |_key, _old, new_val| new_val }
        end
        model.from_table_name = unquote(decl[:from_table_name])
        model.from_table_artifact = unquote(decl[:artifact_table]) if decl[:artifact_table]
      end

      def expand_enum_member_fields(model, hash)
        decl = hash.delete(:member_fields_decl)
        return unless decl && model.is_a?(Enum)

        decl[:member_fields].to_a.each do |field|
          model.member_fields << build(:member_field,
                                       name: field[:name],
                                       type: unquote(field[:member_field_type]))
        end
      end

      def build_string_format(section)
        items = section[:items].to_a.each_with_object({}) do |item, acc|
          acc[item[:key].to_sym] = unquote(item[:value])
        end
        build(:string_format,
              format: unquote(section[:format]),
              artifact: items[:artifact],
              root: items[:root])
      end

      def ensure_collection(model, key)
        model.public_send(key) || begin
          model.public_send("#{key}=", [])
          model.public_send(key)
        end
      end

      def remap_filter_keys(hash, model)
        return unless model.is_a?(Document)

        hash[:show_filter] = build_view_filter(hash.delete(:show_list)) if hash.key?(:show_list)
        return unless hash.key?(:hide_list)

        hash[:hide_filter] = build_view_filter(hash.delete(:hide_list))
      end

      def build_view_filter(entity_names)
        ViewFilter.new(entity_names: Array(entity_names).map(&:to_s))
      end
    end
  end
end
