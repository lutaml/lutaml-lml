# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::Document do
  describe "inheritance" do
    it "inherits from Lutaml::Uml::Document" do
      expect(described_class).to be < Lutaml::Uml::Document
    end
  end

  describe "attributes" do
    it "has instance attribute" do
      doc = described_class.new
      expect(doc.instance).to be_nil
    end

    it "has requires collection" do
      doc = described_class.new
      expect(doc.requires).to be_nil
    end

    it "has instances attribute" do
      doc = described_class.new
      expect(doc.instances).to be_nil
    end
  end

  describe "setting attributes" do
    it "accepts requires list" do
      doc = described_class.new
      doc.requires = ["file1.lml", "file2.lml"]
      expect(doc.requires).to eq(["file1.lml", "file2.lml"])
    end

    it "accepts an instance" do
      inst = Lutaml::Lml::Instance.new(type: "MyType")
      doc = described_class.new
      doc.instance = inst
      expect(doc.instance.type).to eq("MyType")
    end

    it "accepts an InstanceCollection" do
      collection = Lutaml::Lml::InstanceCollection.new
      doc = described_class.new
      doc.instances = collection
      expect(doc.instances).to eq(collection)
    end
  end
end
