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

      # Global scalar normalizer: applied to every leaf in the parse
      # tree (names may legally contain trailing spaces via
      # class_name_chars). Binding is named :value to make the breadth
      # explicit — it is not tied to any one grammar rule.
      rule(simple(:value)) { value.nil? ? value : value.to_s.strip }
    end
  end
end
