# 06 - View grammar duplicates diagram grammar; keywords unreserved

## Status: 🔧 TODO

## Problem

`grammar/concerns/definitions.rb:147-161` — `view_inner_definitions`
copies all 10 diagram inner alternatives and adds 3 view-only ones.
Any new inner directive must be added in two places (DRY/OCP).

`grammar/concerns/view_rules.rb` — `import`/`show`/`hide` are bare
`str()` matches that bypass the keyword-rule generation used by every
other keyword. They do not participate in the keyword system's
word-boundary discipline, and the entity-name list produces a shape
the data processor must re-sniff (Array vs Hash —
`data_processor/view_processing.rb:17-21`).

## Solution

1. Compose instead of duplicating:

       rule(:view_only_definitions) do
         view_import.as(:view_imports) | show_directive | hide_directive
       end
       rule(:view_inner_definitions) do
         view_only_definitions | diagram_inner_definitions
       end

2. Define `VIEW_KEYWORDS = %w[import show hide]` with generated
   `kw_view_import`/`kw_show`/`kw_hide` rules (`str(kw) >> spaces`
   — trailing space is the word boundary). `import` is generated
   under the view-scoped name to stay MECE with the instances-block
   `kw_import`.
3. `entity_name_list` emits `:entity_names` as a stable array shape;
   `ViewProcessing` normalizes without shape-sniffing.

## Files

- `lib/lutaml/lml/grammar/concerns/definitions.rb`
- `lib/lutaml/lml/grammar/concerns/view_rules.rb`
- `lib/lutaml/lml/data_processor/view_processing.rb`
- `spec/lutaml/lml/grammar_spec.rb`

## Verification

`bundle exec rspec spec/lutaml/lml/grammar_spec.rb` — existing view
specs (single/multi show names) must stay green unchanged.
