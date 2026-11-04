# frozen_string_literal: true

require_relative "lib/lutaml_lml/version"

Gem::Specification.new do |spec|
  spec.name = "lutaml-lml"
  spec.version = LutamlLml::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Transitional alias for lutaml (LML was absorbed into it)"
  spec.description = "LutaML Model Language (LML) now ships inside the lutaml " \
                     "gem. This gem only depends on lutaml for one " \
                     "deprecation window; depend on lutaml directly."
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

  spec.add_dependency "lutaml"
end
