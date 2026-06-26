# 17 — Remove dead `AttributeParser`

**Status:** ✅ DONE

## Problem

`Lutaml::Lml::AttributeParser` is a self-contained Parslet parser for
`name = value, name2 = value2` assignment lists. It is **only** referenced
by its own spec — no production code calls it. The full
`Grammar::Full` parser already covers attribute parsing via the
`attributes` and `attribute` rules.

This is dead code. It misleads readers into thinking there's a separate
attribute-parsing pipeline.

## Fix

- Delete `lib/lutaml/lml/attribute_parser.rb`
- Delete `spec/lutaml/lml/attribute_parser_spec.rb`
- Remove the autoload entry from `lib/lutaml/lml.rb`

## Verification

`grep -rn AttributeParser lib/ spec/` returns no hits after deletion.
