# 04 - Formatter::Base overrides Class#name; dispatch fails silently

## Status: 🔧 TODO

## Problem

`formatter/base.rb:37-39` — the class-level `def name` shadows Ruby's
`Class#name`, returning a symbol (`:graphviz`). The instance-level
`name` (line 48-50) returns `self.class.name` — which now resolves to
that symbol, so an instance's `name` silently changed type. Shadowing
`Class#name` also risks breaking any library that legitimately calls
`.name` on these classes.

`dispatch_format` (line 63-64) returns nil for unknown node types with
no signal — a formatter asked to render an unsupported node silently
produces nothing.

`transform.rb:17` — `rule(simple(:member))` matches ANY `{member: x}`
subtree, not just association member ends.

## Solution

1. Rename the class method to `formatter_name`; update
   `Formatter.find_by_name` and the instance `name` to use it.
2. `dispatch_format` raises `Lutaml::Lml::Error` for unhandled node
   types (aligned with the Executor error-surfacing direction).
3. Scope the Transform member rule to the association member context
   (verify what produces `:member` subtrees; if only association
   rules, keep and document; if broader, scope it).

## Files

- `lib/lutaml/lml/formatter/base.rb`
- `lib/lutaml/lml/formatter/graphviz.rb`
- `lib/lutaml/lml/transform.rb`
- `spec/lutaml/lml/formatter/` dispatch specs

## Verification

`bundle exec rspec spec/lutaml/lml/formatter spec/lutaml/lml/transform_spec.rb`
