# 12 - Pipeline parses; resolution becomes an explicit step

## Status: 🔧 TODO

## Problem

`pipeline.rb` runs preprocess → parse → transform → process → build,
then conditionally does view resolution + enrichment behind a
`resolve:` boolean (lines 9-16, 23-27). Two unrelated lifecycles fused
behind a flag; `Parser.parse` vs `Parser.parse_document` differ only
by that flag, and `Parser` (a Parslet parser class) doubles as the
pipeline facade.

ImportResolver recursing into `Parser.parse_document` nests a full
pipeline inside the pipeline.

Depends on: 05 (Source), 07 (registry), 08 (model-file grammar),
09 (errors), 11 (resolver pair) — do last.

## Solution

1. `Pipeline` becomes parse-only: `Pipeline.call(source) → Document`.
   The `resolve:` flag and `resolve_document`/`rebuild_document` move
   out.
2. New `Lutaml::Lml::ViewResolution.call(document, source)` —
   import + filter + rebuild + label enrichment, no-op unless
   `view_imports.any?`.
3. Module-level API on `Lutaml::Lml`:
   - `Lutaml::Lml.parse(io)` — parse + resolve (what `Parser.parse`
     did)
   - `Lutaml::Lml.parse_document(io)` — parse only
4. `Parser` keeps only its Parslet role. All callers
   (`model_compiler.rb`, `cli.rb`, `import_resolver.rb`, executor
   docs, specs) move to the module API. No aliases.

## Files

- `lib/lutaml/lml/pipeline.rb`
- `lib/lutaml/lml/view_resolution.rb` (new)
- `lib/lutaml/lml/parser.rb`
- `lib/lutaml/lml.rb`
- `lib/lutaml/lml/cli.rb`, `lib/lutaml/lml/model_compiler.rb`,
  `lib/lutaml/lml/import_resolver.rb`
- all specs using `Parser.parse`

## Verification

`bundle exec rspec` — full suite green with no `Parser.parse`
references left (`grep -rn "Parser.parse" lib spec` empty).
