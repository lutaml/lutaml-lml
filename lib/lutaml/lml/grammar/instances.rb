# frozen_string_literal: true

require "parslet"
require_relative "concerns/instance_rules"
require_relative "concerns/data_structures"

module Lutaml
  module Lml
    module Grammar
      module Instances
        include Parslet
        include Concerns::InstanceRules
        include Concerns::DataStructures

        INSTANCE_KEYWORDS = %w[
          collection
          condition
          export
          extends
          format
          import
          includes
          instance
          instances
          models
          require
          template
          validation
        ].freeze

        INSTANCE_KEYWORDS.each do |keyword|
          rule("kw_#{keyword}") { whitespace? >> str(keyword) }
        end

        # -- Root (Full: diagram + models + instances)
        rule(:diagram) { require_block? >> (models | diagram_definitions | instances | instance) }
      end
    end
  end
end
