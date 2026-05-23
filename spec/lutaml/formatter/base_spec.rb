# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Formatter::Base do
  describe ".inherited" do
    it "registers subclasses in Formatter.all" do
      expect(Lutaml::Formatter.all).to include(Lutaml::Formatter::Graphviz)
    end
  end

  describe ".name" do
    it "returns downcased last segment of class name" do
      expect(Lutaml::Formatter::Graphviz.name).to eq(:graphviz)
    end
  end

  describe ".format" do
    it "creates an instance and delegates to #format" do
      doc = Lutaml::Uml::Document.new
      result = Lutaml::Formatter::Graphviz.format(doc)
      expect(result).to be_a(String)
    end
  end

  describe "#format" do
    let(:formatter) { described_class.new }

    it "dispatches to format_document for Uml::Document" do
      doc = Lutaml::Uml::Document.new
      expect(formatter).to receive(:format_document).with(doc)
      formatter.format(doc)
    end

    it "returns nil for unknown node types" do
      unknown = Object.new
      expect(formatter.format(unknown)).to be_nil
    end
  end

  describe "abstract methods" do
    let(:formatter) { described_class.new }

    it "raises NotImplementedError for format_attribute" do
      expect { formatter.format_attribute(nil) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for format_operation" do
      expect { formatter.format_operation(nil) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for format_relationship" do
      expect { formatter.format_relationship(nil) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for format_class_relationship" do
      expect { formatter.format_class_relationship(nil) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for format_class" do
      expect { formatter.format_class(nil) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for format_document" do
      expect { formatter.format_document(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#type=" do
    let(:formatter) { described_class.new }

    it "sets type as a downcased symbol" do
      formatter.type = "PNG"
      expect(formatter.type).to eq(:png)
    end

    it "strips whitespace" do
      formatter.type = " svg "
      expect(formatter.type).to eq(:svg)
    end
  end
end
