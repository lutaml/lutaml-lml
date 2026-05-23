# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::Converter do
  let(:host) do
    obj = Object.new
    obj.extend(Lutaml::Lml::UmlConverter)
    obj
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

  describe "#model_registry" do
    it "raises NotImplementedError on base Converter" do
      base = Object.new
      base.extend(Lutaml::Lml::Converter)
      expect { base.model_registry }.to raise_error(NotImplementedError)
    end
  end

  describe "#create_cardinality" do
    it "creates a cardinality with min and max" do
      card = host.create_cardinality({ min: "0", max: "*" })
      expect(card).to be_a(Lutaml::Uml::Cardinality)
      expect(card.min).to eq("0")
      expect(card.max).to eq("*")
    end
  end
end

RSpec.describe Lutaml::Lml::LmlConverter do
  let(:converter) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe "MODEL_REGISTRY" do
    it "maps all factory types to Lml model classes" do
      registry = described_class::MODEL_REGISTRY
      expect(registry[:document]).to eq(Lutaml::Lml::Document)
      expect(registry[:class]).to eq(Lutaml::Lml::Class)
      expect(registry[:enum]).to eq(Lutaml::Lml::Enum)
      expect(registry[:data_type]).to eq(Lutaml::Lml::DataType)
      expect(registry[:association]).to eq(Lutaml::Lml::Association)
    end

    it "uses Uml::Diagram for diagram (no Lml subclass)" do
      expect(described_class::MODEL_REGISTRY[:diagram]).to eq(Lutaml::Uml::Diagram)
    end
  end

  it "creates Lml model instances" do
    klass = converter.create_class({ name: "LmlClass" })
    expect(klass).to be_a(Lutaml::Lml::Class)
    expect(klass.name).to eq("LmlClass")
  end
end

RSpec.describe Lutaml::Lml::UmlConverter do
  let(:converter) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe "MODEL_REGISTRY" do
    it "maps all factory types to Uml model classes" do
      registry = described_class::MODEL_REGISTRY
      expect(registry[:document]).to eq(Lutaml::Uml::Document)
      expect(registry[:class]).to eq(Lutaml::Uml::Class)
      expect(registry[:enum]).to eq(Lutaml::Uml::Enum)
      expect(registry[:data_type]).to eq(Lutaml::Uml::DataType)
    end
  end

  it "creates Uml model instances" do
    klass = converter.create_class({ name: "UmlClass" })
    expect(klass).to be_a(Lutaml::Uml::Class)
    expect(klass.name).to eq("UmlClass")
  end
end
