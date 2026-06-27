# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**lutaml-lml** is a Ruby gem that parses the LutaML Model Language (LML) — a text DSL for describing UML models — into domain model objects. It supports two layers: model definitions (classes, enums, attributes, associations) and data instances (collections, imports, exports). Output is rendered as diagrams via GraphViz.

Key dependencies: `parslet` (PEG parsing), `lutaml-model` (serialization), `ruby-graphviz`.

## Development Commands

```bash
bundle install                  # install deps
bundle exec rake spec           # run all tests
bundle exec rspec               # run all tests
bundle exec rspec spec/lutaml/lml/parser_spec.rb          # single test file
bundle exec rspec spec/lutaml/lml/parser_spec.rb:42       # single test by line
bundle exec rubocop             # lint
```

## Architecture

### Loading Convention

All internal code uses Ruby `autoload` (not `require_relative`). Autoload entries are defined in the immediate parent namespace's file:
- `lib/lutaml/lml.rb` — autoloads all top-level constants and models
- `lib/lutaml/lml/grammar.rb` — autoloads `Grammar::*`
- `lib/lutaml/lml/grammar/concerns.rb` — autoloads `Concerns::*`
- `lib/lutaml/lml/formatter.rb` — autoloads `Formatter::*` (in `Lutaml` namespace)
- `lib/lutaml/lml/layout.rb` — autoloads `Layout::*` (in `Lutaml` namespace)
- `lib/lutaml/lml/data_processor.rb` — autoloads sub-modules

### Parsing Pipeline

```
Input → Preprocessor → Parser → Transform → DataProcessor → DocumentBuilder → Document
                                                                                   ↓
                                                              ImportResolver → ViewResolver → AssociationLabelResolver
```

1. **Pipeline** (`pipeline.rb`): Orchestrates the full parse flow. Entry point for all parsing.
2. **Preprocessor** (`preprocessor.rb`): Strips comments, inlines `include` directives
3. **Parser** (`parser.rb`): Pure Parslet parser (grammar + transform only). `Parser.parse` delegates to Pipeline for backward compatibility.
4. **Grammar** (`grammar/`): Parslet PEG rules split into composable concerns:
   - `Core` — class/enum/data_type/diagram definitions, associations, attributes, views
   - `Instances` — collection/instance/import/export rules
   - `Full` — combines both via inclusion; overrides `diagram` root rule
5. **Transform** (`transform.rb`): Minimal Parslet transform (visibility mapping, string cleanup)
6. **DataProcessor** (`data_processor/`): Post-transform data massage, split into sub-modules by concern (value, attribute, instance, collection, view processing). Usable as mixin or via `.process` class method.
7. **DocumentBuilder** (`document_builder.rb`): Builds domain model objects from processed hashes via a registry pattern. Takes `LmlConverter::MODEL_REGISTRY` and provides `build(key, hash)`.

### Converter Registry

`LmlConverter::MODEL_REGISTRY` maps builder keys (symbols like `:document`, `:class`, `:enum`) to `Lutaml::Lml::*` model classes. This is the single source of truth for the DocumentBuilder's type dispatch.

### Model Compiler

`ModelCompiler` compiles LML model definitions into anonymous `Lutaml::Model::Serializable` subclasses:
- `compile(input)` — parses model definitions, produces a hash of class name → compiled class
- `hydrate(input)` — parses instance data, creates typed instances from compiled classes
- Forward reference resolution: two-pass compilation (deferred attributes resolved after all classes registered)
- `Lutaml::Lml.compile(input, namespace:)` — module-level convenience method

### Format Adapter

`Format::Adapter::StandardAdapter` provides `from_lml`/`to_lml` serialization through the LML format registry:
- Parses LML instance syntax via Pipeline
- Serializes hash data to LML instance syntax
- Preserves `__type__` metadata for nested instance round-trips

### Executor

`Executor` orchestrates instance data I/O: import external data, validate collections, export to external formats:
- `FormatAdapter` — pluggable registry for format-specific I/O adapters
- `CsvAdapter` — CSV import (column mapping → hydrated instances) and export
- `ConditionEvaluator` — collection validation (count comparisons)

### Post-Parse Resolution

After parsing, three resolvers run sequentially on the document:

1. **ImportResolver** — recursively resolves `view import` paths, loading external `.lml`/model files and merging their entities
2. **ViewResolver** — applies `show`/`hide` filters to entity and association collections
3. **AssociationLabelResolver** — enriches associations with attribute names and cardinalities by cross-referencing class attributes

### Domain Models

All models inherit from `Lutaml::Model::Serializable` directly (no external UML gem dependency):
- `Document`, `UmlClass`, `Enum`, `DataType`, `PrimitiveType` — entity definitions
- `Association`, `Cardinality`, `Constraint` — relationship modeling
- `TopElementAttribute`, `Operation`, `OperationParameter`, `Value` — attribute definitions
- `Instance`, `InstanceCollection`, `InstancesImport`, `InstancesExport` — data instances
- `Collection`, `Action`, `Fidelity`, `Group` — structural support
- `Diagram`, `Package`, `ViewImport`, `ViewFilter` — diagram/view support

LML entity models define `self.entity_type` returning their document collection key (`:classes`, `:enums`, `:data_types`).

### Output Formatting

`Formatter::Base` defines a type-dispatch pattern (`FORMAT_HANDLERS`) mapping node types to format methods. `Formatter::Graphviz` extends this with HTML table rendering, split into:
- `HtmlBuilder` — HTML label construction
- `NodeFormatter` — class/enum node rendering
- `RelationshipFormatter` — edge rendering
- `DocumentFormatter` — graph-level structure (deduplicates associations)

Layout engines (`Layout::Engine` → `Layout::GraphVizEngine`) handle the actual `dot` CLI invocation.

### CLI

Thor-based CLI at `Cli::LmlCommands` with `generate`, `validate`, and `compile` commands. Supports LML, YAML, and EXP input formats.

## Key Conventions

- All internal code uses `autoload` — never `require_relative` or `require` with internal paths
- Grammar modules use Parslet's `rule()` DSL; keywords are defined as `kw_*` rules built from `CORE_KEYWORDS` / `INSTANCE_KEYWORDS` arrays
- The `Grammar::Full` module includes both `Core` and `Instances`, overriding the `diagram` root rule to accept both model and instance definitions
- All models inherit from `Lutaml::Model::Serializable` directly, with flattened attribute definitions
- Entity classification uses `self.entity_type` on model classes (polymorphic dispatch, not `is_a?`)
- Code quality: no `send`, `instance_variable_set/get`, `respond_to?`, or `require_relative`
