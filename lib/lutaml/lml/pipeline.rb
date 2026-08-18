# frozen_string_literal: true

require "parslet"
require "parslet/convenience"

module Lutaml
  module Lml
    # Parse pipeline only: preprocess → parse → transform → process →
    # build. View resolution and label enrichment are a separate,
    # explicit post-parse step (ViewResolution) — file I/O for imports
    # does not belong inside parsing.
    class Pipeline
      def self.call(input)
        new(input).call
      end

      def initialize(input)
        @input = Source.wrap(input)
      end

      def call
        data = Preprocessor.call(@input)
        hash = parse_raw(data)
        hash = DataProcessor.process(hash)
        build_document(hash)
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
    end
  end
end
