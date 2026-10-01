# frozen_string_literal: true

require 'parsanol'

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
        Transform.new.apply(Parser.new.parse(data))
      rescue Parsanol::ParseFailed => e
        raise(ParsingError, failure_message(e))
      end

      # Parsanol releases up to 1.3.57 annotate native failures with a
      # byte offset marker but report cause.position as 0; fixed parsanol
      # already carries the correct location in the message. Only
      # rebuild the location when the marker is present.
      def failure_message(error)
        detail = error.message.lines.first.to_s.strip
        cause = error.parse_failure_cause
        offset = error.message[/@@parsanol_pos:(\d+)/, 1]&.to_i
        location =
          if offset && cause&.source
            line, column = cause.source.line_and_column(offset)
            " at line #{line} char #{column}."
          end
        "#{detail}#{location}\ncause: #{cause&.ascii_tree}"
      end

      def build_document(hash)
        DocumentBuilder.new(DocumentBuilder::DEFAULT_REGISTRY).build(:document, hash)
      end
    end
  end
end
