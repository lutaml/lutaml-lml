# 11 - Resolver pair representation + duplicate-definition conflicts

## Status: 🔧 TODO

## Problem

`import_resolver.rb` builds a name→entity hash, then discards the
structure by returning `entities.values` (line 23).
`view_resolver.rb:16` immediately rebuilds the same hash. The two
classes were not designed as a pair and it shows.

`merge_entities` (82-86) uses `entities[entity.name] ||= entity` —
first wins, silently. Two files defining `Foo` differently produce a
diagram of the wrong `Foo` with no signal. Meanwhile the SAME entity
imported through two paths (view imports model M; root also imports
model M) is legitimate re-import and must stay silent.

## Solution

1. ImportResolver returns the name-index (hash) plus associations;
   ViewResolver consumes the index directly. No re-hashing.
2. Duplicate detection: when a name collides, compare
   `existing.to_hash == new.to_hash` (lutaml-model provides it).
   Equal → silent dedup (re-import). Different → record a conflict
   ("Foo defined differently in X and Y") and surface it per TODO 09.
3. Entities with nil names are skipped (they cannot be referenced by
   show/hide or association ends anyway).

## Files

- `lib/lutaml/lml/import_resolver.rb`
- `lib/lutaml/lml/view_resolver.rb`
- `lib/lutaml/lml/pipeline.rb` (plumbing between the two)
- `spec/lutaml/lml/import_resolver_spec.rb`
- `spec/lutaml/lml/view_resolver_spec.rb`

## Verification

`bundle exec rspec spec/lutaml/lml/import_resolver_spec.rb spec/lutaml/lml/view_resolver_spec.rb spec/lutaml/lml/view_spec.rb`
