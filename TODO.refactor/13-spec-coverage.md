# 13 - Spec coverage gaps from the pass-1 audit

## Status: 🔧 TODO

## Problem

Happy paths are covered; the contracts around them are not:

- nested `include` expansion (TODO 03's bug shipped because nothing
  tested it)
- import/include failure surfacing (TODO 09)
- inline `class` + `import` in the same view body (common real case)
- backward compat: `diagram` + `include` still works after the
  view/import changes
- `view` body with `title`/`caption`/`fontname` AND filter directives
  composed together
- word boundary: `important` must not parse as `import`
- `show`/`hide` naming an entity that does not exist (spec the
  contract: filtered-away is fine, never an error)
- a glob mixing model and view files
- view → YAML → parse round trip

## Solution

Add the missing specs to the existing spec files (no new spec files
except where a new class was introduced by earlier TODOs). Specs use
real model instances; no doubles.

## Files

- `spec/lutaml/lml/grammar_spec.rb`
- `spec/lutaml/lml/view_spec.rb`
- `spec/lutaml/lml/import_resolver_spec.rb`
- `spec/lutaml/lml/preprocessor_spec.rb`
- `spec/lutaml/lml/round_trip_spec.rb`
- fixtures under `spec/fixtures/view/`

## Verification

`bundle exec rspec` — all new specs green.
