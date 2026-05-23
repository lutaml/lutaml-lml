# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe "LML Grammar" do
  # Use the actual Parser class (Full grammar) for testing
  let(:parser) { Lutaml::Lml::Parser }

  describe "Core grammar (.lutaml syntax)" do
    it "parses a minimal diagram" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram MyView { class Foo {} }")
      file.rewind
      doc = parser.parse(file)
      expect(doc).to be_a(Lutaml::Lml::Document)
      expect(doc.classes.first.name).to eq("Foo")
      file.close!
    end

    it "parses class with keyword" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { class NamespacedClass <<MyNamespace>> {} }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.classes.first.name).to eq("NamespacedClass")
      expect(doc.classes.first.keyword).to eq("MyNamespace")
      file.close!
    end

    it "parses abstract class" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { abstract class MyBase {} }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.classes.first.name).to eq("MyBase")
      file.close!
    end

    it "parses multiple classes" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { class A {} class B {} class C {} }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.classes.length).to eq(3)
      file.close!
    end

    it "parses attributes with visibility modifiers" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test {\n  class MyClass {\n    +publicAttr: String\n    -privateAttr: Integer\n  }\n}")
      file.rewind
      doc = parser.parse(file)
      attrs = doc.classes.first.attributes
      expect(by_name(attrs, "publicAttr").visibility).to eq("public")
      expect(by_name(attrs, "privateAttr").visibility).to eq("private")
      file.close!
    end

    it "parses attributes with cardinality" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { class MyClass { items: String [0..*] } }')
      file.rewind
      doc = parser.parse(file)
      attr = doc.classes.first.attributes.first
      expect(attr.name).to eq("items")
      expect(attr.cardinality.min).to eq("0")
      expect(attr.cardinality.max).to eq("*")
      file.close!
    end

    it "parses enum with values" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { enum Color { RED GREEN BLUE } }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.enums.first.name).to eq("Color")
      file.close!
    end

    it "parses data_type" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { data_type Amount { value: Decimal } }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.data_types.first.name).to eq("Amount")
      file.close!
    end

    it "parses primitive type" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { primitive Integer }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.primitives.first.name).to eq("Integer")
      file.close!
    end

    it "parses diagram metadata" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram MyView { title "my diagram" caption "my caption" fontname "Arial" class Foo {} }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.title).to eq("my diagram")
      expect(doc.caption).to eq("my caption")
      expect(doc.fontname).to eq("Arial")
      file.close!
    end

    it "parses definition blocks" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { class MyClass { definition { multi line def } } }')
      file.rewind
      doc = parser.parse(file)
      expect(doc.classes.first.definition).to include("multi line def")
      file.close!
    end

    it "parses comments" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test {\n  ** My comment\n  class Foo {}\n}")
      file.rewind
      doc = parser.parse(file)
      expect(doc.comments).to include("My comment")
      file.close!
    end

    it "parses associations" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test {\n  class Foo {}\n  class Bar {}\n  association MyAssoc {\n    owner Foo\n    member Bar\n  }\n}")
      file.rewind
      doc = parser.parse(file)
      expect(doc.associations.length).to eq(1)
      file.close!
    end
  end

  describe "Full grammar (.lml syntax)" do
    it "parses models block with class definitions" do
      file = Tempfile.new(%w[test .lml])
      file.write <<~LML
        models TestModel {
          class ValidationCheck {
            attribute dev_id {
              type String
              cardinality 1
            }
          }
        }
      LML
      file.rewind
      doc = parser.parse(file)
      expect(doc.name).to eq("TestModel")
      klass = doc.classes.find { |c| c.name == "ValidationCheck" }
      expect(klass).not_to be_nil
      file.close!
    end

    it "parses instances with collection" do
      file = Tempfile.new(%w[test .lml])
      file.write <<~LML
        instances {
          collection "test_suite" {
            includes [ "a", "b" ]
          }
        }
      LML
      file.rewind
      doc = parser.parse(file)
      expect(doc.instances).to be_a(Lutaml::Lml::InstanceCollection)
      file.close!
    end

    it "parses require statements" do
      file = Tempfile.new(%w[test .lml])
      file.write <<~LML
        require "deps.lml"
        models Test { class Foo {} }
      LML
      file.rewind
      doc = parser.parse(file)
      expect(doc.requires).to include("deps.lml")
      file.close!
    end
  end

  describe "Grammar composition" do
    it "Full grammar parses .lutaml files (Core is a subset)" do
      file = Tempfile.new(%w[test .lutaml])
      file.write('diagram Test { class Foo { name: String } }')
      file.rewind
      expect { parser.parse(file) }.not_to raise_error
      file.close!
    end

    it "Full grammar parses .lml files (Instances extension)" do
      file = Tempfile.new(%w[test .lml])
      file.write('models TestModel { class Foo {} }')
      file.rewind
      expect { parser.parse(file) }.not_to raise_error
      file.close!
    end
  end

  describe "Edge cases" do
    it "handles empty diagram" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Empty {}")
      file.rewind
      expect { parser.parse(file) }.not_to raise_error
      file.close!
    end

    it "handles class names with spaces" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test { class Banking Information {} }")
      file.rewind
      expect { parser.parse(file) }.not_to raise_error
      file.close!
    end

    it "handles nested class bodies" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test {\n  class Outer {\n    innerAttr: String\n    class Inner {\n      deepAttr: Integer\n    }\n  }\n}")
      file.rewind
      expect { parser.parse(file) }.not_to raise_error
      file.close!
    end

    it "raises on invalid syntax" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("this is not valid syntax !!!")
      file.rewind
      expect { parser.parse(file) }.to raise_error(Lutaml::Lml::ParsingError)
      file.close!
    end

    it "handles empty class body" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test { class Empty {} }")
      file.rewind
      doc = parser.parse(file)
      expect(doc.classes.first.name).to eq("Empty")
      file.close!
    end

    it "handles include directives via preprocessor" do
      dir = Dir.mktmpdir
      shared = File.join(dir, "shared.lutaml")
      File.write(shared, "class Shared {}")
      main_file = Tempfile.new(%w[test .lutaml])
      main_file.write("diagram Test {\n  include #{shared}\n}")
      main_file.rewind
      doc = parser.parse(main_file)
      expect(doc.classes.map(&:name)).to include("Shared")
      main_file.close!
      FileUtils.rm_rf(dir)
    end
  end

  describe "MECE keyword separation" do
    it "Core grammar defines CORE_KEYWORDS" do
      expect(Lutaml::Lml::Grammar::Core::CORE_KEYWORDS).to include("class", "enum", "attribute", "association")
    end

    it "Instances grammar defines INSTANCE_KEYWORDS" do
      expect(Lutaml::Lml::Grammar::Instances::INSTANCE_KEYWORDS).to include("instance", "models", "collection")
    end

    it "keyword lists do not overlap (MECE)" do
      core = Lutaml::Lml::Grammar::Core::CORE_KEYWORDS
      instances = Lutaml::Lml::Grammar::Instances::INSTANCE_KEYWORDS
      overlap = core & instances
      expect(overlap).to be_empty, "Expected no overlap but found: #{overlap.inspect}"
    end

    it "combined keywords cover all expected keywords" do
      core = Lutaml::Lml::Grammar::Core::CORE_KEYWORDS
      instances = Lutaml::Lml::Grammar::Instances::INSTANCE_KEYWORDS
      all = core + instances
      expect(all.uniq.length).to eq(all.length), "Duplicate keywords found"
    end
  end
end
