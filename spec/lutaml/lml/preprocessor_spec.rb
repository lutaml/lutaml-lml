# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Lutaml::Lml::Preprocessor do
  def make_file(content, name = "test.lutaml")
    file = Tempfile.new([name.gsub(/\..*/, ""), File.extname(name)])
    file.write(content)
    file.rewind
    file
  end

  describe ".call" do
    it "returns file content unchanged for simple files" do
      file = make_file("diagram TestDiagram\nend")
      result = described_class.call(file)
      expect(result).to eq("diagram TestDiagram\nend")
      file.close!
    end

    it "removes // comments" do
      file = make_file("diagram Test // this is a comment\nend")
      result = described_class.call(file)
      expect(result).to eq("diagram Test \nend")
      file.close!
    end

    it "removes inline comments" do
      file = make_file("class MyClass // inline comment\ntitle \"Test\" // another\nend")
      result = described_class.call(file)
      expect(result).not_to include("//")
      file.close!
    end
  end

  describe "include directives" do
    it "includes referenced files" do
      shared_content = "class SharedClass\nend"
      shared_file = make_file(shared_content, "shared.lutaml")

      main_content = "diagram Test\ninclude #{File.basename(shared_file.path)}\nend"
      main_file = Tempfile.new(["main", ".lutaml"])
      main_file.write(main_content)
      main_file.rewind

      result = described_class.call(main_file)
      expect(result).to include("SharedClass")
      expect(result).not_to include("include")
      main_file.close!
      shared_file.close!
    end

    it "handles missing include files gracefully" do
      file = make_file("diagram Test\ninclude nonexistent.lutaml\nend")
      result = described_class.call(file)
      expect(result).not_to include("include nonexistent")
      file.close!
    end
  end
end
