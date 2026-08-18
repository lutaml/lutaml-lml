# 03 - Preprocessor does not expand nested includes

## Status: 🔧 TODO

## Problem

`preprocessor.rb:39-46` — `process_include_line` reads an included file
and runs each line through `process_comment_line` only. An `include`
directive inside an included file is passed through unexpanded and
later fails (or silently disappears) at parse time. Line splitting is
also `\n`-only, so `\r\n` files leave stray `\r` in content.

## Solution

1. Recurse: included lines go through the same
   `include → comment` pipeline as top-level lines.
2. Guard recursion with a visited-path set so `a includes b includes a`
   raises instead of looping.
3. Split on both `\n` and `\r\n` (`split(/\r?\n/)`).

## Files

- `lib/lutaml/lml/preprocessor.rb`
- `spec/lutaml/lml/preprocessor_spec.rb` (nested include, include
  cycle, CRLF fixture)

## Verification

`bundle exec rspec spec/lutaml/lml/preprocessor_spec.rb`
