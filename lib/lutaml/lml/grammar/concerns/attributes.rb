# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module Attributes
          include Parslet

          rule(:attribute_value) { key_value_map | value | match("[^\n]").repeat(1) }
          rule(:attribute) do
            comment_definition |
              variable.as(:key) >> spaces? >> str("+").as(:add).maybe >> str("=").maybe >> spaces? >> attribute_value.as(:value)
          end
          rule(:attributes) do
            (
              attribute_line | whitespace
            ).repeat.as(:attributes)
          end
          rule(:attribute_line) do
            spaces? >> attribute >> (str(",").maybe >> whitespace).maybe
          end
          rule(:member_static) { (kw_static.as(:static) >> spaces).maybe }
          rule(:visibility) do
            kw_visibility_modifier.as(:visibility_modifier)
          end
          rule(:visibility?) { visibility.maybe }

          rule(:method_abstract) { (kw_abstract.as(:abstract) >> spaces).maybe }
          rule(:attribute_keyword) do
            str("<<") >>
              match['a-zA-Z0-9_\-\/'].repeat(1).as(:keyword) >>
              str(">>")
          end
          rule(:attribute_keyword?) { attribute_keyword.maybe }
          rule(:attribute_type) do
            (str(":").maybe >>
              spaces? >>
              attribute_keyword? >>
              spaces? >>
              quotes? >>
              match['a-zA-Z0-9_\- \/\+'].repeat(1).as(:type) >>
              quotes? >>
              spaces?
            )
          end
          rule(:attribute_type?) do
            attribute_type.maybe
          end

          rule(:attribute_name) { match['a-zA-Z0-9_\-\/\+'].repeat(1).as(:name) }
          rule(:attribute_definition_name) do
            (quotes >> match['a-zA-Z0-9_\- \/\+'].repeat(1).as(:name) >> quotes) |
              attribute_name
          end

          rule(:attribute_definition) do
            (visibility?.as(:visibility) >>
              spaces? >>
              attribute_definition_name >>
              spaces? >>
              attribute_type? >>
              cardinality? >>
              class_body?)
              .as(:attributes)
          end

          rule(:keyword_type_argument) do
            (
              str("type") >>
                spaces? >>
                match["[^\s\n\r]"].repeat(1).as(:type) >>
                whitespace?
            )
          end

          rule(:keyword_cardinality_argument) do
            (
              str("cardinality") >>
                spaces? >>
                cardinality_body_definition.as(:cardinality) >>
                whitespace?
            )
          end

          rule(:keyword_any_argument) do
            (
              spaces? >>
                match("[^\s\n\r]").repeat(1).as(:name) >>
                spaces >>
                str("=").maybe >>
                spaces? >>
                attribute_value.as(:value) >>
                whitespace?
            )
          end

          rule(:keyword_attribute_options) do
            (
              keyword_type_argument |
                keyword_cardinality_argument |
                keyword_any_argument.as(:properties)
            ).repeat
          end

          rule(:keyword_attribute_body) do
            str("{") >>
              whitespace? >>
              keyword_attribute_options >>
              whitespace? >>
              str("}")
          end

          rule(:keyword_attribute_definition) do
            (
              str("attribute") >>
                spaces >>
                attribute_name >>
                spaces? >>
                keyword_attribute_body
            ).as(:attributes)
          end
        end
      end
    end
  end
end
