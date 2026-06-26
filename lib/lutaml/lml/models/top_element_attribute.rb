# frozen_string_literal: true

module Lutaml
  module Lml
    class TopElementAttribute < Lutaml::Model::Serializable
      # Core attributes
      attribute :name, :string
      attribute :visibility, :string, default: "public"
      attribute :type, :string
      attribute :id, :string
      attribute :contain, :string
      attribute :static, :string
      attribute :cardinality, "Lutaml::Lml::Cardinality"
      attribute :keyword, :string
      attribute :is_derived, :boolean, default: false
      attribute :is_static, :boolean, default: false
      attribute :is_read_only, :boolean, default: false
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :definition, :string
      attribute :association, :string
      attribute :default, :string

      # LML-specific attributes
      attribute :properties, "Lutaml::Lml::TopElementAttribute", collection: true, default: []
      attribute :value, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true, default: []
      attribute :extended, :boolean
      attribute :instances, "Lutaml::Lml::Instance", collection: true, default: []
    end
  end
end
