# frozen_string_literal: true

module Lutaml
  module Lml
    class Operation < Lutaml::Model::Serializable
      # From TopElement
      attribute :name, :string
      attribute :definition, :string
      attribute :keyword, :string
      attribute :stereotype, :string, collection: true, default: -> { [] }
      attribute :visibility, :string, default: "public"

      # From Operation
      attribute :id, :string
      attribute :return_type, :string
      attribute :parameter_type, :string
      attribute :is_static, :boolean, default: false
      attribute :is_abstract, :boolean, default: false
      attribute :owned_parameter, "Lutaml::Lml::OperationParameter", collection: true,
                                                                          default: -> { [] }
    end
  end
end
