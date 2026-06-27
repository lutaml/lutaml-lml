# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::Pipeline do
  describe ".call" do
    it "parses a minimal diagram into a document" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test { class Foo {} }")
      file.rewind

      doc = described_class.call(file)
      expect(doc).to be_a(Lutaml::Lml::Document)
      expect(doc.classes.first.name).to eq("Foo")
    ensure
      file.close!
    end

    it "parses with resolve: false" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("diagram Test { class Bar {} }")
      file.rewind

      doc = described_class.call(file, resolve: false)
      expect(doc).to be_a(Lutaml::Lml::Document)
      expect(doc.classes.first.name).to eq("Bar")
    ensure
      file.close!
    end

    it "raises ParsingError on invalid input" do
      file = Tempfile.new(%w[test .lutaml])
      file.write("!!! invalid !!!")
      file.rewind

      expect { described_class.call(file) }.to raise_error(Lutaml::Lml::ParsingError)
    ensure
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

      doc = described_class.call(file)
      expect(doc.instances).to be_a(Lutaml::Lml::InstanceCollection)
    ensure
      file.close!
    end

    it "resolves view imports when resolve is true" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "model.lutaml"), "class External {}")
      view_file = File.join(dir, "view.lutaml")
      File.write(view_file, "view V { import \"model.lutaml\" }")

      doc = described_class.call(File.new(view_file))
      expect(doc.classes.map(&:name)).to include("External")
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
