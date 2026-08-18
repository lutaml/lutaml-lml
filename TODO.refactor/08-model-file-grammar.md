# 08 - Model-file grammar production (remove Fragment wrap + sniffing + FD leak)

## Status: 🔧 TODO

## Problem

`import_resolver.rb` hacks around the fact that bare model files
(top-level `class Foo {}` with no enclosing block) do not parse:

- `resolve_model_file` (57-66) wraps content in a synthetic
  `diagram Fragment { ... }` — a fake entity name that pollutes any
  name-indexed structure.
- `view_file?` (68-73) sniffs file type by regexing the first 200
  chars for `/\b(view|diagram)\s+\w/` — a comment mentioning "view"
  misclassifies a model file.
- `resolve_view_file` (45) uses `File.new` without closing — FD leak
  on large globs.

The existing root alternatives (`models Name { ... }`, `diagram`,
`view`) are all NAMED blocks; there is no production for "a file of
bare definitions".

## Solution

1. New root production `model_definitions` — a repeat of the same
   inner definitions a diagram body accepts, without the wrapper:

       rule(:model_definitions) { diagram_inner_definition.repeat(1) }

   Add to the root alternation in `grammar/instances.rb`.
2. ImportResolver parses every import with the full parser (the root
   accepts diagram/view/models/bare-definitions alike), then recurses
   into `doc.view_imports` when present. The `view_file?` sniff and
   the `diagram Fragment` wrap are deleted.
3. File reads use `File.open { }` blocks.

## Files

- `lib/lutaml/lml/grammar/concerns/definitions.rb`
- `lib/lutaml/lml/grammar/instances.rb` (root alternation)
- `lib/lutaml/lml/import_resolver.rb`
- `spec/lutaml/lml/grammar_spec.rb` (bare file parses)
- `spec/lutaml/lml/import_resolver_spec.rb`

## Verification

`bundle exec rspec spec/lutaml/lml/import_resolver_spec.rb spec/lutaml/lml/view_spec.rb`
— including a model file whose comment mentions "view" (sniffing
regression guard).
