# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**lutaml-lml** is a Ruby gem that parses the LutaML Model Language (LML) — a text DSL for describing UML models — into domain model objects. It supports two layers: model definitions (classes, enums, attributes, associations) and data instances (collections, imports, exports). Output is rendered as diagrams via GraphViz.

Key dependencies: `parsanol` (PARG grammar — PEG parsing, native-first Rust engine with Ruby fallback), `lutaml-model` (serialization), `ruby-graphviz`.

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
- `lib/lutaml/lml/grammar.rb` — loads the PARG grammar (`Grammar.artifact`)
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
2. **Preprocessor** (`preprocessor.rb`): Expands `include` directives, rejects unterminated block comments (`//`/`/* */` are grammar-level skip trivia)
3. **Parser** (`parser.rb`): Facade over the PARG artifact; `parse` returns the raw parse tree.
4. **Grammar** (`grammar/lml.parg`): The LML grammar written in PARG (parsanol grammar language), entry `diagram`. `grammar/lml.artifact.json` is its compiled form — regenerate with `rake parg` after any grammar edit; `Grammar.artifact` loads the committed artifact (fast path) and falls back to compiling the text on drift or absence (a sync spec enforces the pair in CI). PEG semantics — ordered choice; alternative order is deliberate and lint-checked.
5. **Transform** (`transform.rb`): Minimal Parsanol transform (visibility mapping, string cleanup)
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

### Validation

`Validator.violations(document)` evaluates the RS 3001 §Validation rules over a parsed document — unique type/attribute names, mandatory (positive-minimum cardinality) attributes populated, primitive type and `pattern` conformity, reference resolution and circularity. `lutaml validate` reports these alongside parse errors.

### Post-Parse Resolution

After parsing, three resolvers run sequentially on the document:

1. **ImportResolver** — recursively resolves `view import` paths, loading external `.lml`/model files and merging their entities
2. **ViewResolver** — applies `show`/`hide` filters to entity and association collections
3. **AssociationLabelResolver** — enriches associations with attribute names and cardinalities by cross-referencing class attributes

### Domain Models

All models inherit from `Lutaml::Model::Serializable` directly (no external UML gem dependency):
- `Document`, `UmlClass`, `Enum`, `DataType`, `PrimitiveType`, `Namespace`, `SerializationMapping`, `MappingRule` — entity definitions
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

Thor-based CLI at `Cli::LmlCommands` with `generate`, `validate`, and `compile` commands. Supports LML, YAML, and EXP input formats. `validate` reports RS 3001 rule violations in addition to parse errors.

## Key Conventions

- All internal code uses `autoload` — never `require_relative` or `require` with internal paths
- The grammar is `grammar/lml.parg` (PARG); edit it there — never rebuild parse trees in Ruby. Capture discipline: parenthesize repetitions before `as` (`( *x ) as k`) or captures bind per-iteration; `[ x as k ]` yields `k: nil` when absent (consumers treat nil ≡ absent); `%x00-10FFFF` is the char-wise `any` (`%x00-FF` is byte-wise and fails on multibyte)
- Skip trivia (parsanol#134): `skip = trivia` injects optional trivia (blanks/tabs, `//`+newline, `/* */`) before sequence children and rule references. Consequences: token rules (identifier/char/string scans: `word`, `namechar`, `typechar`, `dq_string`, …) MUST be `atomic` or their runs span trivia (`xml Ceramic` becomes one token, `//` inside strings is eaten); a keyword plus its required separator is an `atomic kw_x_sp = "x" 1*" "` rule; optional separation between tokens needs no rule (trivia owns it); newlines stay grammar-visible (`[ whitespace ]` interspersals remain); char-scan repetition bodies use `until "<terminal>"` or the `ANY` shorthand (both compile inline, verbatim) — not `any_char` refs (a rule-ref child re-enables injection)
- All models inherit from `Lutaml::Model::Serializable` directly, with flattened attribute definitions
- Entity classification uses `self.entity_type` on model classes (polymorphic dispatch, not `is_a?`)
- RS 3001 conformance: the normative examples of lutaml-lang.adoc are vendored as `spec/fixtures/rs3001/*.lml` (`rs3001_corpus_spec`) — every 3001 example must parse and build; serialization mappings (RS 3010 extension) compile into lutaml-model `xml`/`key_value` mappings, with sibling `mapping <format> <class>` canonical and in-class `mapping <format> { }` as the shortcut
- Code quality: no `send`, `instance_variable_set/get`, `respond_to?`, or `require_relative`
