# frozen_string_literal: true

module Lutaml
  module Formatter
    # ELK-layout diagram formatter: builds an Elkrb::Graph from the
    # document, lays it out in-process (no external tools) and emits SVG,
    # or converts the SVG to PS/EPS/EMF through vectory.
    class Elk
      VALID_TYPES = %i[svg ps eps emf].freeze

      attr_reader :type

      def initialize(_attributes = {})
        @type = :svg
      end

      def type=(value)
        @type = value.to_sym
        return if VALID_TYPES.include?(@type)

        raise ArgumentError,
              "unsupported output type #{@type.inspect} (valid: #{VALID_TYPES.join(', ')})"
      end

      def format(document)
        graph = Lutaml::Layout::ElkGraphBuilder.new.build(document)
        svg = Lutaml::Layout::ElkEngine.new(input: graph).render(:svg)
        @type == :svg ? svg : convert(svg)
      end

      private

      def convert(svg)
        require 'vectory'
        Vectory::Svg.new(svg).public_send(:"to_#{@type}").content
      rescue LoadError
        raise Error, 'The vectory gem is required for PS/EPS/EMF output: ' \
                     'add `gem "vectory"` to your Gemfile'
      end
    end
  end
end
