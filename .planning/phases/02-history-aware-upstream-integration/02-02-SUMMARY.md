---
phase: 02-history-aware-upstream-integration
plan: "02"
subsystem: runtime
tags: [merge, upstream-sync, xilinx, experimental, junit]
requires:
  - phase: 02-01
    provides: clean pre-merge anchor, seeded decision ledger, and phase 2 validator
provides:
  - upstream v3.38.1 integrated into the forked codebase
  - ledger-backed dispositions for LCU-01 through LCU-06 during merge resolution
  - repaired experimental and host-side helper surfaces for later Phase 3 sign-off
affects: [02-03, phase-3-quartus, maintainer-review]
tech-stack:
  added: []
  patterns:
    - resolve upstream merge conflicts by LCU intent instead of by patch text
    - preserve local simulator-specific behavior as narrow residual diffs on top of upstream structure
key-files:
  created:
    - svunit_base/svunit_test.svh
    - test/test_list_tests.py
  modified:
    - bin/runSVUnit
    - bin/cleanSVUnit
    - svunit_base/svunit_pkg.sv
    - svunit_base/svunit_testcase.sv
    - svunit_base/svunit_testsuite.sv
    - svunit_base/svunit_testrunner.sv
    - svunit_base/junit-xml/XmlElement.svh
    - src/experimental/sv/svunit.sv
    - src/experimental/sv/svunit/testcase.svh
    - src/experimental/sv/svunit/testsuite.svh
    - src/testExperimental/sv/test_registry_unit_test.sv
    - test/utils.py
    - .planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md
key-decisions:
  - "Keep the upstream CLI and experimental layout as the baseline, then carry forward only the narrow xsim and parser-safe differences that still have local justification."
  - "Treat test/utils.py as a justified replacement rather than pretending the original fork hunk was valid Python."
patterns-established:
  - "Merge-ledger pattern: every LCU resolution is written down while the merge is happening, not reconstructed afterward."
  - "Residual-diff pattern: keep local xsim/runtime behavior as explicit residual edits on top of upstream v3.38.1 instead of replaying the old fork patch wholesale."
requirements-completed: [XILX-03, SYNC-01, SYNC-02]
duration: 9m 37s
completed: 2026-04-12
---

# Phase 02 Plan 02: Upstream Integration Summary

**Upstream `v3.38.1` is merged into the fork, with local xsim behavior, parser-safe queue typing, and the explicit `test/utils.py` replacement recorded in the decision ledger**

## Performance

- **Duration:** 9m 37s
- **Started:** 2026-04-12T08:29:03Z
- **Completed:** 2026-04-12T08:38:40Z
- **Tasks:** 3
- **Files modified:** 13 key surfaces plus the upstream merge set

## Accomplishments
- Merged upstream `v3.38.1` into the fork and resolved all merge conflicts without leaving unmerged paths or conflict markers.
- Preserved the local xsim runtime and cleanup behavior on top of the upstream CLI surface, keeping `-e|--e_arg`, `--list-tests`, and the upstream simulator-discovery behavior intact.
- Ported the parser-safe queue typing and Xilinx-sensitive helper behavior onto the upstream stable-runtime and experimental layouts, and repaired `test/utils.py` as an explicit justified replacement.

## Task Commits

This plan was executed as a real `git merge --no-commit --no-ff`, so the code work landed in one merge commit after all path groups were resolved:

1. **Task 1: Merge upstream `v3.38.1` and resolve the CLI / cleanup surface** - `27232c2` (`feat`)
2. **Task 2: Resolve stable-runtime and helper-library overlaps by intent** - `27232c2` (`feat`)
3. **Task 3: Resolve experimental-flow and host-side regression surfaces** - `27232c2` (`feat`)

## Files Created/Modified
- `bin/runSVUnit` - Upstream CLI retained with local xsim `xvlog --relax` and `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps` carried forward.
- `bin/cleanSVUnit` - Retained the local xsim/Vivado cleanup set on top of the upstream base.
- `svunit_base/svunit_pkg.sv` - Preserved the local `__svunit_fatal` wrapper while keeping the upstream package structure.
- `svunit_base/svunit_testcase.sv` - Combined upstream test-list support with explicit `input` signatures and queue typing.
- `svunit_base/junit-xml/XmlElement.svh` - Kept the local Xilinx string-copy workaround together with upstream XML escaping.
- `src/experimental/sv/svunit/testcase.svh` - Preserved queue-based parser-safe typing in the moved upstream layout.
- `src/testExperimental/sv/test_registry_unit_test.sv` - Kept queue-based experimental regression typing aligned with the merged API.
- `test/utils.py` - Replaced the invalid `simulators = [$]` line with `simulators = []` while retaining the explicit `xsim` detection path.
- `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` - Recorded the final LCU outcomes for the merge.

## Decisions Made
- Used upstream `v3.38.1` as the structural baseline everywhere, then kept only the residual local differences that still mapped to documented Xilinx/parser intent.
- Resolved `LCU-02` fully to upstream help text and `LCU-06` to a justified replacement, rather than carrying those fork hunks forward literally.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Consolidated the code work into one merge commit**
- **Found during:** Tasks 1-3 across the active `git merge --no-commit --no-ff`
- **Issue:** The three path groups shared one in-progress merge state, so git could not safely finalize separate task commits while unresolved paths still existed.
- **Fix:** Resolved the CLI, stable-runtime, experimental, and host-side surfaces against the shared merge index, then finalized them together in one merge commit while keeping the per-LCU rationale in `02-decision-ledger.md`.
- **Files modified:** `bin/runSVUnit`, `bin/cleanSVUnit`, `svunit_base/*`, `src/experimental/sv/*`, `test/utils.py`, `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md`
- **Verification:** `git diff --name-only --diff-filter=U`; `perl -c bin/runSVUnit`; `perl -c bin/cleanSVUnit`; `bash tests/test-phase2-integration.sh review`
- **Committed in:** `27232c2`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The merge still delivered the planned outcomes, but the code changes had to be finalized as one merge commit because the path groups shared one merge transaction.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 3 can now summarize the integrated tree using the already-populated LCU outcomes in `02-decision-ledger.md`.
- The remaining explicit human-review scope is narrower: ancestry wording plus the maintainer check on retained xsim/parser-sensitive outcomes before Quartus sign-off.
- `tests/test-phase2-integration.sh` continues to pass `review` and `requirements` using the ledger fallback until the final integration summary exists.

## Self-Check: PASSED
