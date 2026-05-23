# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::TopElementAttribute do
  describe "inheritance" do
    it "inherits from Lutaml::Uml::TopElementAttribute" do
      expect(described_class).to be < Lutaml::Uml::TopElementAttribute
    end
  end

  describe "extended attributes" do
    it "has properties collection" do
      attr = described_class.new
      expect(attr.properties).to eq([])
    end

    it "has value collection" do
      attr = described_class.new
      expect(attr.value).to be_nil
    end

    it "has attributes collection" do
      attr = described_class.new
      expect(attr.attributes).to eq([])
    end

    it "has extended boolean" do
      attr = described_class.new
      expect(attr.extended).to be_nil
      attr.extended = true
      expect(attr.extended).to eq(true)
    end

    it "has instances collection" do
      attr = described_class.new
      expect(attr.instances).to eq([])
    end
  end

  describe "with nested properties" do
    it "holds nested TopElementAttribute as properties" do
      prop = described_class.new(name: "description", value: "A description")
      attr = described_class.new(name: "dev_id", type: "String", properties: [prop])
      expect(attr.properties.first.name).to eq("description")
    end
  end
end
