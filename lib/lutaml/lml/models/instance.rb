# frozen_string_literal: true

module Lutaml
  module Lml
    class Instance < Lutaml::Model::Serializable
      attribute :type, :string
      attribute :attributes, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :instance, "Lutaml::Lml::Instance"
      attribute :template, "Lutaml::Lml::TopElementAttribute", collection: true
      attribute :parent, :string

      def each_attribute
        return enum_for(:each_attribute) unless block_given?

        Array(attributes).each do |attr|
          yield attr.name, attr.value, Array(attr.instances)
        end
      end
    end
  end
end
