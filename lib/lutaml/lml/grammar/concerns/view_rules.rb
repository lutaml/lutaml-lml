# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        module ViewRules
          include Parslet

          rule(:view_import_keyword) { str("import") >> spaces }

          rule(:view_import) do
            view_import_keyword >>
              str('"') >> (str('"').absent? >> any).repeat.as(:path) >> str('"') >>
              whitespace?
          end

          rule(:entity_name_list) do
            class_name.as(:entity_name) >>
              (spaces? >> str(",") >> spaces? >> class_name.as(:entity_name)).repeat
          end

          rule(:show_directive) do
            str("show") >> spaces >> entity_name_list.as(:show_list) >> whitespace?
          end

          rule(:hide_directive) do
            str("hide") >> spaces >> entity_name_list.as(:hide_list) >> whitespace?
          end
        end
      end
    end
  end
end
