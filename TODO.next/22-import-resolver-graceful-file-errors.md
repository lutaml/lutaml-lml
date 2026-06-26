# 22 — `ImportResolver`: graceful file-error handling

**Status:** ✅ DONE

## Problem

`ImportResolver#resolve_model_file` and `#view_file?` both call
`File.read(file_path)` without rescue. If a glob-matched file is
deleted between glob and read (race), or is unreadable (permissions),
the entire pipeline crashes with `Errno::ENOENT` / `EACCES` instead of
skipping the file with a warning.

`#process_include_line` in `Preprocessor` already handles this pattern
correctly — rescues `Errno::ENOENT` and logs to stderr. ImportResolver
should do the same for consistency and robustness.

## Fix

Wrap each file read in a rescue that:

1. Logs the skipped file path + error class to `$stderr`
2. Returns `[]` from the resolve method (no entities added)
3. Continues processing remaining files

## Files

- `lib/lutaml/lml/import_resolver.rb` — wrap reads
- `spec/lutaml/lml/import_resolver_spec.rb` — add file-error spec

## Why

- Import resolution is a batch operation — one bad file shouldn't take
  down the whole batch
- Matches the existing pattern in `Preprocessor#process_include_line`
