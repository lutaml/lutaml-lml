# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Until the lutaml release that contains LML is published, resolve it from
# a sibling checkout or GitHub main.
lutaml = File.expand_path("../lutaml", __dir__)
if File.directory?(lutaml)
  gem "lutaml", path: lutaml
else
  # TEMPORARY: lutaml main still depends on lutaml-lml (circular); pin the
  # reorg branch until lutaml#236 merges, then return to main.
  gem "lutaml", github: "lutaml/lutaml", branch: "feat/reorg-l1-l3"
end

gem "rake"
gem "rspec"
gem "rubocop"
