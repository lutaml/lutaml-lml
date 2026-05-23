# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::Transform do
  let(:transform) { described_class.new }

  describe "visibility modifier rule" do
    it "converts '-' to 'private'" do
      result = transform.apply({ visibility_modifier: "-" })
      expect(result).to eq("private")
    end

    it "converts '#' to 'protected'" do
      result = transform.apply({ visibility_modifier: "#" })
      expect(result).to eq("protected")
    end

    it "converts '~' to 'friendly'" do
      result = transform.apply({ visibility_modifier: "~" })
      expect(result).to eq("friendly")
    end

    it "converts '+' to 'public'" do
      result = transform.apply({ visibility_modifier: "+" })
      expect(result).to eq("public")
    end
  end

  describe "simple member rule" do
    it "strips whitespace from non-nil simple members in nested context" do
      result = transform.apply({ outer: "  hello  " })
      expect(result[:outer]).to eq("hello")
    end
  end
end
