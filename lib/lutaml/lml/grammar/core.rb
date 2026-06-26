# frozen_string_literal: true

require "parslet"

module Lutaml
  module Lml
    module Grammar
      module Core
        include Parslet
        include Concerns::Primitives
        include Concerns::Attributes
        include Concerns::Associations
        include Concerns::Definitions
        include Concerns::ViewRules

        CORE_KEYWORDS = %w[
          abstract
          aggregation
          association
          attribute
          bidirectional
          caption
          class
          composition
          data_type
          dependency
          diagram
          directional
          enum
          fontname
          generalizes
          include
          interface
          member
          member_type
          method
          owner
          owner_type
          primitive
          private
          protected
          public
          realizes
          static
          title
          view
        ].freeze

        CORE_KEYWORDS.each do |keyword|
          rule("kw_#{keyword}") { whitespace? >> str(keyword) }
        end

        # === Require statements ===
        rule(:require_stmt) do
          kw_require >> spaces >> quoted_string.as(:require) >> whitespace?
        end

        rule(:require_block) do
          (require_stmt >> whitespace?).repeat.as(:requires)
        end

        rule(:require_block?) do
          require_block.maybe
        end

        # -- Root (Core: diagram only)
        rule(:diagram) { require_block? >> diagram_definitions }
      end
    end
  end
end
