# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Formatter::Base do
  describe "FORMAT_HANDLERS" do
    it "is a Hash" do
      expect(described_class::FORMAT_HANDLERS).to be_a(Hash)
    end

    it "maps every node type to a handler method" do
      aggregate_failures do
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::TopElementAttribute]).to eq(:format_attribute)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::Operation]).to eq(:format_operation)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::Association]).to eq(:format_relationship)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::Document]).to eq(:format_document)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::DataType]).to eq(:format_class)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::UmlClass]).to eq(:format_class)
        expect(described_class::FORMAT_HANDLERS[Lutaml::Lml::Enum]).to eq(:format_class)
      end
    end
  end

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
      skip "GraphViz 'dot' not available" unless system("which dot > /dev/null 2>&1")

      doc = Lutaml::Lml::Document.new
      result = Lutaml::Formatter::Graphviz.format(doc)
      expect(result).to be_a(String)
    end
  end

  describe "#format" do
    let(:formatter) { described_class.new }

    it "dispatches to format_document for Uml::Document" do
      doc = Lutaml::Lml::Document.new
      expect(formatter).to receive(:format_document).with(doc)
      formatter.format(doc)
    end

    it "dispatches to format_document for Lml::Document subclass" do
      doc = Lutaml::Lml::Document.new
      expect(formatter).to receive(:format_document).with(doc)
      formatter.format(doc)
    end

    it "dispatches to format_attribute for Lml::TopElementAttribute subclass" do
      attr = Lutaml::Lml::TopElementAttribute.new
      expect(formatter).to receive(:format_attribute).with(attr)
      formatter.format(attr)
    end

    it "dispatches to format_class for Lml::UmlClass subclass" do
      klass = Lutaml::Lml::UmlClass.new
      expect(formatter).to receive(:format_class).with(klass)
      formatter.format(klass)
    end

    it "dispatches to format_class for Lml::Enum subclass" do
      enum = Lutaml::Lml::Enum.new
      expect(formatter).to receive(:format_class).with(enum)
      formatter.format(enum)
    end

    it "dispatches to format_class for Lml::DataType subclass" do
      dt = Lutaml::Lml::DataType.new
      expect(formatter).to receive(:format_class).with(dt)
      formatter.format(dt)
    end

    it "dispatches to format_relationship for Lml::Association subclass" do
      assoc = Lutaml::Lml::Association.new
      expect(formatter).to receive(:format_relationship).with(assoc)
      formatter.format(assoc)
    end

    it "dispatches to format_operation for Lml::Operation subclass" do
      op = Lutaml::Lml::Operation.new
      expect(formatter).to receive(:format_operation).with(op)
      formatter.format(op)
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
