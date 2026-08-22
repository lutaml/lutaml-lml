# frozen_string_literal: true

module Lutaml
  module Lml
    class Value < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :id, :string
      attribute :type, :string
      attribute :definition, Lutaml::Lml::Types::TextType
    end
  end
end
