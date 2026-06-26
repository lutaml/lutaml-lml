# 18 — Add `Document#all_classes` helper

**Status:** ✅ DONE

## Problem

Three call sites perform the same concatenation walk over the four
entity collections on `Document`:

- `lib/lutaml/lml/association_label_resolver.rb:18`
  ```ruby
  all_classes = document.classes + document.enums + document.data_types + document.primitives
  ```
- `lib/lutaml/lml/formatter/graphviz/document_formatter.rb:27` (same)
- `lib/lutaml/lml/formatter/graphviz/document_formatter.rb:47`
  ```ruby
  class_level = (node.classes + node.data_types + node.primitives)
  ```

DRY violation. The "give me all class-like entities" concern lives on
Document, not on each consumer.

## Fix

Add `Document#all_classes` (returns `classes + enums + data_types +
primitives`). Add `Document#classifiable_classes` (returns `classes +
data_types + primitives`, matching the existing exclusion of enums used
by `DocumentFormatter#collect_all_associations`).

Update the three call sites to use the helpers.

## Files

- `lib/lutaml/lml/models/document.rb` — add two methods
- `lib/lutaml/lml/association_label_resolver.rb` — use `all_classes`
- `lib/lutaml/lml/formatter/graphviz/document_formatter.rb` — use both

## Why

- Single source of truth for "what counts as a class-like entity"
- If a new entity type is added (e.g. interfaces), one method changes
  instead of three
- Encapsulation — callers don't need to know which collections exist
