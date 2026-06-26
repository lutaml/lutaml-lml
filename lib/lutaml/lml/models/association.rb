# frozen_string_literal: true

module Lutaml
  module Lml
    class Association < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From Association
      attribute :owner_end, :string
      attribute :owner_end_attribute_name, :string
      attribute :owner_end_cardinality, "Lutaml::Lml::Cardinality"
      attribute :owner_end_type, :string
      attribute :member_end, :string
      attribute :member_end_attribute_name, :string
      attribute :member_end_cardinality, "Lutaml::Lml::Cardinality"
      attribute :member_end_type, :string
      attribute :static, :string
      attribute :action, "Lutaml::Lml::Action"
    end
  end
end
