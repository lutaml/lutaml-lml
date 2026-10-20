# P0 — Generative round-trip laws

The quoting-contract table proved its worth by catching two real defects on
its first day (#68). Examples audit points; laws prove properties. This
package replaces pointwise assurance with generative laws.

1. Add a property engine as a development dependency (prefer `rantly`;
   re-evaluate maintained-ness at adoption). Seeded, reproducible: every
   failure prints the seed and the shrinking trace.
2. Generators:
   - strings: arbitrary unicode incl. quotes, backslashes, control-adjacent
     chars, padding, empty; the bare-word subset; the both-quote-kinds set
   - absent / null / present-empty as distinct generated cases
   - keys: bare, quoted, escaped, empty
   - documents: grammar-directed bounded generator (packages, classes,
     enums incl. values-as-instances, instances, mappings) — depth- and
     size-bounded, seed-controlled
3. Laws:
   L1 value fidelity — for generated v and typed attribute a:
      a.from_lml(a.new(value: v).to_lml).value == v
   L2 key fidelity — generated keys round-trip through emit/parse
   L3 document semantics — generated documents: parse(emit(d))
      semantically equals d (per the document-model comparison from
      TODO.canon/5)
   L4 idempotence — canonical emitter law (needs TODO.canon)
4. Cadence: PR runs reduced depth (fast); nightly runs full depth with a
   distinct seed stream; failures file themselves (seed + minimal case in
   the job log).
Acceptance: L1-L3 green in CI with shrinking on failure; L4 lands with
TODO.canon.
