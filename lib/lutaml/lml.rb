# frozen_string_literal: true

require "lutaml/model"
require "lutaml/uml"

require_relative "lml/version"

module Lutaml
  module Lml
    class Error < Lutaml::Error; end
    class ParsingError < Error; end

    module Node; end
  end
end

# LML model classes (depend on UML domain models)
Dir.glob(File.expand_path("./lml/models/**/*.rb", __dir__)).sort.each do |file|
  require file
end

# Grammar, transform, preprocessing, conversion, parsing
require_relative "lml/grammar/core"
require_relative "lml/grammar/instances"
require_relative "lml/grammar/full"
require_relative "lml/transform"
require_relative "lml/preprocessor"
require_relative "lml/data_processor"
require_relative "lml/converter"
require_relative "lml/uml_converter"
require_relative "lml/lml_converter"
require_relative "lml/parser"
require_relative "lml/yaml_parser"
require_relative "lml/attribute_parser"

# Formatter and layout
require_relative "lml/formatter/base"
require_relative "lml/formatter/graphviz"
require_relative "lml/layout/engine"
require_relative "lml/layout/graph_viz_engine"
