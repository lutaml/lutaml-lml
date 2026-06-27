# frozen_string_literal: true

require "parslet"
require "parslet/convenience"

module Lutaml
  module Lml
    class Parser < Parslet::Parser
      include Grammar::Full

      root(:diagram)

      def self.parse(io)
        Pipeline.call(io)
      end

      def self.parse_document(io)
        Pipeline.call(io, resolve: false)
      end
    end
  end
end
