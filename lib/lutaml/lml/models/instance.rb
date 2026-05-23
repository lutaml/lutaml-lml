# frozen_string_literal: true

module Lutaml
  module Lml
    class Instance < Lutaml::Model::Serializable
      attribute :type, :string
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :instance, "Lutaml::Lml::Instance"
      attribute :template, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :parent, :string
    end
  end
end
