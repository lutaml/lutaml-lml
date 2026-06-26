# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Lutaml::Lml::ImportResolver do
  describe "#resolve" do
    it "resolves glob patterns to model files" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "foo.lutaml"), "class Foo { name: String }")
      File.write(File.join(dir, "bar.lutaml"), "class Bar { count: Integer }")

      doc = Lutaml::Lml::Document.new(
        view_imports: [Lutaml::Lml::ViewImport.new(path: File.join(dir, "*.lutaml"))]
      )
      resolver = described_class.new(nil)
      entities, _associations = resolver.resolve(doc)

      expect(entities.map(&:name)).to include("Foo", "Bar")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "handles empty glob results gracefully" do
      doc = Lutaml::Lml::Document.new(
        view_imports: [Lutaml::Lml::ViewImport.new(path: "/nonexistent/path/*.lutaml")]
      )
      resolver = described_class.new(nil)
      entities, associations = resolver.resolve(doc)
      expect(entities).to be_empty
      expect(associations).to be_empty
    end

    it "deduplicates entities by name (first wins)" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "a.lutaml"), "class Foo { x: String }")
      File.write(File.join(dir, "b.lutaml"), "class Foo { y: Integer }")

      doc = Lutaml::Lml::Document.new(
        view_imports: [Lutaml::Lml::ViewImport.new(path: File.join(dir, "*.lutaml"))]
      )
      resolver = described_class.new(nil)
      entities, = resolver.resolve(doc)

      foos = entities.select { |e| e.name == "Foo" }
      expect(foos.length).to eq(1)
    ensure
      FileUtils.rm_rf(dir)
    end

    it "resolves relative to base_path" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "model.lutaml"), "class Baz {}")

      view_file = File.join(dir, "view.lutaml")
      File.write(view_file, "view V { import \"model.lutaml\" }")

      doc = Lutaml::Lml::Parser.parse(File.new(view_file))
      expect(doc.classes.map(&:name)).to include("Baz")
    ensure
      FileUtils.rm_rf(dir)
    end

    it "skips unreadable files without crashing" do
      dir = Dir.mktmpdir
      path = File.join(dir, "unreadable.lutaml")
      File.write(path, "class Foo {}")
      FileUtils.chmod(0o000, path)
      doc = Lutaml::Lml::Document.new(
        view_imports: [Lutaml::Lml::ViewImport.new(path: path)]
      )
      resolver = described_class.new(nil)
      entities, = resolver.resolve(doc)
      expect(entities).to be_empty
    ensure
      FileUtils.chmod(0o644, File.join(dir, "unreadable.lutaml")) rescue nil
      FileUtils.rm_rf(dir)
    end
  end
end
