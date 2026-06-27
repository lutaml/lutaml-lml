# frozen_string_literal: true

module Lutaml
  module Lml
    class Document < Lutaml::Model::Serializable
      # Core attributes
      attribute :name, :string
      attribute :title, :string
      attribute :caption, :string
      attribute :groups, "Lutaml::Lml::Group", collection: true
      attribute :fidelity, "Lutaml::Lml::Fidelity"
      attribute :fontname, :string
      attribute :comments, :string, collection: true

      attribute :classes, "Lutaml::Lml::UmlClass", collection: true, default: -> { [] }
      attribute :data_types, "Lutaml::Lml::DataType", collection: true, default: -> { [] }
      attribute :enums, "Lutaml::Lml::Enum", collection: true, default: -> { [] }
      attribute :packages, "Lutaml::Lml::Package", collection: true, default: -> { [] }
      attribute :primitives, "Lutaml::Lml::PrimitiveType", collection: true, default: -> { [] }
      attribute :associations, "Lutaml::Lml::Association", collection: true, default: -> { [] }
      attribute :diagrams, "Lutaml::Lml::Diagram", collection: true, default: -> { [] }

      # LML-specific
      attribute :instance, "Lutaml::Lml::Instance"
      attribute :requires, :string, collection: true
      attribute :instances, "Lutaml::Lml::InstanceCollection"
      attribute :view_imports, "Lutaml::Lml::ViewImport", collection: true
      attribute :show_filter, "Lutaml::Lml::ViewFilter"
      attribute :hide_filter, "Lutaml::Lml::ViewFilter"

      # All class-like entities on the document. Used by resolvers and
      # formatters that need to walk every classifiable type without
      # caring which collection holds it.
      def all_classes
        classes + enums + data_types + primitives
      end

      # Class-like entities that can own associations. Excludes enums
      # (which have no attributes/associations of their own).
      def classifiable_classes
        classes + data_types + primitives
      end
    end
  end
end
