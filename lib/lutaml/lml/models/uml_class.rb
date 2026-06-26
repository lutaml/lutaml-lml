# frozen_string_literal: true

module Lutaml
  module Lml
    class UmlClass < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"
      attribute :comments, :string, collection: true

      # From UmlClassifier
      attribute :is_abstract, :boolean, default: false

      # From UmlClass
      attribute :nested_classifier, :string, collection: true, default: -> { [] }
      attribute :type, :string
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :modifier, :string
      attribute :constraints, "Lutaml::Lml::Constraint", collection: true
      attribute :operations, "Lutaml::Lml::Operation", collection: true
      attribute :data_types, "Lutaml::Lml::DataType", collection: true
      attribute :associations, "Lutaml::Lml::Association", collection: true

      # LML-specific
      attribute :parent_class, :string

      yaml do
        map "name", to: :name
        map "keyword", to: :keyword
        map "is_abstract", to: :is_abstract
        map "definition", to: :definition, with: {
          to: :definition_to_yaml, from: :definition_from_yaml
        }
        map "modifier", to: :modifier
        map "stereotype", to: :stereotype
        map "visibility", to: :visibility
        map "type", to: :type
        map "attributes", to: :attributes
        map "operations", to: :operations
        map "constraints", to: :constraints
        map "data_types", to: :data_types
        map "associations", to: :associations, with: {
          to: :associations_to_yaml, from: :associations_from_yaml
        }
      end

      def associations_to_yaml(model, doc)
        return unless model.associations

        associations = model.associations.map(&:to_hash)
        doc["associations"] = associations unless associations.empty?
      end

      def associations_from_yaml(model, values)
        associations = values.map do |value|
          value["owner_end"] = model.name if value["owner_end"].nil?
          Association.from_yaml(value.to_yaml)
        end

        model.associations = associations
      end

      def definition_to_yaml(model, doc)
        doc["definition"] = model.definition if model.definition
      end

      def definition_from_yaml(model, value)
        model.definition = value.to_s
          .gsub(/\\}/, "}")
          .gsub(/\\{/, "{")
          .split("\n")
          .map(&:strip)
          .join("\n")
      end

      def self.entity_type
        :classes
      end
    end
  end
end
