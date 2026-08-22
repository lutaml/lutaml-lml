# frozen_string_literal: true

require 'parslet'

module Lutaml
  module Lml
    class Transform < Parslet::Transform
      VISIBILITY_MAP = {
        '-' => 'private',
        '#' => 'protected',
        '~' => 'friendly'
      }.freeze

      rule(visibility_modifier: simple(:visibility_value)) do
        VISIBILITY_MAP.fetch(visibility_value.to_s, 'public')
      end
      # Global scalar normalizer: Parslet applies this to every leaf in
      # the parse tree (names may legally contain trailing spaces via
      # class_name_chars). Binding is named :value to make the breadth
      # explicit — it is not tied to any one grammar rule.
      rule(simple(:value)) { value.nil? ? value : value.to_s.strip }
    end
  end
end
