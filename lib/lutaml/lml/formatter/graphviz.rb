# frozen_string_literal: true

require "open3"
require_relative "graphviz/html_builder"
require_relative "graphviz/relationship_formatter"

module Lutaml
  module Formatter
    class Graphviz < Base
      include HtmlBuilder
      include RelationshipFormatter

      class Attributes < Hash
        def to_s
          to_a
            .reject { |(_k, val)| val.nil? }
            .map { |(a, b)| "#{a}=#{b.inspect}" }
            .join(" ")
        end
      end

      ACCESS_SYMBOLS = {
        "public" => "+",
        "protected" => "#",
        "private" => "-",
      }.freeze
      DEFAULT_CLASS_FONT = "Helvetica"

      VALID_TYPES = %i[
        dot xdot ps pdf svg svgz fig png gif jpg jpeg json imap cmapx
      ].freeze

      def initialize(attributes = {})
        super

        @graph = Attributes.new
        @graph["splines"] = "ortho"
        @graph["pad"] = 0.5
        @graph["ranksep"] = "1.2.equally"
        @graph["nodesep"] = "1.2.equally"
        @graph["rankdir"] = "BT"

        @edge = Attributes.new
        @edge["color"] = "gray50"

        @node = Attributes.new
        @node["shape"] = "box"

        @type = :dot
      end

      attr_reader :graph, :edge, :node

      def type=(value)
        super
        @type = :dot unless VALID_TYPES.include?(@type)
      end

      def format(node)
        dot = super.lines.map(&:rstrip).join("\n")
        generate_from_dot(dot)
      end

      def format_attribute(node)
        symbol = ACCESS_SYMBOLS[node.visibility]
        result = "#{symbol}#{node.name}"
        if node.type
          keyword = node.keyword ? "«#{node.keyword}»" : ""
          result += " : #{keyword}#{node.type}"
        end
        if node.cardinality
          result += "[#{node.cardinality.min}..#{node.cardinality.max}]"
        end
        result = escape_html_chars(result)
        result = "<U>#{result}</U>" if node.static
        result
      end

      def format_operation(node)
        symbol = ACCESS_SYMBOLS[node.access]
        result = "#{symbol} #{node.name}"
        if node.arguments
          arguments = node.arguments.map do |argument|
            "#{argument.name}#{" : #{argument.type}" if argument.type}"
          end.join(", ")
        end

        result << "(#{arguments})"
        result << " : #{node.type}" if node.type
        result = "<U>#{result}</U>" if node.static
        result = "<I>#{result}</I>" if node.abstract
        result
      end

      def format_class(node, hide_members)
        name = ["<B>#{node.name}</B>"]
        name.unshift("«#{node.keyword}»") if node.keyword
        name_html = build_name_table(name)

        field_table = format_member_rows(node.attributes, hide_members)
        method_table = format_member_rows(node.operations, hide_members) if node.operations&.any?
        table_body = build_table_body(name_html, field_table, method_table)

        <<~HEREDOC.chomp
          <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="10">
            #{table_body}
          </TABLE>
        HEREDOC
      end

      def format_document(node)
        @fontname = node.fontname || DEFAULT_CLASS_FONT
        @node["fontname"] = "#{@fontname}-bold"

        hide_members, hide_other_classes = extract_fidelity_options(node)
        classes = format_all_classes(node, hide_members)
        associations = build_associations(node, hide_other_classes)

        build_digraph(classes, associations)
      end

      def extract_fidelity_options(node)
        if node.fidelity
          [node.fidelity.hideMembers, node.fidelity.hideOtherClasses]
        else
          [nil, nil]
        end
      end

      def format_all_classes(node, hide_members)
        all_classes = node.classes + node.enums + node.data_types + node.primitives
        all_classes.map do |class_node|
          graph_node_name = generate_graph_name(class_node.name)
          <<~HEREDOC
            #{graph_node_name} [
              shape="plain"
              fontname="#{@fontname || DEFAULT_CLASS_FONT}"
              label=<#{format_class(class_node, hide_members)}>]
          HEREDOC
        end.join("\n")
      end

      def build_associations(node, hide_other_classes)
        associations = collect_all_associations(node)
        associations = sort_by_document_grouping(node.groups, associations) if node.groups
        classes_names = node.classes.map(&:name)
        format_filtered_associations(associations, classes_names, hide_other_classes)
      end

      def collect_all_associations(node)
        node.classes.filter_map(&:associations).flatten + node.associations
      end

      def format_filtered_associations(associations, classes_names, hide_other_classes)
        associations.filter_map do |assoc_node|
          next if hide_other_classes && !classes_names.include?(assoc_node.member_end)
          format_relationship(assoc_node)
        end.join("\n")
      end

      def build_digraph(classes, associations)
        indented_classes = indent_lines(classes)
        indented_assocs = indent_lines(associations)

        <<~HEREDOC
          digraph G {
            graph [#{@graph}]
            edge [#{@edge}]
            node [#{@node}]

          #{indented_classes}

          #{indented_assocs}
          }
        HEREDOC
      end

      def indent_lines(text)
        text.lines.map { |line| "  #{line}" }.join.chomp
      end

      protected

      def generate_from_dot(input)
        Lutaml::Layout::GraphVizEngine.new(input: input).render(@type)
      end

      def generate_graph_name(name)
        name.gsub(/[^0-9a-zA-Z]/i, "")
      end
    end
  end
end
