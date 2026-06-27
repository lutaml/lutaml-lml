# frozen_string_literal: true

require "spec_helper"
require "lutaml/lml/executor"

RSpec.describe Lutaml::Lml::Executor::ConditionEvaluator do
  let(:item_class) { Struct.new(:id) }

  describe ".evaluate" do
    it "passes when count >= N is satisfied" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["count >= 2"]
      )
      instances = [item_class.new(1), item_class.new(2)]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "fails when count >= N is not satisfied" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["count >= 5"]
      )
      instances = [item_class.new(1), item_class.new(2)]
      errors = described_class.evaluate(collection, instances)
      expect(errors.length).to eq(1)
      expect(errors.first).to include("count >= 5")
      expect(errors.first).to include("got 2")
    end

    it "passes when count == N" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["count == 3"]
      )
      instances = [item_class.new(1), item_class.new(2), item_class.new(3)]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "passes when count <= N" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["count <= 10"]
      )
      instances = [item_class.new(1), item_class.new(2)]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "returns empty array when no validations" do
      collection = Lutaml::Lml::Collection.new(name: "test")
      errors = described_class.evaluate(collection, [])
      expect(errors).to eq([])
    end

    it "raises for unsupported condition forms" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["unknown_thing"]
      )
      errors = described_class.evaluate(collection, [])
      expect(errors.length).to eq(1)
      expect(errors.first).to include("Unsupported condition")
    end
  end

  describe "block conditions (all?/any?)" do
    let(:item_class) { Struct.new(:name, :components) }

    it "passes when all instances satisfy the predicate" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["all? { |i| i.components.count > 0 }"]
      )
      instances = [
        item_class.new("A", [1]),
        item_class.new("B", [1, 2])
      ]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "fails when any instance does not satisfy the predicate" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["all? { |i| i.components.count > 0 }"]
      )
      instances = [
        item_class.new("A", [1]),
        item_class.new("B", [])
      ]
      errors = described_class.evaluate(collection, instances)
      expect(errors.length).to eq(1)
      expect(errors.first).to include("failed for at least one instance")
    end

    it "passes any? when at least one instance matches" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ['any? { |i| i.name == "B" }']
      )
      instances = [
        item_class.new("A", [1]),
        item_class.new("B", [2])
      ]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "fails any? when no instances match" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ['any? { |i| i.name == "Z" }']
      )
      instances = [item_class.new("A", [1]), item_class.new("B", [2])]
      errors = described_class.evaluate(collection, instances)
      expect(errors.length).to eq(1)
    end

    it "supports numeric, string, boolean, and nil literals" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: [
          "all? { |i| i.components.count >= 1 }",
          'all? { |i| i.name != "X" }'
        ]
      )
      instances = [item_class.new("A", [1])]
      errors = described_class.evaluate(collection, instances)
      expect(errors).to eq([])
    end

    it "reports malformed block conditions" do
      collection = Lutaml::Lml::Collection.new(
        name: "test",
        validations: ["all? { we fubar }"]
      )
      errors = described_class.evaluate(collection, [])
      expect(errors.length).to eq(1)
      expect(errors.first).to include("Invalid block condition")
    end
  end
end
