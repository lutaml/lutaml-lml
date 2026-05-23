# frozen_string_literal: true

module Lutaml
  module Formatter
    class Graphviz < Base
      module RelationshipFormatter
        ARROW_TYPES = {
          "composition" => "diamond",
          "aggregation" => "odiamond",
          "direct" => "vee"
        }.freeze

        DASHED_TYPES = %w[dependency realizes].freeze

        def format_relationship(node)
          graph_parent_name = generate_graph_name(node.owner_end)
          graph_node_name = generate_graph_name(node.member_end)
          attributes = build_edge_attributes(node)
          graph_attributes = " [#{attributes}]" unless attributes.empty?

          "#{graph_parent_name} -> #{graph_node_name}#{graph_attributes}"
        end

        def build_edge_attributes(node)
          attrs = Attributes.new

          apply_edge_style(attrs, node)
          apply_edge_direction(attrs, node)
          apply_edge_labels(attrs, node)
          apply_arrow_types(attrs, node)
          maybe_swap_labels(attrs)

          attrs
        end

        def format_label(name, cardinality = nil)
          res = "+#{name}"
          return res if cardinality.nil? || cardinality.min.nil? || cardinality.max.nil?

          "#{res} #{cardinality.min}..#{cardinality.max}"
        end

        def sort_by_document_grouping(groups, associations)
          result = []
          groups.each do |group|
            group.values.each do |group_name|
              associations
                .select { |assc| assc.owner_end == group_name }
                .each { |association| result.push(association) unless result.include?(association) }
            end
          end
          associations.each { |association| result.push(association) unless result.include?(association) }
          result
        end

        private

        def apply_edge_style(attrs, node)
          attrs["style"] = "dashed" if DASHED_TYPES.include?(node.member_end_type)
        end

        def apply_edge_direction(attrs, node)
          attrs["dir"] = if node.owner_end_type && node.member_end_type
                           "both"
                         elsif node.owner_end_type
                           "back"
                         else
                           "direct"
                         end
        end

        def apply_edge_labels(attrs, node)
          if node&.action&.verb
            attrs["label"] = node.action.verb
          end

          case node&.action&.direction
          when "target"
            attrs["label"] = "#{attrs['label']} ▶"
          when "source"
            attrs["label"] = "◀ #{attrs['label']}"
          end

          if node.owner_end_attribute_name
            attrs["headlabel"] = format_label(
              node.owner_end_attribute_name, node.owner_end_cardinality
            )
          end
          if node.member_end_attribute_name
            attrs["taillabel"] = format_label(
              node.member_end_attribute_name, node.member_end_cardinality
            )
          end
        end

        def apply_arrow_types(attrs, node)
          attrs["arrowtail"] = ARROW_TYPES.fetch(node.owner_end_type, "onormal")
          attrs["arrowhead"] = ARROW_TYPES.fetch(node.member_end_type, "onormal")
        end

        def maybe_swap_labels(attrs)
          return unless attrs["dir"] == "back" && attrs["arrowtail"] != "vee"

          attrs["arrowhead"], attrs["arrowtail"] = [attrs["arrowtail"], attrs["arrowhead"]]
          attrs["headlabel"], attrs["taillabel"] = [attrs["taillabel"], attrs["headlabel"]]
        end
      end
    end
  end
end
