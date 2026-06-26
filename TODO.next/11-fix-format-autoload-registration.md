# 11 — Fix Format module autoload + self-registration

**Status:** ✅ DONE

## Problem (actual bug)

Two files competed to define `Lutaml::Lml::Format`:

- `lib/lutaml/lml/format.rb` — defined `module Format` with an autoload
  for `Adapter`, **and** performed `FormatRegistry.register(:lml, ...)`
  at file scope
- `lib/lutaml/lml/format/adapter.rb` — also defined `module Format` with
  autoloads for `Adapter::Document`, `Mapping`, `Transform`,
  `StandardAdapter`

In `lib/lutaml/lml.rb`, the `Format` autoload pointed at
`"lutaml/lml/format/adapter"` (the namespace file), **not** at
`format.rb`. So:

1. Requiring `lutaml/lml` alone did NOT auto-register the `:lml` format
   with `Lutaml::Model::FormatRegistry`.
2. Requiring `lutaml/lml/format` (the registration file) would NOT trigger
   the autoloads defined in `format/adapter.rb`, because Ruby would have
   already opened `module Format` from `format.rb`.
3. Tests in `format_adapter_spec.rb` had to `require "lutaml/lml/format"`
   explicitly to force registration — a sign the production load path
   was broken.

Additionally, `format/adapter.rb` used `"#{__dir__}/adapter/..."` paths
for its autoloads, inconsistent with the rest of the gem which uses
gem-relative `"lutaml/lml/..."` paths.

## Fix

Single source of truth for the `Format` namespace:

- `lib/lutaml/lml/format.rb` — defines `module Format`, autoloads
  `Adapter` (gem-relative path), and performs the
  `FormatRegistry.register(:lml, ...)` call. This file is the **only**
  place the `:lml` format is registered.
- `lib/lutaml/lml/format/adapter.rb` — DELETED. Its autoloads moved
  into `format.rb`. The namespace is opened once, in one file.
- `lib/lutaml/lml.rb` — the `Format` autoload now points to
  `"lutaml/lml/format"` (the namespace + registration file), not to
  `format/adapter`.

Now `require "lutaml/lml"` alone is sufficient to make
`FormatRegistry.registered?(:lml)` return true on first access (Ruby's
autoload triggers `format.rb`, which both opens the namespace and
registers).

## Specs

`spec/lutaml/lml/format_autoload_spec.rb` (new):

- `Lutaml::Lml::Format` autoloads to the registration file
- After accessing `Lutaml::Lml::Format`, the `:lml` format is registered
  in `Lutaml::Model::FormatRegistry`
- `Lutaml::Lml::Format::Adapter::StandardAdapter` resolves via autoload
