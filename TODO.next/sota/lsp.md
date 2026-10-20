# P2 — Language server (LSP)

A modeling language without tooling is a manuscript without readers. The
pipeline already produces everything an LSP needs; this package exposes it
over the Language Server Protocol.

1. Gem/binary `lutaml-lml-lsp` speaking stdio LSP (use a maintained Ruby
   LSP base or hand-roll the handful of messages needed).
2. textDocument/diagnostic (pull) and publishDiagnostics (push) from
   TODO.diagnostics records — full-document reparse on change.
3. documentSymbol: packages / classes / enums / attributes / instances /
   values from the document model.
4. go-to-definition and find-references: instance-type references to
   classes, values-set references to enums, reference:(path) targets to
   attributes; resolution via the existing AssociationLabelResolver-style
   symbol walk (new: a Document#symbols index).
5. Hover: attribute type/cardinality/default/pattern from the model;
   enum member payloads (compiler-extracted); Null/empty semantics note.
6. Completion: attribute names from the enclosing class; enum member
   names; keywords derived FROM THE GRAMMAR ARTIFACT (keyword list read
   from the compiled artifact so completion can never drift from the
   language).
7. textDocument/formatting via TODO.canon.
8. Error recovery: invalid documents must still yield partial trees.
   Parsanol deepest-failure gives a position, not a recovered tree — if
   error-recovery parsing is required, file the ask on parsanol with the
   LSP use case.
Acceptance: opens every RS 3001 corpus fixture in a stock LSP client with
outline, diagnostics, hover, completion; no crash on any broken input.
