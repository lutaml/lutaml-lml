# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module Associations
          include Parslet

          rule(:association_keyword) { kw_association >> spaces }

          %w[owner member].each do |association_end_type|
            rule("#{association_end_type}_cardinality") do
              spaces? >>
                str("[") >>
                cardinality_body_definition
                  .as("#{association_end_type}_end_cardinality") >>
                str("]")
            end
            rule("#{association_end_type}_cardinality?") do
              public_send(:"#{association_end_type}_cardinality").maybe
            end
            rule("#{association_end_type}_attribute_name") do
              str("#") >>
                visibility? >>
                spaces? >>
                variable.as("#{association_end_type}_end_attribute_name") >>
                spaces?
            end
            rule("#{association_end_type}_attribute_name?") do
              public_send(:"#{association_end_type}_attribute_name").maybe
            end
            rule("#{association_end_type}_definition") do
              public_send(:"kw_#{association_end_type}") >>
                spaces >>
                variable.as("#{association_end_type}_end") >>
                public_send(:"#{association_end_type}_attribute_name?") >>
                public_send(:"#{association_end_type}_cardinality?")
            end
            rule("#{association_end_type}_type") do
              public_send(:"kw_#{association_end_type}_type") >>
                spaces >>
                variable.as("#{association_end_type}_end_type")
            end
          end

          rule(:association_inner_definitions) do
            owner_type |
              member_type |
              owner_definition |
              member_definition |
              comment_definition |
              comment_multiline_definition
          end
          rule(:association_inner_definition) do
            association_inner_definitions >> whitespace?
          end
          rule(:association_body) do
            spaces? >>
              str("{") >>
              whitespace? >>
              association_inner_definition.repeat.as(:members) >>
              str("}")
          end
          rule(:association_definition) do
            association_keyword >>
              spaces? >>
              variable.as(:name).maybe >>
              spaces? >>
              association_body
          end
        end
      end
    end
  end
end
