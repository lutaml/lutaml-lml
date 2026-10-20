# P2 — RS 3001 formal value-semantics annex

The value model settled this cycle — escapes, null, present-empty,
padding, quoted keys — is currently prose in two repos and law in test
code. State it once, formally, where the language lives.

1. Annex text for lutaml/docs (spec-first protocol):
   - the tri-state lattice: absent (unassigned) / null / "" — pairwise
     distinct, with the assignment table (wire form -> value)
   - the escape algebra: the representable value set under the two
     escapes; escape∘unescape = identity on that set; unescape is total
     over grammar-accepted bodies (the grammar rejects all other
     backslashes, so unescape never meets one)
   - the padding law: quoted bodies are verbatim; name/type tokens are
     interior-bounded (the #75/#77 design)
   - the key/value symmetry law: keys and values pass the same escape
     and bare-word predicates
2. Each law cross-references its property test (TODO.properties) and its
   corpus fixture (24, 25).
3. No behavior change: this annex codifies shipped behavior; if the
   annex drafting reveals divergence, the divergence is the bug — fix
   code, not the annex.
Acceptance: annex merged in lutaml/docs; the three fixtures cited from
the annex text; property tests referenced by number.
