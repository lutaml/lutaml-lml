# frozen_string_literal: true

require "spec_helper"

RSpec.describe "LML model subclasses" do
  describe Lutaml::Lml::Class do
    it "inherits from Uml::Class" do
      expect(described_class).to be < Lutaml::Uml::Class
    end

    it "has parent_class attribute" do
      klass = described_class.new(name: "Child", parent_class: "Parent")
      expect(klass.parent_class).to eq("Parent")
    end
  end

  describe Lutaml::Lml::Enum do
    it "inherits from Uml::Enum" do
      expect(described_class).to be < Lutaml::Uml::Enum
    end
  end

  describe Lutaml::Lml::DataType do
    it "inherits from Uml::DataType" do
      expect(described_class).to be < Lutaml::Uml::DataType
    end
  end

  describe Lutaml::Lml::Package do
    it "inherits from Uml::Package" do
      expect(described_class).to be < Lutaml::Uml::Package
    end
  end

  describe Lutaml::Lml::Association do
    it "inherits from Uml::Association" do
      expect(described_class).to be < Lutaml::Uml::Association
    end
  end

  describe Lutaml::Lml::Cardinality do
    it "inherits from Uml::Cardinality" do
      expect(described_class).to be < Lutaml::Uml::Cardinality
    end
  end

  describe Lutaml::Lml::Value do
    it "inherits from Uml::Value" do
      expect(described_class).to be < Lutaml::Uml::Value
    end
  end

  describe Lutaml::Lml::Constraint do
    it "inherits from Uml::Constraint" do
      expect(described_class).to be < Lutaml::Uml::Constraint
    end
  end

  describe Lutaml::Lml::Operation do
    it "inherits from Uml::Operation" do
      expect(described_class).to be < Lutaml::Uml::Operation
    end
  end
end
