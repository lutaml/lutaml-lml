# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::Converter do
  let(:host) do
    Class.new do
      include Lutaml::Lml::Converter

      def create_class(hash)
        Lutaml::Uml::Class.new.tap { |m| set_model(m, hash) }
      end

      def create_enum(hash)
        Lutaml::Uml::Enum.new.tap { |m| set_model(m, hash) }
      end

      def create_attribute(hash)
        Lutaml::Uml::TopElementAttribute.new.tap { |m| set_model(m, hash) }
      end

      def create_cardinality(hash)
        Lutaml::Uml::Cardinality.new(min: hash[:min], max: hash[:max])
      end

      def create_association(hash)
        Lutaml::Uml::Association.new.tap { |m| set_model(m, hash) }
      end

      def create_package(hash)
        Lutaml::Uml::Package.new.tap { |m| set_model(m, hash) }
      end

      def create_data_type(hash)
        Lutaml::Uml::DataType.new.tap { |m| set_model(m, hash) }
      end

      def create_diagram(hash)
        Lutaml::Uml::Diagram.new.tap { |m| set_model(m, hash) }
      end

      def create_operation(hash)
        Lutaml::Uml::Operation.new.tap { |m| set_model(m, hash) }
      end

      def create_constraint(hash)
        Lutaml::Uml::Constraint.new.tap { |m| set_model(m, hash) }
      end

      def create_value(hash)
        Lutaml::Uml::Value.new.tap { |m| set_model(m, hash) }
      end
    end.new
  end

  describe "#set_model_attribute" do
    it "sets scalar attributes on the model" do
      model = Lutaml::Uml::Class.new
      host.set_model_attribute(model, { name: "MyClass" })
      expect(model.name).to eq("MyClass")
    end

    it "appends to collection attributes" do
      model = Lutaml::Uml::Class.new
      host.set_model_attribute(model, { name: "MyClass" })
      attr = Lutaml::Uml::TopElementAttribute.new(name: "foo")
      host.set_model_attribute(model, { attributes: attr })
      expect(model.attributes.length).to eq(1)
    end

    it "ignores keys not in model attributes" do
      model = Lutaml::Uml::Class.new
      host.set_model_attribute(model, { unknown_key: "value", name: "Test" })
      expect(model.name).to eq("Test")
    end

    it "unescapes braces in definitions" do
      model = Lutaml::Uml::Class.new
      host.set_model_attribute(model, { definition: "text with \\{brace\\}" })
      expect(model.definition).to eq("text with {brace}")
    end

    it "strips leading whitespace from definition lines" do
      model = Lutaml::Uml::Class.new
      host.set_model_attribute(model, { definition: "  line1\n  line2" })
      expect(model.definition).to eq("line1\nline2")
    end
  end

  describe "#set_model" do
    it "sets attributes and builds members" do
      model = Lutaml::Uml::Document.new
      hash = {
        title: "Test",
        members: [{ classes: { name: "MyClass" } }]
      }
      host.set_model(model, hash)
      expect(model.title).to eq("Test")
      expect(model.classes.length).to eq(1)
      expect(model.classes.first.name).to eq("MyClass")
    end
  end

  describe "#build_members" do
    it "extracts and processes members hash" do
      model = Lutaml::Uml::Document.new
      hash = {
        title: "Doc",
        members: [
          { classes: { name: "ClassA" } },
          { enums: { name: "EnumA" } }
        ]
      }
      result = host.build_members(model, hash)
      expect(result[:title]).to eq("Doc")
      expect(result).not_to have_key(:members)
      expect(model.classes.length).to eq(1)
      expect(model.enums.length).to eq(1)
    end

    it "returns hash unchanged when no members key" do
      model = Lutaml::Uml::Document.new
      hash = { title: "Doc" }
      result = host.build_members(model, hash)
      expect(result).to eq({ title: "Doc" })
    end
  end

  describe "MEMBER_FACTORIES" do
    it "maps all expected member types to factory methods" do
      expected = %i[packages classes enums data_types diagrams
                    attributes associations operations constraints values]
      expect(Lutaml::Lml::Converter::MEMBER_FACTORIES.keys).to match_array(expected)
    end
  end
end
