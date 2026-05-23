# frozen_string_literal: true

module Lutaml
  module Lml
    module Node
      class ClassNode < Base
        include HasName

        MEMBER_TYPES = {
          field: Attribute,
          method: Operation,
          relationship: Relationship,
          class_relationship: ClassRelationship
        }.freeze

        attr_reader :modifier, :members

        def modifier=(value)
          @modifier = value.to_s
        end

        def members=(value)
          @members = value.to_a.filter_map do |member|
            type = member.keys.first
            klass = MEMBER_TYPES[type]
            next unless klass

            attributes = member.values.first
            attributes[:parent] = self
            klass.new(attributes)
          end
        end

        def attributes
          @members.select { |member| member.instance_of?(Attribute) }
        end

        def operations
          @members.select { |member| member.instance_of?(Operation) }
        end

        def relationships
          @members.select { |member| member.instance_of?(Relationship) }
        end

        def class_relationships
          @members.select { |member| member.instance_of?(ClassRelationship) }
        end
      end
    end
  end
end
