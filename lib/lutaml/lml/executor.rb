# frozen_string_literal: true

module Lutaml
  module Lml
    # Orchestrates instance data I/O: import external data, validate
    # collections, and export to external formats.
    #
    # Format-specific I/O is delegated to registered adapters via the
    # FormatAdapter registry. The core executor only handles the
    # orchestration — it knows *what* to do, adapters know *how*.
    #
    # Usage:
    #   compiled = ModelCompiler.new.compile(models_file)
    #   doc = Pipeline.call(instances_file, resolve: false)
    #   instances = Executor.run(doc, compiled: compiled)
    #
    class Executor
      autoload :FormatAdapter, "lutaml/lml/executor/format_adapter"
      autoload :AdapterHelpers, "lutaml/lml/executor/adapter_helpers"
      autoload :CsvAdapter, "lutaml/lml/executor/csv_adapter"
      autoload :XmlAdapter, "lutaml/lml/executor/xml_adapter"
      autoload :ConditionEvaluator, "lutaml/lml/executor/condition_evaluator"

      attr_reader :compiled

      def initialize(compiled:)
        @compiled = compiled
      end

      # Run the full import/validate/export cycle on a parsed document.
      # Returns an array of hydrated instance objects.
      def self.run(doc, compiled:)
        new(compiled: compiled).run(doc)
      end

      def run(doc)
        instances = run_imports(doc)
        validate_collections(doc, instances)
        run_exports(doc, instances)
        instances
      end

      private

      # --- Import ---

      def run_imports(doc)
        return [] unless doc.instances&.imports&.any?

        doc.instances.imports.flat_map { |imp| import_one(imp) }
      end

      def import_one(imp)
        adapter = FormatAdapter.resolve(imp.format_type)
        adapter.import(imp, compiled: @compiled)
      rescue FormatAdapter::AdapterNotFoundError
        []
      end

      # --- Collection validation ---

      def validate_collections(doc, instances)
        return unless doc.instances&.collections

        collection = doc.instances.collections
        return unless collection.is_a?(Collection)

        ConditionEvaluator.evaluate(collection, instances)
      end

      # --- Export ---

      def run_exports(doc, instances)
        return unless doc.instances&.exports&.any?

        doc.instances.exports.each do |exp|
          export_one(exp, instances)
        end
      end

      def export_one(exp, instances)
        adapter = FormatAdapter.resolve(exp.format_type)
        adapter.export(exp, instances, compiled: @compiled)
      rescue FormatAdapter::AdapterNotFoundError
        nil
      end
    end
  end
end
