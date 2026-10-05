# frozen_string_literal: true

require 'json'

module Lutaml
  module Lml
    class ModelCompiler
      class ValidationError < Error; end

      TYPE_MAP = {
        'String' => :string,
        'Integer' => :integer,
        'Boolean' => :boolean,
        'Float' => :float,
        'Date' => :date,
        'date_time' => :date_time,
        'DateTime' => :date_time,
        'Time' => :time,
        'Uri' => :string
      }.freeze

      # Tokens that denote unbounded cardinality in LML attribute
      # declarations. Anything else must parse as an Integer.
      UNBOUNDED_TOKENS = %w[* n N unbounded].freeze

      def initialize(namespace: nil, artifact_paths: {}, default_artifact: nil)
        @namespace = namespace
        @artifact_paths = artifact_paths
        @default_artifact = default_artifact
        @compiled = {}
        @forward_refs = {}
        @enum_names = Set.new
        @enum_classes = {}
      end

      def compile(input)
        doc = Lutaml::Lml.parse_document(input)
        compile_document(doc)
        @compiled
      end

      def hydrate(input)
        doc = input.is_a?(Document) ? input : Lutaml::Lml.parse_document(input)
        compile_document(doc) unless @compiled.any?
        return {} unless doc.instance

        hydrate_instance(doc.instance)
      end

      def compiled_classes
        @compiled
      end

      # Validate an instances document against compiled models.
      #
      # Accepts the instances input as a String, IO, StringIO, or a
      # pre-parsed Document. If +compiled:+ is supplied, that registry is
      # used; otherwise models are compiled from the same input (which
      # must therefore contain a models section).
      #
      # Returns an array of validation error strings (empty if all pass).
      def validate(input, compiled: nil)
        doc = input.is_a?(Document) ? input : Lutaml::Lml.parse_document(input)
        if compiled
          @compiled = compiled
        else
          compile_document(doc)
        end

        errors = []
        validate_instance(doc.instance, errors) if doc.instance
        errors
      end

      private

      def validate_instance(instance, errors, path = 'root')
        if instance.instance && Array(instance.attributes).empty?
          validate_instance(instance.instance, errors, "#{path}.instance")
          return
        end

        attrs = Array(instance.attributes)
        type_attr = attrs.find { |a| a.name == 'type' }
        type_name = type_attr ? type_attr.value.to_s : instance.type
        klass = @compiled[demodulize(type_name)]
        unless klass
          errors << "#{path}: unknown type '#{type_name}'"
          return
        end

        schema_attrs = klass.attributes.keys.map(&:to_s)
        present_attrs = attrs.map(&:name)
        schema_set = schema_attrs.to_set
        present_set = present_attrs.to_set

        unknown = present_set - schema_set - Set.new(%w[type])
        unknown.each do |name|
          errors << "#{path}.#{name}: attribute not defined on #{type_name}"
        end

        required = klass.attributes.select do |_k, v|
          !v.collection? && !v.options.key?(:default)
        end.keys.map(&:to_s).to_set

        missing = required - present_set
        missing.each do |name|
          errors << "#{path}.#{name}: required attribute missing (cardinality min >= 1)"
        end

        attrs.each do |attr|
          next unless schema_attrs.include?(attr.name)

          attr_def = klass.attributes[attr.name.to_sym]
          next unless attr_def

          next unless attr_def.collection? && attr.instances.any?

          attr.instances.each_with_index do |nested, i|
            validate_instance(nested, errors, "#{path}.#{attr.name}[#{i}]")
          end
        end

        return unless instance.instance

        validate_instance(instance.instance, errors, "#{path}.instance")
      end

      def hydrate_instance(instance)
        inner = instance.instance
        return hydrate_instance(inner) if inner && Array(instance.attributes).empty?

        type_name = resolve_instance_type(instance)
        klass = @compiled[type_name]
        return hydrate_as_untyped(instance, type_name) unless klass

        attrs = extract_instance_attributes(instance, klass)
        klass.new(**attrs)
      end

      def resolve_instance_type(instance)
        # L6: the explicit isa keyword is the type override; a `type`
        # attribute is ordinary data (pubid's identifier-kind field)
        return demodulize(instance.isa.to_s) if instance.isa

        demodulize(instance.type.to_s)
      end

      def demodulize(name)
        name.split('::').last.to_s
      end

      def hydrate_as_untyped(instance, type_name)
        { _name: type_name, **extract_raw_attributes(instance) }
      end

      def extract_raw_attributes(instance)
        instance.each_attribute.each_with_object({}) do |(name, value, nested), hash|
          hash[name.to_sym] = resolve_instance_value(value, nested)
        end
      end

      def extract_instance_attributes(instance, klass)
        schema_keys = klass.attributes.keys.to_set
        instance.each_attribute.each_with_object({}) do |(name, value, nested), hash|
          key = name.to_sym
          next unless schema_keys.include?(key)

          hash[key] = resolve_instance_value(value, nested, klass.attributes[key])
        end
      end

      def resolve_instance_value(value, nested, attr_def = nil)
        if nested.any?
          nested.map { |i| hydrate_instance(i) }
        elsif value.is_a?(Array)
          value
        elsif (enum_class = attr_def && enum_class_for(attr_def.type))
          value_name = enum_value_name(value.to_s)
          description = enum_class.values
                                  .find { |v| v.name == value_name }&.description
          enum_class.new(value: value_name, description: description)
        elsif !value.nil?
          value
        end
      end

      def compile_document(doc)
        doc.classes.each { |c| compile_class(c) }
        doc.enums.each { |e| compile_enum(e) }
        doc.data_types.each { |dt| compile_data_type(dt) }
        resolve_forward_references
        apply_xml_mappings
        register_string_formats(doc)
      end

      def resolve_forward_references
        @forward_refs.each do |class_name, deferred_attrs|
          klass = @compiled[class_name]
          next unless klass

          deferred_attrs.each do |attr_name, raw_type, _type, options|
            resolved = resolve_type(raw_type)
            klass.attribute attr_name, resolved, **options
          end
        end
      end

      def compile_class(klass_def)
        name = klass_def.name.to_s
        compiled_klass = build_compiled_class(klass_def)
        apply_declared_mappings(compiled_klass, klass_def)
        declare_derived_fields(compiled_klass, klass_def)
        register(name, compiled_klass)
      end

      # Emit the lutaml-model mapping blocks declared in the LML source:
      #   mapping yaml { map "full-name", to: "name" }
      # becomes klass.yml do |m| m.map "full-name", to: :name end
      def apply_declared_mappings(compiled_klass, def_obj)
        return unless def_obj.is_a?(UmlClass) || def_obj.is_a?(DataType)

        def_obj.wire_mappings.to_a.group_by(&:format).each do |format, entries|
          next unless format && Lutaml::Model::FormatRegistry.registered?(format.to_sym)

          compiled_klass.public_send(format) do |mapping|
            entries.each { |entry| mapping.map(entry.wire, to: entry.to.to_sym) }
          end
        end
      end

      alias compile_data_type compile_class

      EnumValue = Struct.new(:name, :description, :payload)

      def compile_enum(enum_def)
        name = enum_def.name.to_s
        expand_from_table(enum_def)
        values = extract_enum_values(enum_def)

        payload_fields = Array(enum_def.member_fields).map(&:name).map(&:to_s)
        compiled_klass = Class.new(Lutaml::Model::Serializable) do
          attribute :value, :string, default: values.first.name
          attribute :description, :string
          payload_fields.each do |field|
            attribute field.to_sym, :string
          end

          define_method(:to_s) { value }
        end

        values.each do |value|
          compiled_klass.define_singleton_method(value.name) do
            new({ value: value.name, description: value.description }.merge(value.payload || {}))
          end
        end
        compiled_klass.define_singleton_method(:values) { values }

        @enum_names << name
        @enum_classes[name] = compiled_klass
        register(name, compiled_klass)
      end

      # Builds a compiled Serializable subclass from a class or data-type
      # definition: declares attributes and stashes forward-referenced
      # attributes for post-registration resolution.
      def build_compiled_class(def_obj)
        all_attrs = build_attributes(def_obj)
        immediate, deferred = all_attrs.partition do |(_, raw_type, type, _)|
          type != :string || TYPE_MAP.key?(raw_type) || raw_type.start_with?('reference:(')
        end

        compiled_klass = Class.new(Lutaml::Model::Serializable) do
          immediate.each do |attr_name, _raw, type, options|
            attribute attr_name, type, options
          end
        end
        render_nil_map = Array(def_obj.attributes).to_h do |a|
          [a.name.to_sym, declared_render_nil(a)]
        end.compact
        unless render_nil_map.empty?
          compiled_klass.class_eval do
            @lml_render_nil = render_nil_map

            class << self
              attr_reader :lml_render_nil
            end
          end
          apply_render_nil_mappings(compiled_klass, render_nil_map)
        end

        name = def_obj.name.to_s
        @forward_refs[name] = deferred unless deferred.empty?
        compiled_klass
      end

      # Apply a lutaml-model XML mapping to each compiled class so they
      # support from_xml/to_xml. Runs after forward references are resolved
      # so all attributes (immediate + deferred) get element mappings.
      def apply_xml_mappings
        @compiled.each do |name, klass|
          next if @enum_names.include?(name)

          apply_xml_mapping(klass, name)
        end
      end

      def apply_xml_mapping(klass, root_name)
        attr_names = klass.attributes.keys
        return if attr_names.empty?

        klass.xml do |mapping|
          mapping.root(root_name)
          attr_names.each do |attr_name|
            mapping.map_element(attr_name.to_s, to: attr_name)
          end
        end
      end

      def build_attributes(klass_def)
        Array(klass_def.attributes).map do |attr|
          attr_name = attr.name.to_sym
          raw_type = attr.type.to_s
          type = resolve_type(raw_type)
          options = build_options(attr)
          [attr_name, raw_type, type, options]
        end
      end

      def resolve_type(type_name)
        if TYPE_MAP.key?(type_name)
          TYPE_MAP[type_name]
        elsif type_name.start_with?('reference:(')
          :string
        elsif @compiled.key?(type_name)
          @compiled[type_name]
        else
          :string
        end
      end

      def build_options(attr)
        declared = declared_attribute_options(attr)
        options = {}
        card = attr.cardinality
        unless card
          # LML attributes without an explicit cardinality are optional (0..1)
          options[:default] = declared[:default]
          return options
        end

        min = parse_cardinality_value(card.min)
        max = parse_cardinality_value(card.max)

        if max && (max > 1 || max == Float::INFINITY)
          options[:collection] = true
        elsif max.nil? && min && min > 1
          options[:collection] = true
        elsif min.zero?
          options[:default] = nil
        end
        # a declared default literal wins over the absent-marker
        options[:default] = declared[:default] if declared.key?(:default)
        options
      end

      # L7b: default <literal> and render_nil true|false ride the
      # keyword-attribute properties (bare name-value lines). Defaults
      # fire only on ABSENT input; render_nil mirrors lutaml-model.
      def declared_attribute_options(attr)
        options = {}
        Array(attr.properties).each do |prop|
          next unless prop.name.to_s == 'default'

          value = prop.value
          value = value[:string] if value.is_a?(Hash) && value.key?(:string)
          options[:default] = value&.to_s
        end
        options
      end

      # render_nil is a lutaml-model MAPPING option, not an attribute
      # option: collect the declaration for the mapping passes
      def declared_render_nil(attr)
        Array(attr.properties).find do |prop|
          prop.name.to_s == 'render_nil'
        end&.then { |prop| prop.value.to_s == 'true' }
      end

      def parse_cardinality_value(val)
        return nil if val.nil?
        return Float::INFINITY if UNBOUNDED_TOKENS.include?(val.to_s)
        return val.to_i if val.to_s.match?(/\A\d+\z/)

        raise ValidationError, "Unrecognized cardinality token: #{val.inspect}"
      end

      # L7a point 3: from_table members are baked at compile time — the
      # artifact table's rows become the values, validated against the
      # declared member_fields (unknown field = error; missing = nil).
      # The member name comes from the row's "name" column.
      def expand_from_table(enum_def)
        return unless enum_def.from_table_name

        rows = artifact_table_rows(enum_def)
        known = Array(enum_def.member_fields).map { |f| f.name.to_s }
        rows.each do |row|
          row = row.transform_keys(&:to_s)
          member_name = row.fetch('name')
          unknown = row.keys - known - ['name']
          if unknown.any?
            raise ArgumentError,
                  "enum #{enum_def.name}: table row #{member_name.inspect} has " \
                  "undeclared fields #{unknown.inspect} (declared: #{known.inspect})"
          end
          payload = row.slice(*known).compact
          enum_def.attributes << TopElementAttribute.new(
            name: member_name,
            properties: payload.map do |field, value|
              TopElementAttribute.new(name: field, value: value)
            end
          )
        end
      end

      def artifact_table_rows(enum_def)
        reference = enum_def.from_table_artifact || @default_artifact
        path = artifact_path_for(reference.to_s)
        unless path
          raise ArgumentError,
                "enum #{enum_def.name}: from_table artifact #{reference.inspect} not found"
        end

        envelope = JSON.parse(File.read(path))
        table = envelope['tables'].to_h[enum_def.from_table_name]
        unless table
          raise ArgumentError,
                "enum #{enum_def.name}: table #{enum_def.from_table_name.inspect} " \
                "not found in artifact #{reference.inspect}"
        end

        table['rows'].to_a
      end

      def extract_enum_values(enum_def)
        member_fields = Array(enum_def.member_fields).map do |f|
          [f.name.to_s, f.type.to_s]
        end
        enum_def.attributes.map do |attr|
          description = Array(attr.attributes).find do |nested|
            nested.name == 'description'
          end
          payload = extract_member_payload(attr)
          validate_member_payload(enum_def, attr, payload, member_fields)
          EnumValue.new(attr.name.to_s, description&.type, payload)
        end
      end

      # L7a: per-member payload lines ride the keyword-attribute
      # properties (`abbreviation = "WD"`)
      def extract_member_payload(attr)
        Array(attr.properties).to_h { |p| [p.name.to_s, p.value&.to_s] }
      end

      def validate_member_payload(enum_def, attr, payload, member_fields)
        known = member_fields.map(&:first)
        unknown = payload.keys - known
        return unless unknown.any?

        raise ArgumentError,
              "enum #{enum_def.name}: member #{attr.name} has undeclared " \
              "payload fields #{unknown.inspect} (declared: #{known.inspect})"
      end

      def enum_class_for(type)
        type.is_a?(Class) && @enum_classes.value?(type) and return type
      end

      def enum_value_name(raw)
        raw.split('::').last
      end

      # L7b: derived fields declare existence + type; computation is
      # bound by the binder from artifact derive specs. The attribute
      # participates in mappings like any other (relaton consumes URNs
      # from model JSON).
      def declare_derived_fields(compiled_klass, def_obj)
        return unless def_obj.is_a?(UmlClass) || def_obj.is_a?(DataType)

        derived = Array(def_obj.derived_fields)
        return if derived.empty?

        compiled_klass.class_eval do
          @lml_derived_fields = derived.map(&:name).map(&:to_sym)
          def self.derived_fields
            @lml_derived_fields
          end
        end
        derived.each do |field|
          compiled_klass.attribute field.name.to_sym, resolve_type(field.type.to_s)
        end
      end

      # L5: register grammar-backed string formats. Class-level
      # declarations win; a models-block default applies to classes
      # without their own. Artifact resolution: the compiler's
      # artifacts map (name => path), else the string as a path.
      def register_string_formats(doc)
        defaults = doc.packages.flat_map(&:default_string_formats)
        doc.classes.each do |class_def|
          declared = Array(class_def.string_formats)
          declared.each { |fmt| register_string_format(class_def.name.to_s, fmt) }

          declared_formats = declared.map(&:format)
          defaults.reject { |fmt| declared_formats.include?(fmt.format) }
                  .each { |fmt| register_string_format(class_def.name.to_s, fmt) }
        end
      end

      def register_string_format(class_name, fmt)
        artifact_path = artifact_path_for(fmt.artifact.to_s)
        return unless artifact_path

        compiled = @compiled[class_name]
        return unless compiled

        Parsanol::PARG::Lutaml.register(compiled,
                                        format_name: fmt.format.to_sym,
                                        artifact: artifact_path,
                                        entry: fmt.root.to_s)
      end

      def artifact_path_for(reference)
        mapped = @artifact_paths && @artifact_paths[reference]
        return mapped if mapped && File.exist?(mapped.to_s)
        return reference if File.exist?(reference)

        nil
      end

      # Emit KV mappings carrying render_nil for the declared
      # attributes (yaml/json round-trips honor them)
      def apply_render_nil_mappings(compiled_klass, render_nil_map)
        %i[yaml json].each do |fmt|
          compiled_klass.public_send(fmt) do |mapping|
            render_nil_map.each do |name, flag|
              mapping.map name.to_s, to: name, render_nil: flag
            end
          end
        end
      end

      def register(name, klass)
        @compiled[name] = klass
        return unless @namespace

        @namespace.const_set(name, klass)
      end
    end
  end
end
