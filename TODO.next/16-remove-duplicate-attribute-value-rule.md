# 16 — Remove duplicate `attribute_value` grammar rule

**Status:** ✅ DONE

## Problem

`rule(:attribute_value)` is defined in **two** concerns:

- `lib/lutaml/lml/grammar/concerns/primitives.rb`:
  ```ruby
  rule(:attribute_value) { key_value_map | value | match("[^\n]").repeat(1) }
  ```
- `lib/lutaml/lml/grammar/concerns/data_structures.rb`:
  ```ruby
  rule(:attribute_value) { instance | list | key_value_map | value | match("[^\n]").repeat(1) }
  ```

Parslet's `rule()` overrides on redefinition. The include order is
`Primitives → ... → DataStructures`, so the `DataStructures` version wins
and the `Primitives` version is dead code. Worse: the `Primitives`
version is missing `instance | list`, so anyone reading just
`primitives.rb` will think attribute values can't be lists or instances.

This is a DRY violation and a semantic trap.

## Fix

Delete the override from `primitives.rb`. `DataStructures` owns the
complete definition.

## Files

- `lib/lutaml/lml/grammar/concerns/primitives.rb` — drop `attribute_value`
