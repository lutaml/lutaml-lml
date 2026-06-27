# frozen_string_literal: true

module Lutaml
  module Lml
    class ModelCompiler
      class ValidationError < Error; end

      TYPE_MAP = {
        "String" => :string,
        "Integer" => :integer,
        "Boolean" => :boolean,
        "Float" => :float,
        "Date" => :date,
        "date_time" => :date_time,
        "DateTime" => :date_time,
        "Time" => :time,
        "Uri" => :string,
        "Hash" => :hash,
      }.freeze

      def initialize(namespace: nil)
        @namespace = namespace
        @compiled = {}
        @forward_refs = {}
        @enum_names = Set.new
      end

      def compile(input)
        doc = Pipeline.call(input, resolve: false)
        compile_document(doc)
        @compiled
      end

      def hydrate(input)
        doc = input.is_a?(Document) ? input : Pipeline.call(input, resolve: false)
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
        doc = input.is_a?(Document) ? input : Pipeline.call(input, resolve: false)
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

      def validate_instance(instance, errors, path = "root")
        if instance.instance && Array(instance.attributes).empty?
          validate_instance(instance.instance, errors, "#{path}.instance")
          return
        end

        attrs = Array(instance.attributes)
        type_attr = attrs.find { |a| a.name == "type" }
        type_name = type_attr ? type_attr.value.to_s : instance.type
        klass = @compiled[type_name]
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

          if attr_def.collection? && attr.instances.any?
            attr.instances.each_with_index do |nested, i|
              validate_instance(nested, errors, "#{path}.#{attr.name}[#{i}]")
            end
          end
        end

        if instance.instance
          validate_instance(instance.instance, errors, "#{path}.instance")
        end
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
        type_attr = Array(instance.attributes).find { |a| a.name == "type" }
        raw = type_attr ? type_attr.value.to_s : instance.type.to_s
        demodulize(raw)
      end

      def demodulize(name)
        name.split("::").last.to_s
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

          hash[key] = resolve_instance_value(value, nested)
        end
      end

      def resolve_instance_value(value, nested)
        if nested.any?
          nested.map { |i| hydrate_instance(i) }
        elsif value.is_a?(Array)
          value
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
        register(name, compiled_klass)
      end

      alias_method :compile_data_type, :compile_class

      def compile_enum(enum_def)
        name = enum_def.name.to_s
        values = extract_enum_values(enum_def)

        compiled_klass = Class.new(Lutaml::Model::Serializable) do
          attribute :value, :string, default: values.first.to_s

          define_method(:to_s) { value }
        end

        values.each do |val|
          compiled_klass.define_singleton_method(val) do
            new(value: val.to_s)
          end
        end

        @enum_names << name
        register(name, compiled_klass)
      end

      # Builds a compiled Serializable subclass from a class or data-type
      # definition: declares attributes and stashes forward-referenced
      # attributes for post-registration resolution.
      def build_compiled_class(def_obj)
        all_attrs = build_attributes(def_obj)
        immediate, deferred = all_attrs.partition do |(_, raw_type, type, _)|
          type != :string || TYPE_MAP.key?(raw_type) || raw_type.start_with?("reference:(")
        end

        compiled_klass = Class.new(Lutaml::Model::Serializable) do
          immediate.each do |attr_name, _raw, type, options|
            attribute attr_name, type, options
          end
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
        elsif type_name.start_with?("reference:(")
          :string
        elsif @compiled.key?(type_name)
          @compiled[type_name]
        else
          :string
        end
      end

      def build_options(attr)
        options = {}
        card = attr.cardinality
        return options unless card

        min = parse_cardinality_value(card.min)
        max = parse_cardinality_value(card.max)

        if max && (max > 1 || max == Float::INFINITY)
          options[:collection] = true
        elsif max.nil? && min && min > 1
          options[:collection] = true
        elsif min == 0
          options[:default] = nil
        end
        options
      end

      def parse_cardinality_value(val)
        return nil if val.nil?
        return Float::INFINITY if val == "*" || val == "n"
        val.to_i
      end

      def extract_enum_values(enum_def)
        enum_def.attributes.map do |attr|
          attr.name.to_s
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
