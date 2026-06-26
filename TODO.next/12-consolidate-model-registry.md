# 12 — Consolidate MODEL_REGISTRY under DocumentBuilder

**Status:** ✅ DONE

## Problem

`Lutaml::Lml::LmlConverter::MODEL_REGISTRY` lived in a file named
`lml_converter.rb`. The name `LmlConverter` suggested it was a converter
class — but the file contained only a constant. No methods, no behavior.

This was a legacy namespace left over from earlier refactors. The
registry's only consumer is `DocumentBuilder`, which receives it via
`Pipeline`:

```ruby
DocumentBuilder.new(LmlConverter::MODEL_REGISTRY)
```

The naming violated semantic clarity (the file's name didn't describe
its contents) and MECE (the registry conceptually belongs to the builder
that consumes it, not to a free-floating namespace).

## Fix

- Move the constant to `DocumentBuilder::DEFAULT_REGISTRY`.
- Delete `lib/lutaml/lml/lml_converter.rb`.
- Update `lib/lutaml/lml.rb` — remove the `LmlConverter` autoload.
- Update `lib/lutaml/lml/pipeline.rb` — pass
  `DocumentBuilder::DEFAULT_REGISTRY` instead of
  `LmlConverter::MODEL_REGISTRY`.
- Update any specs that referenced `LmlConverter::MODEL_REGISTRY`.

## Files

- `lib/lutaml/lml/document_builder.rb` — add `DEFAULT_REGISTRY` constant
- `lib/lutaml/lml/lml_converter.rb` — DELETED
- `lib/lutaml/lml.rb` — drop the autoload
- `lib/lutaml/lml/pipeline.rb` — use the new constant
- `spec/**` — update any references

## Why this is better

- One concept = one place. The registry belongs to the builder.
- The name `DEFAULT_REGISTRY` leaves room for callers to inject a custom
  registry (open/closed), while documenting the default.
- Removes a misleadingly-named file.
