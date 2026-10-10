# frozen_string_literal: true

require 'parsanol'

module Lutaml
  module Lml
    class Transform < Parsanol::Transform
      VISIBILITY_MAP = {
        '-' => 'private',
        '#' => 'protected',
        '~' => 'package'
      }.freeze

      rule(visibility_modifier: simple(:visibility_value)) do
        VISIBILITY_MAP.fetch(visibility_value.to_s, 'public')
      end
      # An empty `until` capture is an empty sequence, not an empty
      # string: `""` parses the dq_string body as [] (parsanol
      # repetition semantics). A present, zero-length string value is
      # distinct from an absent one (RS 3001 §String values); only the
      # :string capture is normalized, other empty sequences stay [].
      rule(string: sequence(:empty_string)) { { string: '' } }

      # RS 3001 §String values: the only two escapes are backslash-quote
      # and backslash-backslash (the grammar rejects every other
      # backslash), so unescaping is removing the backslash before
      # those two characters.
      rule(string: simple(:escaped)) { { string: Lutaml::Lml::Transform.unescape(escaped.to_s) } }

      # Rule blocks evaluate in a Parsanol::Context, so this helper is
      # a class method the block reaches through the class.
      # @param body [String] raw string body as captured between quotes
      # @return [String] the value with \" and \\ resolved
      def self.unescape(body)
        body.gsub(/\\(["'\\])/) { Regexp.last_match(1) }
      end

      # Global scalar normalizer: every leaf becomes a string (or stays
      # nil). No stripping — name and type tokens are interior-bounded
      # in the grammar (class_run/type_run/quoted_name_run), so quoted
      # string values keep their padding verbatim (RS 3001 §String
      # values).
      rule(simple(:value)) { value.nil? ? value : value.to_s }

      # Block captures (definition bodies, block comments) read their
      # surrounding layout as content — a block's first line break and
      # closing indentation are layout, not prose. parsanol only fires
      # hash-keyed rules at selected tree positions, so the strip is a
      # post-pass walk, not a rule.
      BLOCK_KEYS = %i[definition comments].freeze

      def apply(tree, context = nil)
        strip_block_layout(super)
      end

      def strip_block_layout(node)
        case node
        when Hash
          node.each_with_object({}) do |(key, value), result|
            result[key] = if BLOCK_KEYS.include?(key) && value.is_a?(String)
                            value.strip
                          else
                            strip_block_layout(value)
                          end
          end
        when Array then node.map { |item| strip_block_layout(item) }
        else node
        end
      end
    end
  end
end
