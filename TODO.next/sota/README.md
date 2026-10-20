# SOTA program — vision and index

Purpose of lutaml-lml: the normative reference implementation of the LutaML
Modeling Language (RS 3001 + RS 3010) — a human-writable, spec-defined text
language for information models and their data, compiled into runtime-typed
lutaml-model classes, interoperating with JSON/YAML/XML/CSV and JSON/YAML
Schema, and rendering diagrams.

The purpose is fully reached — SOTA — when three properties hold:

  PROOF    fidelity is enforced by generative laws, not examples
  CANON    a defined canonical form exists, with a formatter and
           idempotence guarantee
  INTERFACE every diagnostic carries position + code + remedy, and a
           language server exposes the language to editors

This directory is the program. Each file is a self-contained work package
with numbered items and acceptance criteria. Priority order:

  P0  canon.md       canonical form, emitter, formatter CLI
  P0  properties.md  generative round-trip laws
  P1  diagnostics.md structured diagnostics
  P1  contract.md    continuous strict-contract verification
  P2  lsp.md         language server
  P2  formal.md      RS 3001 formal value-semantics annex
  P3  platform.md    language-version negotiation; JS/Opal feasibility

Items are cited as TODO.next/sota/<file>#<n>. Each file carries its own
acceptance criteria; do not close an item without them.

Standing protocol for every item in this program:

- RS 3001 changes land spec-first in lutaml/docs, then here.
- One unit of work = one branch = one PR; rebase-merge the moment CI is
  green; never more than one open PR in this repo.
- The rubocop ratchet gates every touched file; suite must stay green.
- lutaml-model / parsanol / moxml floors move only on evidence, with the
  evidence commit pinned in the PR (the #80 pattern).
- Version numbers for releases come from the owner, never inferred.
- Validate empirically before fixing: reproduce, then fix, then pin with
  a spec or corpus fixture.
