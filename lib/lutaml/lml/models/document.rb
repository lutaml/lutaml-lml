# frozen_string_literal: true

require "lutaml/uml/document"

module Lutaml
  module Lml
    class Document < Lutaml::Uml::Document
      attribute :instance, "Lutaml::Lml::Instance"
      attribute :requires, :string, collection: true
      attribute :instances, "Lutaml::Lml::InstanceCollection"
    end
  end
end
