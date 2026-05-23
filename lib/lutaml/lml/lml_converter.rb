# frozen_string_literal: true

require_relative "converter"
require_relative "models/document"

module Lutaml
  module Lml
    module LmlConverter
      include Converter

      MODEL_REGISTRY = {
        document: ::Lutaml::Lml::Document,
        package: ::Lutaml::Lml::Package,
        class: ::Lutaml::Lml::Class,
        enum: ::Lutaml::Lml::Enum,
        data_type: ::Lutaml::Lml::DataType,
        diagram: ::Lutaml::Uml::Diagram,
        attribute: ::Lutaml::Lml::TopElementAttribute,
        cardinality: ::Lutaml::Lml::Cardinality,
        association: ::Lutaml::Lml::Association,
        operation: ::Lutaml::Lml::Operation,
        constraint: ::Lutaml::Lml::Constraint,
        value: ::Lutaml::Lml::Value
      }.freeze

      def model_registry
        MODEL_REGISTRY
      end
    end
  end
end
