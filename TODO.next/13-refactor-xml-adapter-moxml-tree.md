# 13 — Build XML export tree directly with Moxml

**Status:** ✅ DONE

## Problem

`XmlAdapter.build_export_xml` worked by:

1. Calling `inst.to_xml.chomp` for each instance → per-record XML
   **strings**
2. Joining those strings with separators
3. Wrapping in a root tag via string interpolation
4. **Re-parsing** the joined string with `Moxml.parse`
5. **Re-serializing** with `doc.to_xml(indent: 2)`

Round-tripping through string → parse → serialize is wasteful and
fragile (any escaping mismatch between `inst.to_xml` and Moxml's parser
would corrupt the output). It also forces `to_xml` to emit a root
element per record, which we then have to merge under a single document
root.

## Fix

Build the Moxml tree directly:

1. `Moxml::Document.build` → creates an XML document with a declaration
2. Add a root element (`<Products>` etc.) as a single child
3. For each instance, parse its `to_xml` output to a node, then
   **move** the parsed root element under our document root

The "parse once per instance, then graft" pattern is necessary because
`lutaml-model`'s `to_xml` already produces a complete XML document for
each record — we need to extract its root element and re-parent it.
This is O(n) parses, but each parse is independent and the join no
longer requires re-parsing the whole document.

The `wrap_in_root` string interpolation helper is removed.

## Files

- `lib/lutaml/lml/executor/xml_adapter.rb` — replace `build_export_xml`
  with direct tree construction

## Specs

Existing export specs in `spec/lutaml/lml/executor/xml_adapter_spec.rb`
continue to pass — same output shape, different implementation.
