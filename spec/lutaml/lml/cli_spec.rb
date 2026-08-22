# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "tempfile"
require "lutaml/lml/cli"

# The gem writes YAML with Document#to_yaml and reads it back through the
# `-i yaml` input path. A document the gem produced itself has to survive that
# trip, so this drives the real Thor command rather than the parser underneath.
#
# `generate` is the command under test for the round-trip because it exercises
# the full parse-render path; `validate` covers the same input-format handling
# without rendering.
RSpec.describe Lutaml::Cli::LmlCommands do
  def write_yaml(fixture, dir)
    doc = Lutaml::Lml::Pipeline.call(File.new(fixtures_path(fixture)))
    path = File.join(dir, "#{File.basename(fixture, '.lml')}.yaml")
    File.write(path, doc.to_yaml)
    path
  end

  def find_attribute(instance, name)
    return nil unless instance

    Array(instance.attributes).each do |attr|
      return attr if attr.name == name

      Array(attr.instances).each do |nested|
        found = find_attribute(nested, name)
        return found if found
      end
    end
    find_attribute(instance.instance, name)
  end

  def generate(path, dir)
    described_class.start(
      ["generate", "-i", "yaml", "-o", File.join(dir, "out.dot"), path],
    )
  end

  # The defect is CollectionTrueMissingError raised out of the YAML reload,
  # before anything is rendered. Reaching Graphviz therefore proves the reload
  # worked, and Graphviz shells out to `dot`, which CI runners do not have.
  # So a missing binary at the render step is a pass, and any other error
  # still fails the example.
  def reload_through_cli(path, dir)
    generate(path, dir)
    :rendered
  rescue Errno::ENOENT => e
    raise unless e.message.include?("dot")

    :reached_renderer
  end

  describe "generate -i yaml" do
    # data_s102_check.lml carries `prerequisites = [ "S102_Dev1009" ]`, a list
    # literal. Before this change the reload raised CollectionTrueMissingError
    # straight out of the command.
    it "reads back YAML it wrote from a document with a list-valued attribute" do
      Dir.mktmpdir do |dir|
        path = write_yaml("lml/data_s102_check.lml", dir)

        expect(%i[rendered reached_renderer])
          .to include(reload_through_cli(path, dir))
      end
    end

    it "reads back YAML it wrote from a document with a map-valued attribute" do
      Dir.mktmpdir do |dir|
        path = write_yaml("mixed_lml/instances.lml", dir)

        expect(%i[rendered reached_renderer])
          .to include(reload_through_cli(path, dir))
      end
    end

    # The two examples above prove the command completes. They cannot prove the
    # list came back, because these fixtures are instance data and the graphviz
    # formatter only draws classes - the .dot it writes is empty boilerplate
    # either way. So assert the values through the handler the command actually
    # dispatches to for `-i yaml`, which is where the crash used to happen.
    it "recovers the list values through the handler generate dispatches to" do
      Dir.mktmpdir do |dir|
        path = write_yaml("lml/data_s102_check.lml", dir)

        doc = described_class::PARSE_HANDLERS["yaml"].call(Pathname.new(path))

        expect(find_attribute(doc.instance, "prerequisites").value)
          .to eq(["S102_Dev1009"])
      end
    end
  end

  describe "validate" do
    def run_validate(*args)
      described_class.start(["validate", *args])
    end

    it "accepts a valid file with the default input format" do
      file = Tempfile.new(%w[model .lml])
      file.write('models Test { class Foo {} }')
      file.rewind

      expect { run_validate(file.path) }.not_to raise_error
    end

    it "reads a YAML file when given -i yaml" do
      Dir.mktmpdir do |dir|
        path = write_yaml("lml/data_s102_check.lml", dir)

        expect { run_validate("-i", "yaml", path) }.not_to raise_error
      end
    end

    it "rejects a YAML file when the input format is left as lutaml" do
      Dir.mktmpdir do |dir|
        path = write_yaml("lml/data_s102_check.lml", dir)

        expect { run_validate(path) }.to raise_error(SystemExit)
      end
    end

    it "reports a parse failure and exits nonzero" do
      file = Tempfile.new(%w[model .lml])
      file.write("models Test { class Foo {")
      file.rewind

      expect { run_validate(file.path) }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end
  end
end
