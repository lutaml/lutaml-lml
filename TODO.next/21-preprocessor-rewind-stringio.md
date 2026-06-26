# 21 — Preprocessor: rewind StringIO after read

**Status:** ✅ DONE

## Problem

`Preprocessor#call` does:

```ruby
input_file.read.split("\n").reduce([]) do |res, line|
  ...
end.join("\n")
```

`IO#read` consumes the stream. If the same StringIO is passed to the
preprocessor twice (or if any other code reads from it afterward), the
subsequent reads return `""`.

This is an idempotency bug — the same input can produce different
output depending on whether it has been preprocessed before.

## Fix

Rewind the IO before reading (and after, for good measure):

```ruby
def call
  input_file.rewind if input_file.respond_to?(:rewind)
  # ... existing read+process ...
end
```

Note: `respond_to?(:rewind)` is used here as a capability check on an
external IO boundary, not as a type check on internal code — this is
the duck-typing exception, not a violation of the project's
"no respond_to for type checks" rule. The alternative is branching on
`is_a?(StringIO) || is_a?(IO) || is_a?(File)`, which is brittle.

## Files

- `lib/lutaml/lml/preprocessor.rb` — rewind
- `spec/lutaml/lml/preprocessor_spec.rb` (new or updated) — add
  idempotency spec

## Why

- Preprocessor is a pure function of its input. Same input → same
  output, every time.
- StringIO inputs are common in tests and Pipeline internals; this bug
  is silent until someone re-reads.
