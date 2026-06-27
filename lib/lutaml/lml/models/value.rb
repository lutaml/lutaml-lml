# frozen_string_literal: true

module Lutaml
  module Lml
    class Value < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :id, :string
      attribute :type, :string
      attribute :definition, :string
    end
  end
end
