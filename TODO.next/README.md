# TODO.next — Post-0.1.0 Cleanup

Investigation-driven refactor items found after the 0.1.0 release. Each
item cites file:line, what's wrong, why it matters, and the fix shape.
Items are ordered by impact, lowest-risk first.

## Done criteria

- Behavior preserved (existing specs stay green; new specs cover changes)
- No `require_relative`, no `double()`, no `respond_to?`, no `send` on
  private methods, no hand-rolled `to_h`/`from_h`
- One commit per TODO item, conventional-commit message
- Branch `refactor/post-release-cleanup` → PR → green GHA

---

## T1 — Remove dead code (low risk, no behavior change)

### T1.1 Preprocessor dead regex guard
**File:** `lib/lutaml/lml/preprocessor.rb:41`
**Code:** `return line if include_path_match.nil? || line =~ /^\s\*\*/`
**Why dead:** The first clause already returns when the line isn't an
`include` directive. The second clause matches "exactly one whitespace
then two asterisks" — a markdown-bold pattern that cannot coexist with
`include` on the same line. It is a typo for `/^\s*\*\*/` or similar
and was never reachable.
**Fix:** Delete the `|| line =~ /^\s\*\*/` clause.

### T1.2 StandardAdapter#initialize no-op override
**File:** `lib/lutaml/lml/format/adapter/standard_adapter.rb:18-20`
**Code:** `def initialize(attributes = {}, **options); super; end`
**Why dead:** The method body is `super` with the same args. The
default behavior would be identical. Dead scaffolding.
**Fix:** Delete the method.

### T1.3 Formatter::Base#format redundant control flow
**File:** `lib/lutaml/lml/formatter/base.rb:58-63`
**Code:**
```ruby
def format(node)
  result = dispatch_format(node)
  return unless result
  result
end
```
**Why dead:** `return unless result; result` is equivalent to
`dispatch_format(node)` (Ruby implicitly returns the last expression,
and `dispatch_format` already returns `nil` when no handler matches).
**Fix:** Collapse to `dispatch_format(node)`.

---

## T2 — Preprocessor: rescue Errno::EACCES (consistency)

**File:** `lib/lutaml/lml/preprocessor.rb:47` (rescues only `Errno::ENOENT`)
**Inconsistency:** `ImportResolver` rescues both `Errno::ENOENT` and
`Errno::EACCES` (lines 52, 63, 71). Preprocessor only handles missing
files, not unreadable ones — an unreadable include aborts the whole parse.
**Fix:** Broaden the rescue to `Errno::ENOENT, Errno::EACCES` and emit
the same warning shape as ImportResolver.

---

## T3 — Extract Instance attribute walker (DRY, model-driven)

**Files:**
- `lib/lutaml/lml/model_compiler.rb:142-152` (`extract_raw_attributes`)
- `lib/lutaml/lml/model_compiler.rb:164-172` (`coerce_attribute_value`)
- `lib/lutaml/lml/format/adapter/standard_adapter.rb:37-46` (`instance_to_hash`)

**Duplication:** All three implement the identical shape:
```
walk instance.attributes; for each attr:
  if attr.instances.any? -> recurse on each
  elif attr.value.is_a?(Array) -> array of values
  elif !attr.value.nil? -> single value
```
**Why model-driven matters:** Instance owns its own structure. Forcing
every caller to know about `attr.instances` vs `attr.value` vs
`attr.value.is_a?(Array)` leaks the model's internal shape.
**Fix:** Add `Instance#each_attribute` that yields
`(name, primitive_value, nested_instances)` triplets. All three callers
reduce using the triplet; the conditional lives in exactly one place.

---

## T4 — Refactor ModelCompiler#validate (OCP, performance)

**File:** `lib/lutaml/lml/model_compiler.rb:46-61`
**Smells:**
- `is_a?(String) || is_a?(IO) || is_a?(StringIO)` appears twice
- `Pipeline.call` may run twice (once at line 50, again at line 56) for
  the case where neither `compiled:` nor the type-check branch fires
- Method has five branches: with-compiled, type-check, instance,
  fallback re-parse, no-instance

**Fix:** Split into two public methods:
- `validate_document(doc)` — takes a parsed Document, walks instances
- `validate_input(input)` — runs Pipeline once, delegates to above

Eliminate the second `Pipeline.call` entirely. The instance-shape
branch (`is_a?(Lutaml::Lml::Instance)`) becomes its own
`validate_instance_object(instance)` for callers that already hold one.

---

## T5 — Surface executor errors (don't swallow)

**File:** `lib/lutaml/lml/executor.rb:53-58, 81-86, 62-69`
**Smells:**
- `import_one` rescues `AdapterNotFoundError` → `[]` (silent)
- `export_one` rescues `AdapterNotFoundError` → `nil` (silent)
- `validate_collections` calls `ConditionEvaluator.evaluate` and
  discards the returned errors

**Why it matters:** A typo in `format_type` produces zero output and
zero error — a debugging black hole. Validation errors are computed
and thrown away.
**Fix:** Let `AdapterNotFoundError` propagate (callers can rescue if
they want). Return `ConditionEvaluator.evaluate`'s errors from
`Executor#run` as a second return value, or change `run` to return a
`Result` struct with `instances` and `errors`.

---

## T6 — Name cardinality magic tokens

**File:** `lib/lutaml/lml/model_compiler.rb:305-309`
**Code:**
```ruby
def parse_cardinality_value(val)
  return nil if val.nil?
  return Float::INFINITY if val == "*" || val == "n"
  val.to_i
end
```
**Why:** Inline string literals for unbounded-cardinality sentinels.
`"n"` is undocumented. Unrecognized tokens silently become 0 via
`to_i`.
**Fix:** Extract `UNBOUNDED_TOKENS = %w[* n N unbounded].freeze` as a
named constant; raise on unrecognized non-numeric tokens.

---

## T7 — Autoload Formatter/Layout (rule compliance)

**File:** `lib/lutaml/lml.rb:7-8`
**Code:**
```ruby
require "lutaml/lml/formatter"
require "lutaml/lml/layout"
```
**Why:** Project rule says "Never use `require` with a path to code
within your own library. Use Ruby `autoload` instead." These two
requires are for code in our library (they live under `lib/lutaml/lml/`).
The current comment explains they live in the `Lutaml` top namespace —
which is true, but the fix is to set up autoloads at that namespace
level, not to eagerly require.
**Fix:** Open `module Lutaml` (already opened in this file) and
declare:
```ruby
module Lutaml
  autoload :Formatter, "lutaml/lml/formatter"
  autoload :Layout, "lutaml/lml/layout"
end
```
This defers loading until first reference.

---

## T8 — DRY Definitions grammar (Parslet)

**File:** `lib/lutaml/lml/grammar/concerns/definitions.rb`
**Duplication:**
1. `enum_inner_definitions` (lines 63-68) and `data_type_inner_definitions`
   (lines 91-96) are byte-identical.
2. `class_body`, `enum_body`, `data_type_body`, `diagram_body`,
   `view_body` all repeat the same `spaces? >> str("{") >>
   whitespace? >> inner.repeat.as(:members) >> str("}")` scaffold
   with only the inner rule name differing.

**Fix:**
1. Replace `data_type_inner_definitions` with `enum_inner_definitions`
   (single source of truth for "what can appear inside an enum or
   data_type").
2. Add a private helper `braced_body(inner)` that returns the scaffold
   atom; each `*_body` rule calls it.

**Risk:** Grammar changes can break parsing subtly. Run the full
grammar + parser + real_world specs after the change.

---

## T9 — Behavior-based formatter specs (rule compliance)

**File:** `spec/lutaml/formatter/base_spec.rb:49-95`
**Smell:** 8 tests use `expect(formatter).to receive(:format_X).with(node)`
then call `formatter.format(node)`. These are interaction tests: they
verify the dispatch table routes to a method name, but they would pass
even if the method were renamed or its body broken — the mock itself
defines the expectation.
**Rule:** Global rule prohibits `double()` and demands "Test behavior,
not interactions."
**Fix:** Define a `Recorder < Formatter::Base` test subclass that
overrides each `format_*` to return a sentinel string. Assert on the
returned string for each node type — single behavior test per dispatch
path.

---

## T10 — Add ConditionEvaluator edge case specs

**File:** `lib/lutaml/lml/executor/condition_evaluator.rb` (predicate parser)
**Coverage gap:** `build_predicate`, `attribute_getter`, `parse_literal`
have no direct unit tests. Only happy-path `count >= 1` is exercised
via `executor_spec.rb`.
**Why it matters:** This is a hand-rolled mini-language evaluator.
Off-by-one regex bugs hide silently here.
**Fix:** Add `spec/lutaml/lml/executor/condition_evaluator_spec.rb`
covering:
- Each operator: `>, >=, <, <=, ==, !=`
- Each literal type: integer, float, double-quoted string,
  single-quoted string, `true`, `false`, `nil`, `null`
- Nested attribute paths: `i.a.b.c`
- Error paths: missing operator, unknown literal, predicate not
  starting with `i`, unsupported condition form
- The `NoMethodError` rescue path (predicate references undefined attr)

---

## Deferred / Out of scope

These were identified but not selected for this round (risk vs reward):

- **D1** Definitions grammar: extracting a `common_inner_definitions`
  rule shared by diagram and view bodies. Higher risk of breaking
  the parser for marginal DRY gain.
- **D2** DocumentBuilder#remap_filter_keys — moving filter-list
  normalization into Document. Requires model API changes; current
  code works correctly.
- **D3** DocumentBuilder#ensure_collection / #append_collection
  encapsulation leak. lutaml-model's collection API may be the root
  cause; broader fix.
- **D4** ImportResolver: separating `classify` from `load` and
  injecting a logger. Currently the `warn` side-effect is acceptable.
- **D5** Formatter::Base#dispatch_format linear `find`. The hash is
  small (7 entries); the linear search is semantically correct for
  type matching with subclasses.
- **D6** StandardAdapter `primitive_value` / `quote_value` scalar
  predicate consolidation. Minor duplication.
