# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rspec"
gem "rubocop"
gem "rake"
# ELK layout for the `--layout elk` diagram engine (soft dependency:
# the gemspec does not require it; Formatter::Elk guides installation)
gem "elkrb", "~> 1.0"
# Diagram output conformance gate (spec/lutaml/lml/svg_conformance_spec.rb)
gem "svg_conform"
gem "nokogiri" # svg_conform resolves its lutaml-model XML adapter through it
