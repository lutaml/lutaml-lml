# frozen_string_literal: true

module Lutaml
  module Lml
    class Diagram < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      attribute :package_id, :string
      attribute :package_name, :string
      attribute :diagram_type, :string
    end
  end
end
