# frozen_string_literal: true

module Lutaml
  module Lml
    class ViewResolver
      def resolve(document, entities, associations)
        visible = apply_filters(document, entities)
        filtered_associations = filter_associations(associations, visible)

        [visible, filtered_associations]
      end

      private

      def apply_filters(document, entities)
        names = entities.each_with_object({}) { |e, h| h[e.name] = e }

        names = apply_show_filter(names, document.show_filter)
        names = apply_hide_filter(names, document.hide_filter)

        names.values
      end

      def apply_show_filter(names, filter)
        return names unless filter

        show_set = filter.entity_names.to_set
        names.select { |name, _| show_set.include?(name) }
      end

      def apply_hide_filter(names, filter)
        return names unless filter

        hide_set = filter.entity_names.to_set
        names.reject { |name, _| hide_set.include?(name) }
      end

      def filter_associations(associations, visible_entities)
        visible_names = visible_entities.map(&:name).to_set
        associations.select do |assoc|
          owner_visible = visible_names.include?(assoc.owner_end.to_s)
          member_visible = visible_names.include?(assoc.member_end.to_s)
          owner_visible && member_visible
        end
      end
    end
  end
end
