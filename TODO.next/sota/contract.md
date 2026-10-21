# P1 — Continuous strict-contract verification

The 0.8.96 breakage shipped because the suite ran only the released
lutaml-model; the #80 fix happened only because a floor PR forced the
run. Institutionalize that discovery: verify against dependency HEAD
continuously, tighten floors on evidence.

1. Scheduled workflow (daily): the suite against:
   - lutaml-model HEAD (git ref)
   - parsanol HEAD
   - moxml HEAD
   one job each, clearly labeled HEAD-verification (not gating).
2. Rollout discipline: allow-failure first; promote to required once
   green for N consecutive days (N = 7).
3. Breakage protocol: reproduce locally against the pinned HEAD commit,
   file upstream with the evidence, pin a floor here only with the
   breaking-commit SHA cited in the PR (the #80 pattern, made law).
4. Keep a short log section in this file: date, dependency, commit,
   outcome — the floor history that #80 established by accident.
Acceptance: scheduled runs exist and report; the log has its first entry;
no future dependency breakage ships in a release.

## Verification log

Run with the Gemfile path override (the same mechanism the scheduled
workflow uses):

| Date | Dependency | Commit | Outcome |
| --- | --- | --- | --- |
| 2026-10-20 | lutaml-model | `0697ecf` | green (816 examples) |
| 2026-10-20 | parsanol | `4152e11` | red: `dsl_spec.rb:268` expects the deepest failure at line 25 char 32; HEAD reports the top-level sequence failure at line 1 char 1 |
| 2026-10-20 | moxml | `59c20d0` | green (816 examples) |

The parsanol HEAD finding is an error-reporting change, not a parse
failure: broken input still raises `ParsingError`, but the position no
longer points at the deepest failure. Record it upstream (parsanol) with
this repro before changing the suite or pinning a floor.

First scheduled-workflow dispatch (2026-10-21, run 39531086873):
lutaml-model HEAD green, moxml HEAD green, parsanol HEAD red with the
same error-position finding. The workflow reports success under the
allow-failure rollout as designed.

