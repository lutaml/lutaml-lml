# frozen_string_literal: true

module Lutaml
  module Lml
    class DataType < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string, default: "dataType"
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From UmlClassifier
      attribute :is_abstract, :boolean, default: false

      # From DataType
      attribute :nested_classifier, :string, collection: true, default: -> { [] }
      attribute :type, :string
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :modifier, :string
      attribute :constraints, "Lutaml::Lml::Constraint", collection: true
      attribute :operations, "Lutaml::Lml::Operation", collection: true
      attribute :data_types, "Lutaml::Lml::DataType", collection: true
      attribute :associations, "Lutaml::Lml::Association", collection: true

      def self.entity_type
        :data_types
      end
    end
  end
end
