# frozen_string_literal: true

require "parslet"

module Lutaml
  module Lml
    module Grammar
      module Instances
        include Parslet

        INSTANCE_KEYWORDS = %w[
          collection
          condition
          export
          extends
          format
          import
          includes
          instance
          instances
          models
          require
          template
          validation
        ].freeze

        INSTANCE_KEYWORDS.each do |keyword|
          rule("kw_#{keyword}") { whitespace? >> str(keyword) }
        end

        # Override attribute_value to support lists (layer 2 feature)
        rule(:attribute_value) { list | key_value_map | value | match("[^\n]").repeat(1) }

        # === Lists ===
        rule(:list_item) { instance | value }
        rule(:list) do
          str("[") >> whitespace? >>
            (list_item >> spaces? >> str(",").maybe >> whitespace?).repeat.as(:list) >> whitespace? >>
            str("]")
        end

        # === Instance block ===
        rule(:instance) do
          keyword_instance | class_instance
        end

        rule(:keyword_instance) do
          (
            kw_instance >> spaces >>
            namespaced_identifier.as(:instance_type) >> spaces? >>
            str("{") >> whitespace? >>
            ((spaces? >> instance) | attributes) >>
            str("}")
          ).as(:instance) >> whitespace?
        end

        # === Models block ===
        rule(:models) do
          kw_models >> whitespace? >>
            variable.as(:name) >> whitespace? >> str("{") >>
            model_body.repeat.as(:members) >>
            str("}") >> whitespace?
        end

        rule(:model_body) do
          (class_definition.as(:classes) | enum_definition.as(:enums)) >> whitespace?
        end

        # === Collection block ===
        rule(:collection) do
          kw_collection >> spaces >> quoted_string.as(:name) >> spaces? >>
            str("{") >> whitespace? >>
            includes.maybe >> whitespace? >>
            validation.maybe >> whitespace? >>
            str("}") >> whitespace?
        end

        rule(:includes) do
          kw_includes >> spaces? >> list.as(:includes)
        end

        # === Validation block ===
        rule(:validation) do
          kw_validation >> spaces? >> str("{") >> whitespace? >>
            condition.repeat.as(:validations) >>
            str("}")
        end

        rule(:condition) do
          kw_condition >> spaces >> quoted_string.as(:condition) >> whitespace?
        end

        # === Import block ===
        rule(:import) do
          kw_import >> spaces? >> str("{") >> whitespace? >>
            import_definition.repeat.as(:imports) >>
          str("}") >> whitespace?
        end

        rule(:import_definition) do
          match("[^\s\n\r]").repeat(1).as(:format_type) >> spaces? >> quoted_string.as(:file) >> whitespace? >>
            str("{") >> whitespace? >>
            attributes >> whitespace? >>
            str("}") >> whitespace?
        end

        # === Instances block ===
        rule(:instances) do
          kw_instances >> whitespace? >>
            str("{") >> whitespace? >>
            instances_body.maybe >>
            str("}") >> whitespace?
        end

        rule(:instances_body) do
          (instances_member >> whitespace?).repeat.as(:instances)
        end

        rule(:instances_member) do
          import | collection.as(:collections) | export | instance
        end

        rule(:class_instance) do
          (variable.as(:instance_type) >> whitespace? >> quoted_string.as(:name) >> whitespace? >>
            (kw_extends >> whitespace? >> quoted_string.as(:parent) >> whitespace?).maybe >>
             str("{") >> whitespace? >>
            lml_instance_body.maybe >>
            str("}")).as(:instance) >> whitespace?
        end

        rule(:lml_instance_body) do
          (lml_instance_members >> whitespace?)
        end

        rule(:instance_template) do
          kw_template >> whitespace? >> str("{") >> whitespace? >>
            attributes >> whitespace? >>
            str("}") >> whitespace?
        end

        rule(:lml_instance_members) do
          instance_template.as(:template) | attributes
        end

        # === Export block ===
        rule(:export) do
          kw_export >> whitespace? >> str("{") >> whitespace? >>
            (export_format >> whitespace?).repeat.as(:exports) >>
            str("}") >> whitespace?
        end

        rule(:export_format) do
          kw_format >> spaces >> variable.as(:format_type) >> whitespace? >> str("{") >> whitespace? >>
            attributes >>
            str("}") >> whitespace?
        end

        # -- Root (Full: diagram + models + instances)
        rule(:diagram) { require_block? >> (models | diagram_definitions | instances | instance) }
      end
    end
  end
end
