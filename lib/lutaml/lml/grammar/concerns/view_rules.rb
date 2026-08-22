# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module ViewRules
          include Parslet

          # View-scoped keyword rules. `import` is named view_import to
          # stay MECE with the instances-block kw_import keyword. The
          # trailing `spaces` is the word boundary: `important` fails to
          # match rather than parsing as `import`.
          VIEW_KEYWORDS = {
            "view_import" => "import",
            "show" => "show",
            "hide" => "hide",
          }.freeze

          VIEW_KEYWORDS.each do |rule_name, keyword|
            rule("kw_#{rule_name}") { whitespace? >> str(keyword) >> spaces }
          end

          rule(:view_import) do
            kw_view_import >>
              str('"') >> quoted_string_content.as(:path) >> str('"') >>
              whitespace?
          end

          # Entity names in show/hide lists must be space-free: general
          # class_name_chars allows spaces, which would swallow a
          # following directive (`show Foo, Bar hide Baz` would parse
          # "Bar hide Baz" as one name).
          rule(:entity_name_atom) do
            match('[a-zA-Z0-9_.:\-]').repeat(1).as(:entity_name)
          end

          rule(:entity_name_list) do
            entity_name_atom >>
              (spaces? >> str(",") >> spaces? >> entity_name_atom).repeat
          end

          rule(:show_directive) do
            kw_show >> entity_name_list.as(:show_list) >> whitespace?
          end

          rule(:hide_directive) do
            kw_hide >> entity_name_list.as(:hide_list) >> whitespace?
          end
        end
      end
    end
  end
end
