# frozen_string_literal: true

module Lutaml
  module Formatter
    # ELK-layout diagram formatter: builds an Elkrb::Graph from the
    # document, lays it out in-process (no external tools) and emits SVG.
    class Elk
      VALID_TYPES = %i[svg].freeze

      attr_reader :type

      def initialize(_attributes = {})
        @type = :svg
      end

      def format(document)
        graph = Lutaml::Layout::ElkGraphBuilder.new.build(document)
        Lutaml::Layout::ElkEngine.new(input: graph).render(@type)
      end
    end
  end
end
