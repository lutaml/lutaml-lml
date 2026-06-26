# frozen_string_literal: true

require "spec_helper"
require "lutaml/lml"

RSpec.describe "View import and filtering" do
  let(:fixtures_dir) { File.expand_path("../../fixtures/view", __dir__) }

  describe "ImportResolver" do
    it "imports model files via glob pattern" do
      file_path = File.join(fixtures_dir, "import_model.lutaml")
      doc = Lutaml::Lml::Parser.parse(File.new(file_path))

      class_names = doc.classes.map(&:name)
      expect(class_names).to include("Foo", "Bar", "Baz")
    end

    it "imports model files from nested view" do
      file_path = File.join(fixtures_dir, "import_view.lutaml")
      doc = Lutaml::Lml::Parser.parse(File.new(file_path))

      class_names = doc.classes.map(&:name)
      expect(class_names).to include("Foo", "Bar", "Baz")
    end

    it "handles circular imports without infinite loop" do
      file_path = File.join(fixtures_dir, "cycle_a.lutaml")
      expect { Lutaml::Lml::Parser.parse(File.new(file_path)) }.not_to raise_error
    end
  end

  describe "ViewResolver show/hide filtering" do
    it "filters entities with show directive" do
      file_path = File.join(fixtures_dir, "import_with_show.lutaml")
      doc = Lutaml::Lml::Parser.parse(File.new(file_path))

      class_names = doc.classes.map(&:name)
      expect(class_names).to include("Foo", "Bar")
      expect(class_names).not_to include("Baz")
    end

    it "filters entities with hide directive" do
      file_path = File.join(fixtures_dir, "import_with_hide.lutaml")
      doc = Lutaml::Lml::Parser.parse(File.new(file_path))

      class_names = doc.classes.map(&:name)
      expect(class_names).not_to include("Baz")
      expect(class_names).to include("Foo", "Bar")
    end
  end
end
