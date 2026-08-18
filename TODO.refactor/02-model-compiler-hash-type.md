# 02 - ModelCompiler offers forbidden :hash type

## Status: 🔧 TODO

## Problem

`model_compiler.rb:18` maps the LML DSL type name `"Hash"` to the
lutaml-model `:hash` type. `:hash` is on the project's forbidden list:
it bypasses typed attributes and reintroduces untyped data flow in
user-compiled classes.

## Solution

Remove the `"Hash" => :hash` entry from `TYPE_MAP`. An LML model
declaring a `Hash` attribute then falls through to the unknown-type
error, which is the correct outcome: if hash-shaped data is ever
needed it must be a typed model, not a raw hash.

## Files

- `lib/lutaml/lml/model_compiler.rb`
- `spec/lutaml/lml/model_compiler_spec.rb` (assert `Hash` now raises
  unknown-type)

## Verification

`bundle exec rspec spec/lutaml/lml/model_compiler_spec.rb`
