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

      # Global scalar normalizer: applied to every leaf in the parse
      # tree (names may legally contain trailing spaces via
      # class_name_chars). Binding is named :value to make the breadth
      # explicit — it is not tied to any one grammar rule.
      rule(simple(:value)) { value.nil? ? value : value.to_s.strip }
    end
  end
end
