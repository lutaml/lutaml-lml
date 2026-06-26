# 9 — Add model specs for behavioral coverage

**Status:** ✅ DONE

## What was added

7 new spec files for models with meaningful behavior:
- `uml_class_spec.rb` — attributes, entity_type, YAML round-trip, owner_end inference
- `enum_spec.rb` — defaults, entity_type
- `data_type_spec.rb` — defaults, entity_type
- `association_spec.rb` — ends, cardinality
- `diagram_spec.rb` — attributes, defaults
- `primitive_type_spec.rb` — defaults, entity_type
- `package_spec.rb` — attributes, empty collection defaults

## Problem

16 of 22 model files have no specs. While many are simple data containers
(just attribute definitions), several have meaningful behavior:

- `UmlClass` — YAML serialization, entity_type, owner_end inference
- `Association` — complex attribute structure, used by AssociationLabelResolver
- `Enum` — entity_type, value collection
- `DataType` — entity_type, shared attributes with UmlClass
- `Diagram` — name, definition, diagram_type
- `Package` — nested structure

## Plan

Add behavioral specs for models that have logic beyond plain attribute access:
1. UmlClass — YAML round-trip, entity_type, associations_from_yaml
2. Enum — entity_type, defaults
3. DataType — entity_type
4. Diagram — entity_type, defaults
5. Association — attribute access
6. Package — attribute access

Skip pure data containers (Action, Cardinality, Constraint, Fidelity, Group,
Operation, OperationParameter, Value, ViewFilter, ViewImport) — they have no
behavior beyond what lutaml-model provides.
