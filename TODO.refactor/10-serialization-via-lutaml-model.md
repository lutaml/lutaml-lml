# 10 - Definition unescaping via lutaml-model type (kill 3× hand-rolled copies)

## Status: 🔧 TODO

## Problem

The `definition` unescape (`gsub(/\\}/, '}').gsub(/\\{/, '{')` + line
strip/join) is hand-rolled in three places for the same content:

- `models/uml_class.rb:66-77` — `definition_to_yaml` /
  `definition_from_yaml` custom mapping methods
- `document_builder.rb:82-85` — `sanitize_definition`
- `lutaml-uml/lib/lutaml/uml/document.rb` (same pattern, other repo)

`models/uml_class.rb:50-64` — `associations_to_yaml` /
  `associations_from_yaml`: the `from` side injects
  `owner_end = model.name` when absent. That is semantic enrichment
  (an association defaults its owner to the containing entity), not
  serialization — it belongs in the builder where the container is
  known, not in a YAML mapping proc.

## Solution

1. Register a custom lutaml-model type:

       class TextType < Lutaml::Model::Type::String
         def self.cast(value) = unescape/strip/normalize (value)
       end
       Lutaml::Model::Type.register(:lml_text, TextType)

   `UmlClass` declares `attribute :definition, :lml_text`; the yaml
   mapping drops its `with:` block. `DocumentBuilder#sanitize_definition`
   is deleted — assignment through the attribute setter casts.

2. `owner_end` defaulting moves to `DocumentBuilder#add_members`,
   which knows the containing model. The `associations` mapping drops
   its `with:` block.

## Files

- `lib/lutaml/lml/types/text_type.rb` (new)
- `lib/lutaml/lml.rb` (autoload + registration)
- `lib/lutaml/lml/models/uml_class.rb`
- `lib/lutaml/lml/document_builder.rb`
- `spec/lutaml/lml/types/text_type_spec.rb` (new)
- `spec/lutaml/lml/round_trip_spec.rb` (must stay green)

## Verification

`bundle exec rspec spec/lutaml/lml/round_trip_spec.rb spec/lutaml/lml/types`
— round-trip through YAML must be unchanged.
