---
phase: 03-quartus-verification-sign-off
fixed_at: 2026-04-18T00:00:00Z
review_path: .planning/phases/03-quartus-verification-sign-off/03-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 03: Code Review Fix Report

**Fixed at:** 2026-04-18T00:00:00Z
**Source review:** .planning/phases/03-quartus-verification-sign-off/03-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (fix_scope=critical_warning — WR-01, WR-02)
- Fixed: 2
- Skipped: 0
- Info findings (IN-01 through IN-06) were out of scope and were not touched.

## Fixed Issues

### WR-01: Raw test-log inlined into markdown code fence without backtick-escaping

**Files modified:** `scripts/certify.sh`
**Commit:** 047c3e7
**Applied fix:** Replaced the inline `cat "${OUTPUT_DIR}/test-log.txt"` command-substitution
inside a ```` ```text ```` fence (lines 482-489 in the original) with a short linking
heredoc that points the reader at `test-log.txt` in the Evidence directory. The evidence
artefact is already enumerated in the Evidence section (line 473), so linking is sufficient.
This is Option B from the reviewer's suggestion. Chose Option B over Option A (widening
to a 4-backtick fence) because it also removes the secondary concern of holding a multi-MB
log in bash memory via command substitution, and keeps the markdown artefact small.

Verification:
- Tier 1: re-read lines 470-499; confirmed `TAILEOF`, container-adapter `if` block, and
  new `RAWEOF` heredoc structure intact; outer `{ ... } > "${OUTPUT_DIR}/qualification-results.md"`
  still closes correctly.
- Tier 2: `bash -n scripts/certify.sh` returned clean (SYNTAX OK).

### WR-02: JUnit XML counter parse silently falls back to 0 on malformed XML

**Files modified:** `scripts/certify.sh`
**Commit:** 4ec498d
**Applied fix:** Replaced the four independent `grep -oP '...' | head -1 || echo "0"`
pipelines (lines 285-289 in the original) with a single atomic `python3` invocation using
`xml.etree.ElementTree`. The parser prefers the top-level element's aggregate attrs
(`tests`, `failures`, `errors`, `skipped`) if present, otherwise sums across direct
`<testsuite>` children — handling both a bare `<testsuite>` root and a `<testsuites>`
wrapper whether or not the wrapper carries aggregate attrs. `ParseError` and `OSError`
are caught and emit a diagnostic to stderr with `sys.exit(2)`, which the enclosing
`if xml_counts="$(...)"; then ... else ... fi` catches and logs as
`WARN: tests.xml parse failed; marking run as FAIL`. This distinguishes "parse failure"
from "no tests ran" in the build-info.json / test-log.txt trail, which was the
triage-ambiguity concern the reviewer flagged. Python3 is already a `commonRuntimeInputs`
entry in `nix/mk-certify.nix:33` (`pythonWithPytest`), so there is no new dependency.

Design notes:
- Refined the reviewer's suggested snippet (which had a duplicate `node = root if ... else root`
  and an unclear `attrs = root.attrib if "tests" in ... else root[0].attrib` fallback).
  The rewritten parser is explicit: check `"tests" in root.attrib` first, otherwise sum
  the direct children. This correctly handles pytest emitters that wrap in `<testsuites>`
  with aggregates on the wrapper, emitters that wrap without aggregates, and single
  `<testsuite>` roots.
- `int()` coercion is wrapped in a helper that returns 0 for missing/malformed attrs,
  matching the prior behaviour for individual attributes while still aborting on
  structural parse errors.
- The `if xml_counts="$(...)"; then ... else ... fi` pattern was validated locally as
  honouring `set -euo pipefail` correctly: `set -e` is suspended for the `if` condition
  (standard bash semantics), and a non-zero python exit routes to the diagnostic branch.

Verification:
- Tier 1: re-read lines 280-334; confirmed python heredoc closes with `PY`, `read -r` into
  the four counter variables executes on success, else-branch zeroes counters, downstream
  STATUS comparison (line 333) unchanged.
- Tier 2: `bash -n scripts/certify.sh` returned clean (SYNTAX OK).
- Extra: validated the `if cmd="$(...)"; then ... else ... fi` pattern under
  `set -euo pipefail` with an inline smoke test (success → then-branch with captured
  stdout; non-zero exit → else-branch taken, captured stdout still populated).

## Skipped Issues

None. Both in-scope findings were fixed.

Out-of-scope findings (not attempted under `fix_scope=critical_warning`):
- IN-01: pytest-filter quoting robustness in container heredoc (certify.sh:219)
- IN-02: `--cap-add=NET_ADMIN` over-granting (certify.sh:236, quartus-shell.sh:111)
- IN-03: flock / mkdir ordering preflight race (03-reproduce.sh:127 vs 164-166)
- IN-04: `uname -m` -> Nix system string mapping (03-reproduce.sh:147,155)
- IN-05: `$0` vs `${BASH_SOURCE[0]}` in --help grep (03-reproduce.sh:71)
- IN-06: xhost-user token split validation (quartus-shell.sh:24,81-84)

---

_Fixed: 2026-04-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
