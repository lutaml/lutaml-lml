# frozen_string_literal: true

module Lutaml
  module Lml
    class Package < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From Package
      attribute :contents, :string, collection: true, default: -> { [] }
      attribute :classes, "Lutaml::Lml::UmlClass", collection: true, default: -> { [] }
      attribute :enums, "Lutaml::Lml::Enum", collection: true, default: -> { [] }
      attribute :data_types, "Lutaml::Lml::DataType", collection: true, default: -> { [] }
      attribute :packages, "Lutaml::Lml::Package", collection: true, default: -> { [] }
      attribute :diagrams, "Lutaml::Lml::Diagram", collection: true, default: -> { [] }
    end
  end
end
