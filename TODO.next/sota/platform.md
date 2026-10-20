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
