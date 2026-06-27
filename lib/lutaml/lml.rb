# frozen_string_literal: true

require "lutaml/model"

# Lutaml::Formatter and Lutaml::Layout are in the Lutaml top namespace,
# not Lutaml::Lml. Require their namespace files to set up autoloads.
require "lutaml/lml/formatter"
require "lutaml/lml/layout"

module Lutaml
  class Error < StandardError; end

  module Lml
    class Error < Lutaml::Error; end
    class ParsingError < Error; end

    def self.compile(input, namespace: nil)
      ModelCompiler.new(namespace: namespace).compile(input)
    end

    # Top-level autoloads
    autoload :Parser, "lutaml/lml/parser"
    autoload :Pipeline, "lutaml/lml/pipeline"
    autoload :Preprocessor, "lutaml/lml/preprocessor"
    autoload :Transform, "lutaml/lml/transform"
    autoload :DataProcessor, "lutaml/lml/data_processor"
    autoload :DocumentBuilder, "lutaml/lml/document_builder"
    autoload :ModelCompiler, "lutaml/lml/model_compiler"
    autoload :ImportResolver, "lutaml/lml/import_resolver"
    autoload :ViewResolver, "lutaml/lml/view_resolver"
    autoload :AssociationLabelResolver, "lutaml/lml/association_label_resolver"
    autoload :Executor, "lutaml/lml/executor"
    autoload :YamlParser, "lutaml/lml/yaml_parser"
    autoload :HasAttributes, "lutaml/lml/has_attributes"
    autoload :VERSION, "lutaml/lml/version"

    # Model classes (in Lutaml::Lml namespace, files in models/ directory)
    autoload :Action, "lutaml/lml/models/action"
    autoload :Association, "lutaml/lml/models/association"
    autoload :Cardinality, "lutaml/lml/models/cardinality"
    autoload :Collection, "lutaml/lml/models/collection"
    autoload :Constraint, "lutaml/lml/models/constraint"
    autoload :DataType, "lutaml/lml/models/data_type"
    autoload :Diagram, "lutaml/lml/models/diagram"
    autoload :Document, "lutaml/lml/models/document"
    autoload :Enum, "lutaml/lml/models/enum"
    autoload :Fidelity, "lutaml/lml/models/fidelity"
    autoload :Group, "lutaml/lml/models/group"
    autoload :Instance, "lutaml/lml/models/instance"
    autoload :InstanceCollection, "lutaml/lml/models/instance_collection"
    autoload :InstancesExport, "lutaml/lml/models/instances_export"
    autoload :InstancesImport, "lutaml/lml/models/instances_import"
    autoload :Operation, "lutaml/lml/models/operation"
    autoload :OperationParameter, "lutaml/lml/models/operation_parameter"
    autoload :Package, "lutaml/lml/models/package"
    autoload :PrimitiveType, "lutaml/lml/models/primitive_type"
    autoload :TopElementAttribute, "lutaml/lml/models/top_element_attribute"
    autoload :UmlClass, "lutaml/lml/models/uml_class"
    autoload :Value, "lutaml/lml/models/value"
    autoload :ViewFilter, "lutaml/lml/models/view_filter"
    autoload :ViewImport, "lutaml/lml/models/view_import"

    # Namespaces with their own autoloads
    autoload :Grammar, "lutaml/lml/grammar"
    autoload :Format, "lutaml/lml/format"
  end
end
