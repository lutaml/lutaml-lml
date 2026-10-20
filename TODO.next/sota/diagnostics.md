# P1 — Structured diagnostics

Diagnostics are the user experience of a language. Parse failures already
carry positions (parsanol deepest-failure); semantic failures are strings.
SOTA: every diagnostic is a record, machine-renderable, with a remedy.

1. Diagnostic record (Lutaml::Lml::Diagnostic): code, severity, file,
   line, column, length (optional), message, remedy. Codes namespaced:
   parse/LML-0xx, validation/LML-Vxx, hydration/LML-Hxx, contract/LML-Cxx.
2. Pipeline raises Diagnostic-carrying errors (ParsingError gains the
   record) instead of formatted strings; message rendering stays
   human-identical so existing tests port mechanically.
3. Source positions for semantic errors: parsanol attaches capture
   offsets in the raw tree; the transform post-pass retains offsets for
   name/value nodes onto the document model so validation and hydration
   violations can cite file/line/col.
4. Validator violations carry positions of the offending member.
5. CLI `--format json` emits the diagnostic array machine-readably;
   default rendering stays text with `path:line:col: [CODE] message` +
   remedy line.
6. Document the code registry in README (table) and keep it in the
   diagnostics module as the single source.
Acceptance: file-backed errors cite positions end-to-end; JSON output
stable; registry documented; no string-only errors remain.
