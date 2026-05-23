# frozen_string_literal: true

module Lutaml
  module Lml
    class InstancesImport < Lutaml::Model::Serializable
      attribute :format_type, :string
      attribute :file, :string
      attribute :attributes, "Lutaml::Lml::TopElementAttribute"
    end
  end
end
