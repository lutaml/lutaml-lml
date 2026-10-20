# P0 — Canonical form, emitter, formatter CLI

LML round-trips values today; it does not define a canonical textual form.
Without one, diffs are syntactic noise, there is no `format` tool, and the
idempotence law is unstatable. This package defines and ships the canonical
form.

1. [DESIGN — settled] The canonical form, as realized by the emitter:
   - ORDER. The document model is group-structured (classes, enums,
     data_types, packages, primitives, associations, namespaces,
     serialization_mappings, diagrams, instances are separate
     collections), so original inter-group order is not representable.
     Canonical order is therefore: fixed group order — requires,
     namespaces, packages (depth-first: package members recurse in the
     same group order), classes, enums, data_types, primitives,
     serialization_mappings, associations, diagrams, instances — with
     declaration order preserved WITHIN each group. Semantic equality
     is defined over the same grouping (see item 5).
   - LAYOUT. Two-space indent; one blank line between members at every
     level; single trailing newline; no blank-first/blank-last bodies.
   - ATTRIBUTE FORMS. Terse comma form `attribute name, Type` when the
     attribute carries only name and type with default cardinality.
     Otherwise the block form, members in fixed order: type (when the
     comma form is not eligible the type still rides the block as its
     first member), cardinality, values set, default, pattern, then any
     other properties sorted by name. Cardinality `[a..b]`; unbounded
     max renders `n`; `[0..1]` is omitted (the default).
   - MODIFIERS. Visibility emitted only when not public (+ - # ~);
     abstract only when true; stereotype only when present.
   - QUOTING. Values AND keys reuse the emit predicates verbatim: bare
     only for [A-Za-z0-9_]; double quotes with the two RS 3001 escapes.
   - DEFINITIONS. Single-line prose renders the line form
     `definition "..."`; multiline prose renders the block form with the
     body indented one level and layout edges stripped (the transform's
     BLOCK_KEYS semantics).
   - COMMENTS. Line comments render `// body` above their member in
     stored order. The document model stores comments as strings;
     block-comment identity is not preserved — canonical renders all
     comments as line comments (lossy for comment KIND, never for
     content; recorded as a known canonicalization property).
   - NULL/ABSENT. Definitions: nil optional members are omitted
     entirely (canonical records intent by absence; `null` appears only
     in instance data per the value semantics). Instances: the instance
     emitter policy stands — nil scalars omitted, explicit semantics
     otherwise unchanged.
2. Implement `Lutaml::Lml::Formatter::Canonical` emitting from the
   document model (parse -> canonical text; never source-preserving —
   the canonical form is defined, not reconstructed).
3. CLI: `lutaml format model.lml [--check]`. `--check` exits 1 with a
   diff when the file is not canonical; without it, rewrite.
4. Idempotence law: format(format(x)) == format(x) for every corpus
   document and every generated document (TODO.properties/4).
5. Semantic-equivalence law: parse(format(parse(x))) equals parse(x)
   under the document-model comparison (define and test it here).
6. Spec annex: RS 3001 gains an informative "Canonical form" annex
   (lutaml/docs PR first, per protocol).
7. Run the formatter over spec/fixtures/rs3001 once, commit the
   canonicalized corpus, and add a CI check that fixtures stay canonical.

Acceptance: corpus canonicalizes idempotently; `--check` green on the
vendored fixtures; laws green in CI; annex merged.
