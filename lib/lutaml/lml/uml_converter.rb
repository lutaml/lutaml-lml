# frozen_string_literal: true

require_relative "converter"

module Lutaml
  module Lml
    module UmlConverter
      include Converter

      def create_document(hash)
        ::Lutaml::Uml::Document.new.tap { |m| set_model(m, hash) }
      end

      def create_package(hash)
        ::Lutaml::Uml::Package.new.tap { |m| set_model(m, hash) }
      end

      def create_class(hash)
        ::Lutaml::Uml::Class.new.tap { |m| set_model(m, hash) }
      end

      def create_enum(hash)
        ::Lutaml::Uml::Enum.new.tap { |m| set_model(m, hash) }
      end

      def create_data_type(hash)
        ::Lutaml::Uml::DataType.new.tap { |m| set_model(m, hash) }
      end

      def create_diagram(hash)
        ::Lutaml::Uml::Diagram.new.tap { |m| set_model(m, hash) }
      end

      def create_attribute(hash)
        ::Lutaml::Uml::TopElementAttribute.new.tap { |m| set_model(m, hash) }
      end

      def create_cardinality(hash)
        ::Lutaml::Uml::Cardinality.new.tap do |c|
          c.min = hash[:min]
          c.max = hash[:max]
        end
      end

      def create_association(hash)
        ::Lutaml::Uml::Association.new.tap do |model|
          member_end_card = hash.delete(:member_end_cardinality)
          model.member_end_cardinality = create_cardinality(member_end_card) if member_end_card
          owner_end_card = hash.delete(:owner_end_cardinality)
          model.owner_end_cardinality = create_cardinality(owner_end_card) if owner_end_card
          set_model(model, hash)
        end
      end

      def create_operation(hash)
        ::Lutaml::Uml::Operation.new.tap { |m| set_model(m, hash) }
      end

      def create_constraint(hash)
        ::Lutaml::Uml::Constraint.new.tap { |m| set_model(m, hash) }
      end

      def create_value(hash)
        ::Lutaml::Uml::Value.new.tap { |m| set_model(m, hash) }
      end
    end
  end
end
