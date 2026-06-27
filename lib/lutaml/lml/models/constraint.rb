# frozen_string_literal: true

module Lutaml
  module Lml
    class Constraint < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From Constraint
      attribute :body, :string
      attribute :type, :string
      attribute :weight, :string
      attribute :status, :string
    end
  end
end
