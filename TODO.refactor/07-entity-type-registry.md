# 07 - Entity-type registry (stop hardcoding the entity list)

## Status: 🔧 TODO

## Problem

The set of entity types is hardcoded in four places:

- `document_builder.rb:37-49` — `MEMBER_KEY_MAP`
- `pipeline.rb:53-61` — `rebuild_document` names `classes/enums/data_types`
  only → **imported primitives are silently dropped**
- `import_resolver.rb:75-80` — `collect_local_entities` same three,
  primitives dropped
- `models/document.rb:34-42` — `all_classes` / `classifiable_classes`
  re-list them

Every model class already declares `self.entity_type`
(`uml_class.rb:79`, `enum.rb:23`, `data_type.rb:26`,
`primitive_type.rb:21`) — the single source of truth exists but is
unused by these call sites.

## Solution

`Lutaml::Lml::EntityTypes` registry module:

    EntityTypes.all          # [UmlClass, Enum, DataType, PrimitiveType]
    EntityTypes.by_symbol    # { classes: UmlClass, enums: Enum, ... }
    EntityTypes.classifiable # excludes Enum (no own associations)

- `rebuild_document` iterates `by_symbol` (fixes primitives drop).
- `collect_local_entities` iterates `EntityTypes.all`.
- `Document#all_classes` / `classifiable_classes` iterate the registry.
- `classifiable?` declared per model class (Enum → false, others true)
  so the classification lives with the model, not in a consumer.

## Files

- `lib/lutaml/lml/entity_types.rb` (new)
- `lib/lutaml/lml.rb` (autoload)
- `lib/lutaml/lml/pipeline.rb`
- `lib/lutaml/lml/import_resolver.rb`
- `lib/lutaml/lml/models/document.rb`
- `lib/lutaml/lml/models/enum.rb` (+ classifiable? on the others)
- `spec/lutaml/lml/entity_types_spec.rb` (new; incl. primitives
  survive a view import)

## Verification

`bundle exec rspec spec/lutaml/lml/entity_types_spec.rb spec/lutaml/lml/view_spec.rb`
