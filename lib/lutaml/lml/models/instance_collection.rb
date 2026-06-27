# frozen_string_literal: true

module Lutaml
  module Lml
    class InstanceCollection < Lutaml::Model::Serializable
      attribute :instances, "Lutaml::Lml::Instance", collection: true, default: []
      attribute :imports, "Lutaml::Lml::InstancesImport", collection: true, default: []
      attribute :exports, "Lutaml::Lml::InstancesExport", collection: true, default: []
      attribute :collections, "Lutaml::Lml::Collection", default: []
    end
  end
end
