# frozen_string_literal: true

require "parslet"
require "parslet/convenience"

module Lutaml
  module Lml
    class Parser < Parslet::Parser
      include Grammar::Full
      include LmlConverter
      include DataProcessor

      def self.parse(io, options = {})
        new.parse(io, options)
      end

      def parse(input_file, _options = {})
        data = Preprocessor.call(input_file)
        reporter = Parslet::ErrorReporter::Deepest.new
        hash = Transform.new.apply(super(data, reporter: reporter))
        process_data(hash)
        create_document(hash)
      rescue Parslet::ParseFailed => e
        raise(ParsingError,
              "#{e.message}\ncause: #{e.parse_failure_cause.ascii_tree}")
      end

      root(:diagram)
    end
  end
end
