# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Formatter::Graphviz do
  let(:formatter) { described_class.new }

  describe "#format_attribute" do
    it "renders public attribute with type" do
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "count", visibility: "public", type: "Integer"
      )
      expect(formatter.format_attribute(attr)).to eq("+count : Integer")
    end

    it "renders private attribute" do
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "secret", visibility: "private"
      )
      expect(formatter.format_attribute(attr)).to eq("-secret")
    end

    it "renders attribute with keyword" do
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "id", visibility: "public", type: "String", keyword: "PK"
      )
      expect(formatter.format_attribute(attr)).to eq("+id : «PK»String")
    end

    it "escapes brackets in cardinality output" do
      card = Lutaml::Uml::Cardinality.new(min: "0", max: "*")
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "items", visibility: "public", type: "String",
        cardinality: card
      )
      result = formatter.format_attribute(attr)
      expect(result).to include("&#91;0..*&#93;")
    end

    it "renders static attribute with underline" do
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "instance", visibility: "public", static: "true"
      )
      expect(formatter.format_attribute(attr)).to eq("<U>+instance</U>")
    end
  end

  describe "#format_label" do
    it "formats label with cardinality" do
      card = Lutaml::Uml::Cardinality.new(min: "1", max: "*")
      result = formatter.format_label("items", card)
      expect(result).to eq("+items 1..*")
    end

    it "returns name only when cardinality is nil" do
      result = formatter.format_label("name", nil)
      expect(result).to eq("+name")
    end
  end

  describe "#escape_html_chars" do
    it "escapes angle brackets and square brackets" do
      result = formatter.escape_html_chars("<class>[0]")
      expect(result).to eq("&#60;class&#62;&#91;0&#93;")
    end
  end

  describe "#format_class" do
    it "renders class with keyword" do
      klass = Lutaml::Uml::Class.new(name: "Service", keyword: "interface")
      result = formatter.format_class(klass, nil)
      expect(result).to include("«interface»")
      expect(result).to include("<B>Service</B>")
    end

    it "renders class with attributes" do
      attr = Lutaml::Uml::TopElementAttribute.new(
        name: "id", visibility: "public", type: "String"
      )
      klass = Lutaml::Uml::Class.new(name: "Entity", attributes: [attr])
      result = formatter.format_class(klass, nil)
      expect(result).to include("+id : String")
    end

    it "renders empty table when hide_members is true" do
      attr = Lutaml::Uml::TopElementAttribute.new(name: "hidden", visibility: "public")
      klass = Lutaml::Uml::Class.new(name: "Hidden", attributes: [attr])
      result = formatter.format_class(klass, true)
      expect(result).not_to include("hidden")
    end
  end

  describe "#indent_lines" do
    it "indents each line with two spaces" do
      result = formatter.indent_lines("line1\nline2")
      expect(result).to eq("  line1\n  line2")
    end
  end

  describe "#extract_fidelity_options" do
    it "returns nil pair when no fidelity" do
      doc = Lutaml::Uml::Document.new
      expect(formatter.extract_fidelity_options(doc)).to eq([nil, nil])
    end
  end
end
