# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Dependency HEAD verification (TODO.next/sota/contract.md): a checkout
# path overrides the released gem so the scheduled job can run the suite
# against upstream main without changing the gemspec.
{
  "LML_LUTAML_MODEL_HEAD" => "lutaml-model",
  "LML_PARSANOL_HEAD" => "parsanol",
  "LML_MOXML_HEAD" => "moxml",
}.each do |env, gem_name|
  path = ENV[env]
  gem gem_name, path: path if path && !path.empty?
end

gem "rspec"
gem "rubocop"
gem "rake"
# Property-based generation for the round-trip laws. 2.x is the last
# series that installs on the gem's supported Ruby floor (3.0 requires
# Ruby 3.3).
gem "rantly", "~> 2.0"
# ELK layout for the `--layout elk` diagram engine (soft dependency:
# the gemspec does not require it; Formatter::Elk guides installation)
gem "elkrb", "~> 1.0"
# Diagram output conformance gate (spec/lutaml/lml/svg_conformance_spec.rb)
gem "svg_conform"
gem "nokogiri" # svg_conform resolves its lutaml-model XML adapter through it
# Output format conversion for the ELK engine (issue #53): SVG -> EMF/PS/EPS
gem "vectory"
# Direct PDF emission for the ELK engine (issue #53): SVG -> PDF, no
# external tools (soft dependency: required only for --type pdf)
gem "pdfrb"
