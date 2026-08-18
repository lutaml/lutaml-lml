# 09 - Import resolution stops swallowing errors

## Status: 🔧 TODO

## Problem

Commit fa8cf9a established the direction: errors surface, callers
decide. The resolvers did not follow:

- `import_resolver.rb:52-53, 63-64` — `Errno::ENOENT/EACCES` →
  `warn "Skipping ..."` and continue. A typo'd import path yields a
  silently empty diagram.
- `import_resolver.rb:32` — `Dir.glob` matching nothing is
  indistinguishable from success.
- `preprocessor.rb:47-49` — missing `include` file → `warn`, continue.

## Solution

1. ImportResolver collects resolution failures while walking the
   import graph (path + reason), and raises `Lutaml::Lml::ImportError`
   (subclass of `Lutaml::Lml::Error`) at the end listing every failed
   import. Empty-glob is a failure with its own message.
2. Preprocessor raises `Lutaml::Lml::Error` for missing include files.
3. Specs asserting the old swallow behavior ("handles empty glob
   results gracefully", "skips unreadable files without crashing")
   are rewritten to assert the raise + message.

## Files

- `lib/lutaml/lml/import_resolver.rb`
- `lib/lutaml/lml/preprocessor.rb`
- `lib/lutaml/lml.rb` (ImportError)
- `spec/lutaml/lml/import_resolver_spec.rb`
- `spec/lutaml/lml/preprocessor_spec.rb`

## Verification

`bundle exec rspec spec/lutaml/lml/import_resolver_spec.rb spec/lutaml/lml/preprocessor_spec.rb spec/lutaml/lml/view_spec.rb`
