# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::AttributeParser do
  describe ".parse" do
    it "parses a single string assignment" do
      result = described_class.parse('name = "hello"')
      expect(result).to eq("name" => "hello")
    end

    it "parses a single-quoted string" do
      result = described_class.parse("name = 'hello'")
      expect(result).to eq("name" => "hello")
    end

    it "parses an integer assignment" do
      result = described_class.parse("count = 42")
      expect(result).to eq("count" => 42)
    end

    it "parses a negative integer" do
      result = described_class.parse("offset = -5")
      expect(result).to eq("offset" => -5)
    end

    it "parses a float assignment" do
      result = described_class.parse("rate = 3.14")
      expect(result).to eq("rate" => 3.14)
    end

    it "parses multiple assignments" do
      result = described_class.parse('name = "test", count = 10')
      expect(result).to eq("name" => "test", "count" => 10)
    end

    it "raises on invalid input" do
      expect { described_class.parse("!!!invalid!!!") }.to raise_error(Parslet::ParseFailed)
    end
  end
end
