# 01 - Model attribute defaults consistency

## Status: 🔧 TODO

## Problem

Attribute defaults are inconsistent across models, forcing defensive
nil-handling at every call site:

- `models/top_element_attribute.rb:24,26` use `default: []` (shared frozen
  literal; must be `default: -> { [] }`).
- `models/document.rb` — `view_imports`, `requires`, `comments`, `groups`
  are collections without defaults, so they can be nil.
- `pipeline.rb:45` (`view_imports&.any?`), `import_resolver.rb:49`
  (`doc.view_imports&.each`) defend against nil that a default would
  eliminate.

Singular attributes where nil is meaningful (`instance`, `instances`,
`fidelity`, `show_filter`, `hide_filter`) keep no default — absence is the
signal. Executor's `doc.instances&.` guards stay (nil = no instances block).

## Solution

1. Fix `default: []` → `default: -> { [] }` in TopElementAttribute.
2. Add `default: -> { [] }` to Document: `view_imports`, `requires`,
   `comments`, `groups`.
3. Remove now-dead `&.` on `view_imports`.

## Files

- `lib/lutaml/lml/models/top_element_attribute.rb`
- `lib/lutaml/lml/models/document.rb`
- `lib/lutaml/lml/pipeline.rb`
- `lib/lutaml/lml/import_resolver.rb`

## Verification

`bundle exec rspec` — full suite green; new spec asserting
`Document.new.view_imports == []`.
