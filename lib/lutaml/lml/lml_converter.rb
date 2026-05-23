# frozen_string_literal: true

require_relative "converter"
require_relative "models/document"

module Lutaml
  module Lml
    module LmlConverter
      include Converter

      # Creates Lml::Document (has instance/requires/instances from layer 2)
      def create_document(hash)
        ::Lutaml::Lml::Document.new.tap { |m| set_model(m, hash) }
      end

      def create_package(hash)
        ::Lutaml::Lml::Package.new.tap { |m| set_model(m, hash) }
      end

      def create_class(hash)
        ::Lutaml::Lml::Class.new.tap { |m| set_model(m, hash) }
      end

      def create_enum(hash)
        ::Lutaml::Lml::Enum.new.tap { |m| set_model(m, hash) }
      end

      def create_data_type(hash)
        ::Lutaml::Lml::DataType.new.tap { |m| set_model(m, hash) }
      end

      # No Lml::Diagram subclass — use Uml::Diagram
      def create_diagram(hash)
        ::Lutaml::Uml::Diagram.new.tap { |m| set_model(m, hash) }
      end

      def create_attribute(hash)
        ::Lutaml::Lml::TopElementAttribute.new.tap { |m| set_model(m, hash) }
      end

      def create_cardinality(hash)
        ::Lutaml::Lml::Cardinality.new.tap do |c|
          c.min = hash[:min]
          c.max = hash[:max]
        end
      end

      def create_association(hash)
        ::Lutaml::Lml::Association.new.tap do |model|
          member_end_card = hash.delete(:member_end_cardinality)
          model.member_end_cardinality = create_cardinality(member_end_card) if member_end_card
          owner_end_card = hash.delete(:owner_end_cardinality)
          model.owner_end_cardinality = create_cardinality(owner_end_card) if owner_end_card
          set_model(model, hash)
        end
      end

      def create_operation(hash)
        ::Lutaml::Lml::Operation.new.tap { |m| set_model(m, hash) }
      end

      def create_constraint(hash)
        ::Lutaml::Lml::Constraint.new.tap { |m| set_model(m, hash) }
      end

      def create_value(hash)
        ::Lutaml::Lml::Value.new.tap { |m| set_model(m, hash) }
      end
    end
  end
end
