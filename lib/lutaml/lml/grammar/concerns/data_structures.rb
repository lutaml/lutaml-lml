# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module DataStructures
          include Parslet

          rule(:attribute_value) { list | key_value_map | value | match("[^\n]").repeat(1) }

          rule(:list_item) { instance | value }
          rule(:list) do
            str("[") >> whitespace? >>
              (list_item >> spaces? >> str(",").maybe >> whitespace?).repeat.as(:list) >> whitespace? >>
              str("]")
          end

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

          rule(:validation) do
            kw_validation >> spaces? >> str("{") >> whitespace? >>
              condition.repeat.as(:validations) >>
              str("}")
          end

          rule(:condition) do
            kw_condition >> spaces >> quoted_string.as(:condition) >> whitespace?
          end

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
        end
      end
    end
  end
end
