# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# The LML front ships inside the lutaml gem (lutaml >= 0.11.8, monorepo
# packages/lutaml), so the released gem covers every consumer. A sibling
# monorepo checkout overrides it for local development; CI and everyone
# else resolve from rubygems.
lutaml_pkg = File.expand_path("../lutaml/packages/lutaml", __dir__)
if File.directory?(lutaml_pkg)
  gem "lutaml", path: lutaml_pkg
else
  gem "lutaml"
end

gem "rake"
gem "rspec"
gem "rubocop"
