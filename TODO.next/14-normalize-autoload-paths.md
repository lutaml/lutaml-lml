# 14 — Normalize autoload paths and remove redundant self-registration

**Status:** ✅ DONE

## Problem

Two inconsistencies in the gem's load-time wiring:

1. **Path style.** Most autoloads use gem-relative paths
   (`"lutaml/lml/foo"`), but a few files used `"#{__dir__}/foo"`. Both
   work, but the inconsistency is a smell — `__dir__`-based paths
   presume a particular file layout that the gem-relative form does
   not.

2. **Redundant registration calls at file scope.** Both
   `csv_adapter.rb` and `xml_adapter.rb` ended with:
   ```ruby
   Lutaml::Lml::Executor::FormatAdapter.register("csv", Lutaml::Lml::Executor::CsvAdapter)
   ```
   These ran at file load time. But `FormatAdapter` already has a
   `BUILTIN_ADAPTERS` table that resolves built-ins lazily via
   `Executor.const_get(:CsvAdapter)` on first use. So the explicit
   registration was (a) redundant with `BUILTIN_ADAPTERS` and (b) ran
   eagerly, defeating the point of lazy resolution.

## Fix

- Replace `"#{__dir__}/..."` autoload paths with `"lutaml/lml/..."`.
- Remove the trailing `register` calls from `csv_adapter.rb` and
  `xml_adapter.rb`. Resolution goes through `BUILTIN_ADAPTERS` only.

## Files

- `lib/lutaml/lml/format/adapter.rb` — paths normalized (later removed
  entirely by TODO 11, but the principle applies going forward)
- `lib/lutaml/lml/executor/csv_adapter.rb` — drop trailing register
- `lib/lutaml/lml/executor/xml_adapter.rb` — drop trailing register

## Why

- One way to write autoload paths.
- Lazy adapter resolution is the design — don't undermine it with eager
  registration at file scope.
