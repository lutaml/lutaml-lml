# frozen_string_literal: true

require "lutaml/uml/class"

module Lutaml
  module Lml
    class TopElementAttribute < Uml::TopElementAttribute
      attribute :properties, TopElementAttribute, collection: true, default: []
      attribute :value, TopElementAttribute, collection: true
      attribute :attributes, TopElementAttribute, collection: true, default: []
      attribute :extended, :boolean
      attribute :instances, "Lutaml::Lml::Instance", collection: true, default: []
    end
  end
end
