# 20 — Convert `FORMAT_HANDLERS` to a Hash

**Status:** ✅ DONE

## Problem

`Lutaml::Formatter::Base::FORMAT_HANDLERS` is an Array of `[Type,
:method]` pairs:

```ruby
FORMAT_HANDLERS = [
  [Lml::TopElementAttribute, :format_attribute],
  [Lml::Operation, :format_operation],
  [Lml::Association, :format_relationship],
  [Lml::Document, :format_document],
  [Lml::DataType, :format_class],
  [Lml::UmlClass, :format_class],
  [Lml::Enum, :format_class]
].freeze
```

Dispatch uses:

```ruby
_, handler = FORMAT_HANDLERS.find { |type, _| node.is_a?(type) }
```

An Array-of-pairs is the wrong shape for a constant lookup table. A
Hash expresses the intent (Type → handler) directly and reads better.

## Fix

Convert to:

```ruby
FORMAT_HANDLERS = {
  Lml::TopElementAttribute => :format_attribute,
  Lml::Operation => :format_operation,
  Lml::Association => :format_relationship,
  Lml::Document => :format_document,
  Lml::DataType => :format_class,
  Lml::UmlClass => :format_class,
  Lml::Enum => :format_class
}.freeze
```

Dispatch becomes:

```ruby
handler = FORMAT_HANDLERS.find { |type, _| node.is_a?(type) }&.last
```

## Files

- `lib/lutaml/lml/formatter/base.rb` — change shape, update dispatch
- `spec/lutaml/formatter/base_spec.rb` — add a regression spec that
  verifies type→handler dispatch for at least two node classes

## Why

- Reads as a lookup table, not a list of pairs
- Hash key uniqueness (last-wins) matches the override semantic: when
  `UmlClass` and `DataType` both map to `:format_class`, there's no
  ambiguity, but the Hash shape surfaces any future collision
