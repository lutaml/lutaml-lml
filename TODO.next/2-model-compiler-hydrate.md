# 2 — ModelCompiler.hydrate — auto-instantiate compiled classes from parsed instances

**Status:** ✅ DONE

`ModelCompiler#hydrate(input)` implemented. Walks the parsed instance tree recursively,
resolves type names (including qualified `Namespace::Type` via `demodulize`),
looks up compiled classes, and creates hydrated objects with correct types.

Forward reference resolution implemented: classes compiled in declaration order,
forward-referenced types deferred and resolved in a second pass.

### Key methods
- `hydrate(input)` — public entry point, returns a hydrated object or hash
- `hydrate_instance(instance)` — recursive instance walker
- `resolve_instance_type(instance)` — extracts type, strips namespace
- `coerce_attribute_value(attr, attr_def)` — handles nested instances, arrays, primitives
- `resolve_forward_references` — second-pass type resolution for forward refs

### Specs
- Hydrates flat instances with primitive attributes
- Hydrates nested instances (array of typed children)
- Hydrates real-world IHO metadata with CompliantStandard nesting
- Returns raw hash for unknown types
- Forward reference resolution (IhoMetadata → CompliantStandard compiled first)
