# 4 — Fix format adapter for nested instance round-trip

**Status:** ✅ DONE

### What was fixed

**to_lml side:**
- `StandardAdapter#to_lml` includes type names (`__type__`) for nested Hash
  instances and arrays of Hash instances
- `format_nested` and `format_nested_instance` extract `__type__` and emit
  `instance TypeName { ... }` instead of bare `instance { ... }`
- `__type__` is filtered from the body output (not emitted as an attribute)
- `hash_to_lml_body` refactored into focused methods (`format_value`, `format_array`,
  `format_nested`, `format_nested_instance`) — OCP-compliant dispatch

**from_lml side (newly completed):**
- Grammar (`concerns/instance_rules.rb`): `keyword_instance` now accepts an
  optional type — `instance { ... }` and `instance Type { ... }` both parse
- Grammar (`concerns/data_structures.rb`): `attribute_value` now accepts
  `instance` directly (not just inside `[...]` lists), enabling
  `attr = instance { ... }` nested assignment
- DataProcessor (`attribute_processing.rb`): `convert_instance_type` no longer
  destructures Hash values via `Array(hash)` — wraps single-instance hashes
  in an array instead, preserving the hash structure for typed hydration
- StandardAdapter (`standard_adapter.rb`): `instance_to_hash` unwraps
  single-element instance arrays to a single Hash, so non-collection typed
  attributes (e.g. `attribute :address, AddressClass`) hydrate correctly

### Typed round-trip verified

```ruby
address = Class.new(Lutaml::Model::Serializable) do
  attribute :street, :string
  lml { map :street, to: :street }
end
person = Class.new(Lutaml::Model::Serializable) do
  attribute :name, :string
  attribute :address, address   # single typed attribute
  lml { map :name, to: :name; map :address, to: :address }
end

original = person.new(name: "Alice", address: address.new(street: "Main"))
restored = person.from_lml(original.to_lml)
restored.address.street  # => "Main" (typed AddressClass instance)
```

Collections also round-trip: `items = [ instance {...}, instance {...} ]`
hydrates to `Array` of typed instances.

### Known limitation

A collection with exactly one element loses its array-ness on round-trip
through the untyped StandardAdapter path, because `instance_to_hash` unwraps
single-element arrays. This does not affect the typed `from_lml` path for
non-collection attributes. Collection attributes with one element should use
the typed model path directly.

### Specs
- Nested Hash with `__type__` preserves type name in output
- Array of nested Hashes preserves type names
- Nested Hash without `__type__` outputs bare `instance { ... }`
- Flat round-trip still works (primitives, floats, booleans)
- Typed nested single instance round-trips through from_lml/to_lml
- Typed nested collection round-trips through from_lml/to_lml
