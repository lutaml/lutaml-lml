# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module InstanceRules
          include Parslet

          rule(:instance) do
            keyword_instance | class_instance
          end

          rule(:keyword_instance) do
            (
              kw_instance >> (spaces >> namespaced_identifier.as(:instance_type)).maybe >> spaces? >>
              str("{") >> whitespace? >>
              ((spaces? >> instance) | attributes) >>
              str("}")
            ).as(:instance) >> whitespace?
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

          rule(:models) do
            kw_models >> whitespace? >>
              variable.as(:name) >> whitespace? >> str("{") >>
              model_body.repeat.as(:members) >>
              str("}") >> whitespace?
          end

          rule(:model_body) do
            (class_definition.as(:classes) | enum_definition.as(:enums)) >> whitespace?
          end
        end
      end
    end
  end
end
