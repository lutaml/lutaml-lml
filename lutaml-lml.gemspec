# frozen_string_literal: true

require_relative "lib/lutaml/lml/version"

Gem::Specification.new do |spec|
  spec.name = "lutaml-lml"
  spec.version = Lutaml::Lml::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "LutaML Model Language (LML) parser and converter"
  spec.description = "Parses LML (.lml / .lutaml) text syntax into UML/LML domain models. " \
                     "Supports two layers: model definitions (classes, enums, attributes) " \
                     "and data instances (collections, imports, exports)."
  spec.homepage = "https://github.com/lutaml/lutaml-lml"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/lutaml/lutaml-lml",
    "changelog_uri" => "https://github.com/lutaml/lutaml-lml/releases"
  }

  spec.files = Dir.glob("lib/**/*.rb") + Dir.glob("exe/*")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "lutaml-model", "~> 0.3"
  spec.add_dependency "lutaml-uml"
  spec.add_dependency "parslet", "~> 2.0"
  spec.add_dependency "ruby-graphviz"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rake", "~> 13.0"
end
