# frozen_string_literal: true

require "bundler/setup"
require "lutaml-lml"

RSpec.describe "lutaml-lml transitional alias" do
  let(:gemspec) do
    Gem::Specification.load(File.expand_path("../lutaml-lml.gemspec", __dir__))
  end

  it "depends on lutaml and nothing else" do
    expect(gemspec.runtime_dependencies.map(&:name)).to eq(["lutaml"])
  end

  it "no longer depends on ruby-graphviz" do
    expect(gemspec.runtime_dependencies.map(&:name))
      .not_to include("ruby-graphviz")
  end

  it "ships no LML implementation of its own" do
    expect(gemspec.files).to all(satisfy { |f| !f.start_with?("lib/lutaml/") })
  end

  it "loads the LML front from lutaml" do
    expect(Lutaml::Lml.parse("models M { class A {} }")).to be_a(Lutaml::Lml::Document)
  end
end
