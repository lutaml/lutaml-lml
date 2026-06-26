# 7 — Fix CSV adapter + model definitions

**Status:** ✅ DONE

## What was fixed

1. **`InstancesImport#attributes`** — changed from single `TopElementAttribute`
   to collection with default `[]`, matching `InstancesExport`'s definition.
   Import needs multiple attribute entries (map_to + column headers).

2. **`CsvAdapter#export`** — replaced `compiled.keys` (class names) with
   derived attribute names from the target class. Now uses `is_a?` to find
   the matching compiled class and reads its `attributes.keys` for CSV headers.

3. **Spec fixture path** — `../../fixtures/` resolved to `spec/lutaml/fixtures/`
   instead of `spec/fixtures/`. Fixed to `../../../fixtures/`.

4. **Bare rescue** — `inst.public_send(f) rescue nil` replaced with
   `extract_attribute_value` method that catches `NoMethodError` specifically.

5. **Doubles removed** — `condition_evaluator_spec.rb` used `double("a")` for
   simple count-based tests. Replaced with `Struct.new(:id)` instances.

6. **Added specs** — 4 new test cases: empty attributes guard, column remapping,
   empty instances guard, no file attribute guard.
