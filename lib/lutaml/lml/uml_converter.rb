# frozen_string_literal: true

require_relative "converter"

module Lutaml
  module Lml
    module UmlConverter
      include Converter

      MODEL_REGISTRY = {
        document: ::Lutaml::Uml::Document,
        package: ::Lutaml::Uml::Package,
        class: ::Lutaml::Uml::Class,
        enum: ::Lutaml::Uml::Enum,
        data_type: ::Lutaml::Uml::DataType,
        diagram: ::Lutaml::Uml::Diagram,
        attribute: ::Lutaml::Uml::TopElementAttribute,
        cardinality: ::Lutaml::Uml::Cardinality,
        association: ::Lutaml::Uml::Association,
        operation: ::Lutaml::Uml::Operation,
        constraint: ::Lutaml::Uml::Constraint,
        value: ::Lutaml::Uml::Value
      }.freeze

      def model_registry
        MODEL_REGISTRY
      end
    end
  end
end
