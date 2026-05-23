# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Layout::Engine do
  describe "#initialize" do
    it "stores input" do
      engine = described_class.new(input: "digraph G {}")
      expect(engine.input).to eq("digraph G {}")
    end
  end

  describe "#render" do
    it "raises ArgumentError" do
      engine = described_class.new(input: "test")
      expect { engine.render(:dot) }.to raise_error(ArgumentError, /Implement render method/)
    end
  end
end

RSpec.describe Lutaml::Layout::GraphVizEngine do
  describe "#render" do
    it "delegates to dot command and returns output" do
      skip "GraphViz 'dot' not available" unless system("which dot > /dev/null 2>&1")

      dot_input = "digraph G { A -> B }"
      engine = described_class.new(input: dot_input)
      result = engine.render(:svg)
      expect(result).to include("svg")
    end
  end
end
