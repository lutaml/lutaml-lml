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
