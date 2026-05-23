# frozen_string_literal: true

module Lutaml
  module Lml
    module Node
      class ClassNode < Base
        include HasName

        MEMBER_TYPES = {
          field: [Attribute, :attributes],
          method: [Operation, :operations],
          relationship: [Relationship, :relationships],
          class_relationship: [ClassRelationship, :class_relationships]
        }.freeze

        attr_reader :modifier, :members

        def modifier=(value)
          @modifier = value.to_s
        end

        def members=(value)
          @members_by_type = Hash.new { |h, k| h[k] = [] }
          @members = value.to_a.filter_map do |member|
            type = member.keys.first
            entry = MEMBER_TYPES[type]
            next unless entry

            klass, collection_key = entry
            attributes = member.values.first
            attributes[:parent] = self
            node = klass.new(attributes)
            @members_by_type[collection_key] << node
            node
          end
        end

        def attributes
          @members_by_type[:attributes]
        end

        def operations
          @members_by_type[:operations]
        end

        def relationships
          @members_by_type[:relationships]
        end

        def class_relationships
          @members_by_type[:class_relationships]
        end
      end
    end
  end
end
