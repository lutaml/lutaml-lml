# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module Primitives
          include Parslet

          rule(:quotes) { match['"\''] }
          rule(:quotes?) { quotes.maybe }
          rule(:space) { match("\s") }
          rule(:spaces) { space.repeat(1) }
          rule(:spaces?) { spaces.maybe }
          rule(:whitespace) do
            (space | match("	") | match("\r?\n") | match("\r") | str(";"))
              .repeat(1)
          end
          rule(:whitespace?) { whitespace.maybe }
          rule(:newline) { match('[\r\n]') }

          rule(:quoted_string) do
            str('"') >> (str('"').absent? >> any).repeat.as(:string) >> str('"')
          end
          rule(:boolean) { (str("true") | str("false")).as(:boolean) }
          rule(:number) { match("[0-9]").repeat(1).as(:number) }
          rule(:variable) { (quoted_string | match("[a-zA-Z0-9_]").repeat(1)) }
          rule(:reference) do
            str("reference:(") >>
              (variable >> (str(".") >> variable).repeat).as(:reference) >>
              str(")")
          end
          rule(:range) do
            (variable.as(:start) >> str("..") >> variable.as(:end)).as(:range)
          end
          rule(:namespaced_identifier) do
            variable >> (str("::") >> variable).repeat
          end
          rule(:comment_definition) do
            spaces? >> (str("**") | str("#")) >> (newline.absent? >> any).repeat.as(:comments)
          end
          rule(:comment_multiline_definition) do
            spaces? >> str("*|") >> (str("|*").absent? >> any)
              .repeat.as(:comments) >> whitespace? >> str("|*")
          end
          rule(:class_name_chars) { match('(?:[a-zA-Z0-9 _-]|\:|\.)').repeat(1) }
          rule(:class_name) do
            class_name_chars >>
              (str("(") >>
                class_name_chars >>
                str(")")).maybe
          end
          rule(:cardinality_body_definition) do
            match['0-9a-z\*'].as("min") >>
              str("..").maybe >>
              match['0-9a-z\*'].as("max").maybe
          end
          rule(:cardinality) do
            str("[") >>
              cardinality_body_definition.as(:cardinality) >>
              str("]")
          end
          rule(:cardinality?) { cardinality.maybe }

          rule(:value) do
            boolean |
              reference |
              range |
              number |
              quoted_string
          end

          rule(:key_value_pair) do
            variable.as(:key) >> spaces >> str("=").maybe >> spaces? >> value.as(:value)
          end
          rule(:key_value_map) do
            str("{") >> whitespace? >>
              (key_value_pair >> whitespace).repeat.as(:key_value_map) >>
              str("}")
          end

          rule(:kw_visibility_modifier) do
            str("+") | str("-") | str("#") | str("~")
          end
        end
      end
    end
  end
end
