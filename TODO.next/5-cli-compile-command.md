# 5 — CLI `compile` command for model generation

**Status:** ✅ DONE

Added `compile` subcommand to `Lutaml::Lml::Cli::LmlCommands`.

### Usage

```bash
lutaml lml compile models.lml                    # compile, print class names
lutaml lml compile models.lml -n MyModels        # register in MyModels namespace
```

### Implementation

- `compile` method in CLI accepts a path and optional `--namespace`
- Delegates to `ModelCompiler.new(namespace: ns).compile(File.new(path))`
- Prints compiled class names to stdout
- `resolve_namespace` helper resolves dotted module names (e.g., `Foo::Bar`)

### Verification

- `lutaml lml compile spec/fixtures/lml/iho_data_models.lml` outputs:
  `compiled: IhoMetadata` and `compiled: CompliantStandard`
- `bundle exec rspec` — 356 examples, 0 failures
