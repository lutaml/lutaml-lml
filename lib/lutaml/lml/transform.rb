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
      rule(simple(:member)) { member.nil? ? member : member.to_s.strip }
    end
  end
end
