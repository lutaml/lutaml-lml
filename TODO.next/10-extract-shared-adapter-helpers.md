# 10 — Extract shared format-adapter helpers

**Status:** ✅ DONE

## Problem

`CsvAdapter` and `XmlAdapter` duplicate two helpers verbatim:

- `resolve_target_class(attributes, compiled)` — finds the `map_to`
  attribute and resolves the compiled-class key
- `extract_attribute(attributes, name)` — generic name → value lookup
  over a `TopElementAttribute` collection

Both adapters also repeat the pattern of guarding on `imp.attributes&.any?`
and walking the same `Array(attributes).find { ... }` shape.

This violates DRY and MECE — the "how to read an import attribute list"
concern has no single home, so each adapter reinvents it.

## Fix

Extract a single `AdapterHelpers` module under `Executor::` and mix it
into both adapters. The module owns three concerns:

1. **Class resolution** — `resolve_target_class(attributes, compiled)`
2. **Attribute lookup** — `find_attribute(attributes, name)` returns the
   `TopElementAttribute` (or nil); `attribute_value(attributes, name)`
   returns its string value
3. **Instance → class lookup** — `find_class_for_instance(instances, compiled)`
   returns `[class_name, klass]` so export code doesn't duplicate the
   `compiled.values.find { |k| inst.is_a?(k) }` walk

Both adapters now delegate to these helpers. No behavior change.

## Files

- `lib/lutaml/lml/executor/adapter_helpers.rb` (new) — shared module
- `lib/lutaml/lml/executor.rb` — autoload `AdapterHelpers`
- `lib/lutaml/lml/executor/csv_adapter.rb` — include + delegate
- `lib/lutaml/lml/executor/xml_adapter.rb` — include + delegate

## Specs

`spec/lutaml/lml/executor/adapter_helpers_spec.rb` (new) — exercises the
helpers directly via a lightweight struct-based `TopElementAttribute`
stand-in, covering:

- `resolve_target_class` — found, missing, nil attributes
- `attribute_value` — found, missing, nil
- `find_class_for_instance` — single match, no match
