# frozen_string_literal: true

require "parslet"
require "parslet/convenience"

module Lutaml
  module Lml
    class Pipeline
      def self.call(input, resolve: true)
        new(input, resolve: resolve).call
      end

      def initialize(input, resolve: true)
        @input = input
        @resolve = resolve
      end

      def call
        data = Preprocessor.call(@input)
        hash = parse_raw(data)
        hash = DataProcessor.process(hash)
        document = build_document(hash)
        if @resolve
          document = resolve_document(document)
          AssociationLabelResolver.new.enrich(document)
        end
        document
      end

      private

      def parse_raw(data)
        reporter = Parslet::ErrorReporter::Deepest.new
        Transform.new.apply(Parser.new.parse(data, reporter: reporter))
      rescue Parslet::ParseFailed => e
        raise(ParsingError,
              "#{e.message}\ncause: #{e.parse_failure_cause.ascii_tree}")
      end

      def build_document(hash)
        DocumentBuilder.new(DocumentBuilder::DEFAULT_REGISTRY).build(:document, hash)
      end

      def resolve_document(document)
        return document unless document.view_imports&.any?

        base_path = @input.is_a?(StringIO) ? nil : @input.path
        entities, associations = ImportResolver.new(base_path).resolve(document)
        entities, associations = ViewResolver.new.resolve(document, entities, associations)
        rebuild_document(document, entities, associations)
      end

      def rebuild_document(document, entities, associations)
        grouped = entities.group_by { |e| e.class.entity_type }

        document.classes = grouped[:classes] || []
        document.enums = grouped[:enums] || []
        document.data_types = grouped[:data_types] || []
        document.associations = associations
        document
      end
    end
  end
end
