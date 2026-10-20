# P0 — Canonical form, emitter, formatter CLI

LML round-trips values today; it does not define a canonical textual form.
Without one, diffs are syntactic noise, there is no `format` tool, and the
idempotence law is unstatable. This package defines and ships the canonical
form.

1. Define the canonical form (design note in this file before code):
   - members in declaration order; deterministic from the document model
   - two-space indent; one blank line between top-level members
   - attributes: the explicit block form whenever non-default members
     exist (type, cardinality, default, pattern, properties); the terse
     comma form (`attribute name, Type`) otherwise
   - quoting policy reuses the emit predicates: bare only for
     [A-Za-z0-9_] (values and keys alike); double quotes with the two
     RS 3001 escapes otherwise
   - comments: line comments preserved attached to their member; block
     comments kept verbatim after layout-edge strip
   - null vs absent: omitted line for nil (current policy), `null` only
     where the author wrote it — canonicalization records intent
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
