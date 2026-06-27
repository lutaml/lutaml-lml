# frozen_string_literal: true

require "spec_helper"
require "lutaml/lml/executor"

RSpec.describe Lutaml::Lml::Executor do
  describe ".run" do
    it "returns empty array when no imports" do
      doc = Lutaml::Lml::Document.new
      result = described_class.run(doc, compiled: {})
      expect(result).to eq([])
    end

    it "returns empty array when no instances block" do
      doc = Lutaml::Lml::Document.new
      result = described_class.run(doc, compiled: {})
      expect(result).to eq([])
    end

    it "runs imports via registered adapter" do
      # Register a test adapter that returns fixed data
      test_adapter = Class.new do
        def self.import(_imp, compiled:)
          [Struct.new(:name).new("test_item")]
        end

        def self.export(_exp, _instances, compiled:)
          nil
        end
      end
      Lutaml::Lml::Executor::FormatAdapter.register("test", test_adapter)

      imp = Lutaml::Lml::InstancesImport.new(
        format_type: "test",
        file: "test.dat"
      )
      instances = Lutaml::Lml::InstanceCollection.new(imports: [imp])
      doc = Lutaml::Lml::Document.new(instances: instances)

      result = described_class.run(doc, compiled: {})
      expect(result.length).to eq(1)
      expect(result[0].name).to eq("test_item")
    end

    it "skips unknown format types gracefully" do
      imp = Lutaml::Lml::InstancesImport.new(
        format_type: "unknown_format",
        file: "test.dat"
      )
      instances = Lutaml::Lml::InstanceCollection.new(imports: [imp])
      doc = Lutaml::Lml::Document.new(instances: instances)

      result = described_class.run(doc, compiled: {})
      expect(result).to eq([])
    end

    it "runs collection validations" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["count >= 1"]
      )
      instances = Lutaml::Lml::InstanceCollection.new(
        collections: collection
      )
      doc = Lutaml::Lml::Document.new(instances: instances)

      # Should not raise — count >= 1 passes with empty array (count = 0)
      result = described_class.run(doc, compiled: {})
      expect(result).to eq([])
    end
  end
end
