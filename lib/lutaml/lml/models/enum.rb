# frozen_string_literal: true

module Lutaml
  module Lml
    class Enum < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string, default: "enumeration"
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From UmlClassifier
      attribute :is_abstract, :boolean, default: false

      # From Enum
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true,
                                                                   default: -> { [] }
      attribute :modifier, :string
      attribute :operations, "Lutaml::Lml::Operation", collection: true, default: -> { [] }
      attribute :values, "Lutaml::Lml::Value", collection: true, default: -> { [] }

      def self.entity_type
        :enums
      end
    end
  end
end
