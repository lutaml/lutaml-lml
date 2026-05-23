# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module Definitions
          include Parslet

          # -- Class
          rule(:kw_class_modifier) { kw_abstract | kw_interface }

          rule(:class_modifier) do
            (kw_class_modifier.as(:modifier) >> spaces).maybe
          end
          rule(:class_keyword) { kw_class >> spaces }
          rule(:class_inner_definitions) do
            definition_body |
              ((str("attribute") >> spaces).absent? >> attribute_definition) |
              keyword_attribute_definition |
              comment_definition |
              comment_multiline_definition
          end
          rule(:class_inner_definition) do
            class_inner_definitions >> whitespace?
          end
          rule(:class_body) do
            spaces? >>
              str("{") >>
              whitespace? >>
              class_inner_definition.repeat.as(:members) >>
              str("}")
          end
          rule(:class_body?) { class_body.maybe }

          rule(:parent_class) do
            spaces? >> str("<") >> spaces? >> class_name_chars.as(:parent_class)
          end

          rule(:class_definition) do
            class_modifier >>
              class_keyword >>
              class_name.as(:name) >>
              parent_class.maybe >>
              spaces? >>
              attribute_keyword? >>
              class_body?
          end

          # -- Definition
          rule(:definition_body) do
            spaces? >>
              str("definition") >>
              whitespace? >>
              str("{") >>
              ((str("\\") >> any) | (str("}").absent? >> any))
                .repeat.maybe.as(:definition) >>
              str("}")
          end

          # -- Enum
          rule(:enum_keyword) { kw_enum >> spaces }
          rule(:enum_inner_definitions) do
            definition_body |
              attribute_definition |
              comment_definition |
              comment_multiline_definition
          end
          rule(:enum_inner_definition) do
            enum_inner_definitions >> whitespace?
          end
          rule(:enum_body) do
            spaces? >>
              str("{") >>
              whitespace? >>
              enum_inner_definition.repeat.as(:members) >>
              str("}")
          end
          rule(:enum_body?) { enum_body.maybe }
          rule(:enum_definition) do
            enum_keyword >>
              quotes? >>
              class_name.as(:name) >>
              quotes? >>
              attribute_keyword? >>
              enum_body?
          end

          # -- data_type
          rule(:data_type_keyword) { kw_data_type >> spaces }
          rule(:data_type_inner_definitions) do
            definition_body |
              attribute_definition |
              comment_definition |
              comment_multiline_definition
          end
          rule(:data_type_inner_definition) do
            data_type_inner_definitions >> whitespace?
          end
          rule(:data_type_body) do
            spaces? >>
              str("{") >>
              whitespace? >>
              data_type_inner_definition.repeat.as(:members) >>
              str("}")
          end
          rule(:data_type_body?) { data_type_body.maybe }
          rule(:data_type_definition) do
            data_type_keyword >>
              quotes? >>
              class_name.as(:name) >>
              quotes? >>
              attribute_keyword? >>
              data_type_body?
          end

          # -- primitive
          rule(:primitive_keyword) { kw_primitive >> spaces }
          rule(:primitive_definition) do
            primitive_keyword >>
              quotes? >>
              class_name.as(:name) >>
              quotes?
          end

          # -- Diagram
          rule(:diagram_keyword) { kw_diagram >> spaces? }
          rule(:diagram_inner_definitions) do
            title_definition |
              caption_definition |
              fontname_definition |
              class_definition.as(:classes) |
              enum_definition.as(:enums) |
              primitive_definition.as(:primitives) |
              data_type_definition.as(:data_types) |
              association_definition.as(:associations) |
              comment_definition |
              comment_multiline_definition
          end
          rule(:diagram_inner_definition) do
            diagram_inner_definitions >> whitespace?
          end
          rule(:diagram_body) do
            spaces? >>
              str("{") >>
              whitespace? >>
              diagram_inner_definition.repeat.as(:members) >>
              str("}")
          end
          rule(:diagram_definition) do
            diagram_keyword >>
              spaces? >>
              class_name.as(:name) >>
              diagram_body >>
              whitespace?
          end
          rule(:diagram_definitions) { diagram_definition >> whitespace? }

          # -- Metadata
          rule(:title_keyword) { kw_title >> spaces }
          rule(:title_text) do
            quotes? >>
              match['a-zA-Z0-9_\- ,.:;'].repeat(1).as(:title) >>
              quotes?
          end
          rule(:title_definition) { title_keyword >> title_text }
          rule(:caption_keyword) { kw_caption >> spaces }
          rule(:caption_text) do
            quotes? >>
              match['a-zA-Z0-9_\- ,.:;'].repeat(1).as(:caption) >>
              quotes?
          end
          rule(:caption_definition) { caption_keyword >> caption_text }

          rule(:fontname_keyword) { kw_fontname >> spaces }
          rule(:fontname_text) do
            quotes? >>
              match['a-zA-Z0-9_\- '].repeat(1).as(:fontname) >>
              quotes?
          end
          rule(:fontname_definition) { fontname_keyword >> fontname_text }
        end
      end
    end
  end
end
