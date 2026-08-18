# 05 - Source abstraction for pipeline input

## Status: 🔧 TODO

## Problem

Input handling is duplicated with type checks scattered across the
pipeline:

- `pipeline.rb:47` — `@input.is_a?(StringIO) ? nil : @input.path`
- `preprocessor.rb:19-20` — `input_file.rewind` +
  `input_file.is_a?(StringIO) ? Dir.pwd : File.dirname(input_file.path)`
- `import_resolver.rb:29` — its own `base_path ? File.dirname(base_path) : Dir.pwd`

Each site re-derives "what is this input and where does it live" with
a different expression. Adding a new input kind (plain String) means
touching all of them.

## Solution

`Lutaml::Lml::Source`:

    Source.wrap(input)  # String | StringIO | IO/File
    #source.read       # full text (rewinds first)
    #source.path       # filesystem path or nil
    #source.base_dir   # dir of path, or Dir.pwd for anonymous input

Pipeline and Preprocessor accept/normalize through Source once.
ImportResolver receives a base directory (it already takes `base_path`).

## Files

- `lib/lutaml/lml/source.rb` (new)
- `lib/lutaml/lml.rb` (autoload)
- `lib/lutaml/lml/pipeline.rb`
- `lib/lutaml/lml/preprocessor.rb`
- `spec/lutaml/lml/source_spec.rb` (new)

## Verification

`bundle exec rspec spec/lutaml/lml/source_spec.rb spec/lutaml/lml/pipeline_spec.rb spec/lutaml/lml/preprocessor_spec.rb`
