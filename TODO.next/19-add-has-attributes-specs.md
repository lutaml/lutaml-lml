# 19 — Add specs for `HasAttributes`

**Status:** ✅ DONE

## Problem

`Lutaml::Lml::HasAttributes` is mixed into `Formatter::Base` and the
CLI, but has no direct test coverage. Its only behavior —
`update_attributes` — does two things:

1. Unwraps `Parslet::Slice` values into strings
2. Calls `public_send(:"#{name}=", value)` for each pair

A regression in either behavior would silently break both the CLI and
every formatter.

## Fix

Add `spec/lutaml/lml/has_attributes_spec.rb`:

- Sets string attributes from a hash
- Sets symbol keys
- Unwraps `Parslet::Slice` values into strings
- Ignores keys with no writer (uses a real model with subset of writers
  or a Struct — no `double()`)
- Handles empty / nil input gracefully

## Files

- `spec/lutaml/lml/has_attributes_spec.rb` (new)
