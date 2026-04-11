---
phase: 01-fork-delta-baseline-intent-record
plan: "02"
subsystem: testing
tags: [git, evidence, matrix, xilinx, upstream-sync]
requires:
  - phase: 01-01
    provides: pinned upstream target, derived merge-base, and baseline review guardrails
provides:
  - replayable shell validation for the phase 1 matrix artifact set
  - raw fork-only, range-diff, and path-overlap evidence from the true merge-base
  - master logical-change matrix with keep, superseded, rewrite, and human-review classifications
affects: [01-03, phase-2-sync, xilinx-review]
tech-stack:
  added: []
  patterns:
    - pair each logical change unit with raw git evidence and an explicit merge classification
    - default parser-sensitive Xilinx/Vivado changes to rewrite or human-review unless upstream subsumption is concrete
key-files:
  created:
    - tests/test-phase1-matrix.sh
    - .planning/phases/01-fork-delta-baseline-intent-record/evidence/fork-only.log
    - .planning/phases/01-fork-delta-baseline-intent-record/evidence/range-diff.txt
    - .planning/phases/01-fork-delta-baseline-intent-record/evidence/path-overlap.txt
    - .planning/phases/01-fork-delta-baseline-intent-record/01-fork-delta-matrix.md
    - .planning/phases/01-fork-delta-baseline-intent-record/01-02-SUMMARY.md
  modified: []
key-decisions:
  - "Split 8e7d8d35e68a2deb0923871de998b13782f5f5ec only along clean subsystem threads, and keep c2cb87111cf93cbf0f3f485730d314dbad3cb858 separate because range-diff identifies a direct upstream counterpart."
  - "Treat stable-runtime and experimental parser-compatibility edits as rewrite candidates, keep helper-library parser fixes as local until proven unnecessary, and leave the suspicious `test/utils.py` simulator edit as human-review."
patterns-established:
  - "Matrix evidence pattern: validator plus fork-only log, path overlap, and range-diff references on every material row."
  - "Classification pattern: unmatched Xilinx/Vivado parser changes do not get auto-collapsed to superseded."
requirements-completed: [BASE-02, BASE-03, XILX-01, XILX-02]
duration: 8m 33s
completed: 2026-04-11
---

# Phase 01 Plan 02: Fork Delta Matrix Summary

**Fork-delta matrix with replayable git evidence, Xilinx/Vivado change units, and merge classifications from the verified merge-base**

## Performance

- **Duration:** 8m 33s
- **Started:** 2026-04-11T13:45:29Z
- **Completed:** 2026-04-11T13:54:02Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added `tests/test-phase1-matrix.sh` with reusable `files`, `classifications`, `xilinx-trace`, and `intent` checks.
- Captured replayable `fork-only.log`, `range-diff.txt`, and `path-overlap.txt` evidence from merge-base `84b88033590a1469a238be84d8526b25a9f29d10`.
- Built `.planning/phases/01-fork-delta-baseline-intent-record/01-fork-delta-matrix.md` with row-level intent, Xilinx traceability, and `keep`/`superseded`/`rewrite`/`human-review` classifications.

## Task Commits

Each task was committed atomically:

1. **Task 1: Install replayable matrix verification checks** - `401e179` (`feat`)
2. **Task 2: Capture fork-only commit, overlap, and counterpart evidence** - `76941c8` (`feat`)
3. **Task 3: Build the master logical-change matrix** - `fda1ec0` (`feat`)

## Files Created/Modified
- `tests/test-phase1-matrix.sh` - Shell verifier for matrix presence, valid classifications, Xilinx traceability, and row-level intent completeness.
- `.planning/phases/01-fork-delta-baseline-intent-record/evidence/fork-only.log` - Replayable fork-only commit list plus `git show --stat --name-only` output for both fork-only commits.
- `.planning/phases/01-fork-delta-baseline-intent-record/evidence/range-diff.txt` - Human-review-only `git range-diff` capture against upstream `v3.38.1`.
- `.planning/phases/01-fork-delta-baseline-intent-record/evidence/path-overlap.txt` - Explicit overlap surface between the fork-only delta and upstream target changes.
- `.planning/phases/01-fork-delta-baseline-intent-record/01-fork-delta-matrix.md` - Master logical-change table with classifications, purpose notes, and merge-handling guidance.
- `.planning/phases/01-fork-delta-baseline-intent-record/01-02-SUMMARY.md` - Execution summary for the fork-delta evidence and matrix plan.

## Decisions Made
- Split the large `8e7d8d35e68a2deb0923871de998b13782f5f5ec` patch only where the patch hunks formed reviewable subsystem threads, rather than flattening everything to one row or one-file granularity.
- Marked the `c2cb87111cf93cbf0f3f485730d314dbad3cb858` help-text follow-up as `superseded` because `range-diff` exposes upstream counterpart `93d3e7e`.
- Treated the stable-runtime and experimental parser-compatibility rows as `rewrite` because upstream changed the same files substantially after the fork point.
- Left the `test/utils.py` simulator-enumeration edit as `human-review` because the recorded `simulators = [$]` line is not trustworthy enough to auto-carry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a temporary matrix skeleton to satisfy the Task 2 file gate**
- **Found during:** Task 2 (Capture fork-only commit, overlap, and counterpart evidence)
- **Issue:** The plan required `bash tests/test-phase1-matrix.sh files` after Task 2, but that verifier is defined to require `01-fork-delta-matrix.md` even though Task 3 is the step that populates the matrix.
- **Fix:** Created a minimal `01-fork-delta-matrix.md` skeleton in Task 2 so the artifact-presence gate could pass, then replaced it with the full logical-change matrix in Task 3.
- **Files modified:** `.planning/phases/01-fork-delta-baseline-intent-record/01-fork-delta-matrix.md`
- **Verification:** `bash tests/test-phase1-matrix.sh files`; later `bash tests/test-phase1-matrix.sh classifications && bash tests/test-phase1-matrix.sh xilinx-trace && bash tests/test-phase1-matrix.sh intent`
- **Committed in:** `76941c8` and completed in `fda1ec0`

**2. [Rule 3 - Blocking] Force-added the planned `fork-only.log` artifact because ignore rules excluded it**
- **Found during:** Task 2 (Capture fork-only commit, overlap, and counterpart evidence)
- **Issue:** `.gitignore` excluded `evidence/fork-only.log`, which blocked the required task commit even though the plan mandates that file as a tracked artifact.
- **Fix:** Staged the file with `git add -f` and kept the plan-mandated path unchanged.
- **Files modified:** `.planning/phases/01-fork-delta-baseline-intent-record/evidence/fork-only.log`
- **Verification:** `bash tests/test-phase1-matrix.sh files`; `rg -n "8e7d8d35e68a2deb0923871de998b13782f5f5ec|c2cb87111cf93cbf0f3f485730d314dbad3cb858" .planning/phases/01-fork-delta-baseline-intent-record/evidence/fork-only.log`
- **Committed in:** `76941c8`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were needed to satisfy the plan's own verification and artifact-tracking requirements. No scope expansion beyond the evidence and matrix surface.

## Issues Encountered
- A literal `|` inside the first draft of the matrix notes broke the Markdown-table parser in `tests/test-phase1-matrix.sh`. Rephrasing that note removed the extra column and restored all Task 3 checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `01-03` can now build the executive summary and human-review handoff directly from the matrix rows and evidence files.
- Phase 2 has the exact merge-base, fork-only commit evidence, overlap surface, and row-level classifications needed for history-aware integration work.
- The baseline ambiguity from `01-01` remains active: later phases still must not silently collapse the remembered `v3.37.0` baseline or the candidate-marker first-parent mismatch.

## Self-Check: PASSED
