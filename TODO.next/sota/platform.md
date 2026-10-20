# P3 — Platform assurance: version negotiation; JS/Opal feasibility

Two long-horizon items, both needing design decisions before code.

1. Language-version negotiation.
   Documents record data-model versions (`models X version "y.z"`) but
   nothing declares WHICH LML grammar a document speaks. Design first:
   - proposal A: a prologue line `lml "1.0"` before the first member
   - proposal B: extend the existing block headers
   Decide: strictness (reject newer than supported vs warn), the
   grammar-artifact version as the source of truth, and the corpus
   migration. Then implement: parser acceptance, warning diagnostics,
   corpus headers, spec amendment (lutaml/docs first).
2. JS/Opal leg — feasibility before porting.
   The grammar artifact is JSON and portable; parsanol is the blocker
   (Ruby engine + native paths). Write the feasibility note:
   - artifact-driven interpreter in JS vs Opal-compiled lutaml-lml
   - what lutaml-model-js assumes of us
   - the moxml/pdfrb/graphviz surfaces under JS (renderer story first:
     svg only?)
   Record the decision here; port only on an explicit go.
Acceptance: (1) design note + amendment + implementation + corpus;
(2) feasibility note with a recorded decision, no porting without a go.

## Design decisions (2026-10-20)

### Language version negotiation

- **Proposal A adopted.** The prologue is an optional first line,
  `lml "x.y"`. It is unambiguous, needs one grammar production, is
  independent of the data-model version (`models X version "y.z"`), and
  is naturally first in canonical output.
- **Strictness: warn, never reject.** A document declaring a version
  newer than the build parses and validates, with warning
  `contract/LML-C06` positioned at the version string. Tooling can still
  inspect future documents, and forward compatibility is preserved.
- **Source of truth: the grammar artifact.** `Grammar.version` reads the
  compiled artifact's version (1.0.0). Comparison uses `Gem::Version`;
  trailing component zeros are equivalent (1.0 = 1.0.0).
- **Corpus migration.** Every RS 3001 fixture declares `lml "1.0"`; the
  canonical emitter writes the prologue first when present and never
  invents one. Fixture 26 exercises quoted keys.
- **Spec amendment:** RS 3001 gains a Language version section and the
  canonical group order mentions the prologue (lutaml/docs PR, spec-first
  before this code merges).

### JS/Opal leg — feasibility and decision

Decision: **do not port now**. If a port is approved later, start with an
artifact-driven interpreter in JavaScript, not an Opal build.

- The grammar artifact is JSON and portable. A JS interpreter can walk
  the compiled atom tree; the work is reproducing parsanol's skip-trivia
  injection and the Ruby transform/data-processor/builder pipeline, not
  the grammar itself.
- Opal would carry the entire Ruby pipeline (plus lutaml-model) and still
  needs an interpreter for the native parser path; the payload and
  debugging cost are higher without removing the blocker.
- parsanol is the blocker either way. Any port must match its
  skip-injection and capture semantics; the RS 3001 corpus is the
  conformance gate.
- lutaml-model-js would consume the compiled class metadata that
  ModelCompiler produces (attribute types, collections, XML/key-value
  mappings), not Ruby class objects.
- Dependency surfaces: moxml has an XML story in JS; pdfrb and
  ruby-graphviz do not. First-class JS scope would be parse, validate,
  canonical emit, and SVG rendering only.
- Keep the Ruby implementation normative; the corpus and property laws
  define conformance for any port.

