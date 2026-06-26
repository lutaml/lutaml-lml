# 15 — Add missing specs for shared helpers and load-time wiring

**Status:** ✅ DONE

## Problem

Several behaviors introduced by TODOs 10–14 had no direct test
coverage. Their correctness was only inferred indirectly through
CsvAdapter/XmlAdapter specs, which made regressions hard to localize.

## Add

- `spec/lutaml/lml/executor/adapter_helpers_spec.rb` — direct coverage
  for `Lutaml::Lml::Executor::AdapterHelpers`:
  - `resolve_target_class` — found, missing, empty attributes
  - `attribute_value` — found, missing, nil attributes
  - `find_class_for_instance` — single match, no match, empty instances
- `spec/lutaml/lml/format_autoload_spec.rb` — load-time wiring:
  - `Lutaml::Lml::Format` autoload triggers
  - Accessing `Format` registers `:lml` with `FormatRegistry`
  - `Format::Adapter::StandardAdapter` autoloads
- `spec/lutaml/lml/document_builder_registry_spec.rb` — `DEFAULT_REGISTRY`:
  - Constant exists and is a Hash
  - Maps builder keys to model classes
  - `LmlConverter` is no longer defined (regression guard for TODO 12)

## Standars

- No `double()` — uses real `Lutaml::Lml::TopElementAttribute` instances
  or `Struct`-based stand-ins for lightweight cases.
- Behavior-focused — asserts on outputs, not method-call counts.
