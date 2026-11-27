# frozen_string_literal: true

require_relative "lib/lutaml_lml/version"

Gem::Specification.new do |spec|
  spec.name = "lutaml-lml"
  spec.version = LutamlLml::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Retired: the LML core ships in lutaml-model; rendering in lutaml-diagram"
  spec.description = "RETIRED. The LutaML Model Language (LML) core ships inside "
                     "lutaml-model >= 0.8.188 (require \"lutaml/lml\"); the "
                     "render backends (ELK, DOT emission, SVG/PDF) ship in "
                     "lutaml-diagram. Depend on lutaml-model (and "
                     "lutaml-diagram for rendering) — not on this gem."
  spec.homepage = "https://github.com/lutaml/lutaml-lml"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases",
    "rubygems_mfa_required" => "true",
  }

  spec.files = ["lib/lutaml-lml.rb", "lib/lutaml_lml/version.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "lutaml-model", "~> 0.8.188" # carries lib/lutaml/lml (the subsume this alias forwards to)
end
