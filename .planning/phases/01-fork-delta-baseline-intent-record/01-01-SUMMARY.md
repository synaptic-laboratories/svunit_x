---
phase: 01-fork-delta-baseline-intent-record
plan: "01"
subsystem: testing
tags: [git, jq, baseline, evidence, upstream-sync]
requires: []
provides:
  - replayable shell verification for the pinned upstream baseline artifacts
  - machine-readable upstream baseline manifest with exact hashes and discrepancy flags
  - raw remote-ref and merge-base evidence for the Phase 1 sync target
  - human-review note for baseline and marker ancestry disagreements
affects: [01-02, 01-03, phase-2-sync]
tech-stack:
  added: []
  patterns:
    - pair machine-readable manifests with raw git evidence and a shell verifier
    - classify ancestry ambiguity as human-review instead of auto-resolving it
key-files:
  created:
    - .planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json
    - .planning/phases/01-fork-delta-baseline-intent-record/evidence/refs.txt
    - .planning/phases/01-fork-delta-baseline-intent-record/evidence/merge-base.txt
    - .planning/phases/01-fork-delta-baseline-intent-record/01-baseline-review.md
    - .planning/phases/01-fork-delta-baseline-intent-record/01-01-SUMMARY.md
  modified:
    - tests/test-phase1-baseline.sh
key-decisions:
  - "Use https://github.com/svunit/svunit.git as the authoritative upstream and pin the exact tag object and peeled commit in repo artifacts."
  - "Treat the remembered v3.37.0 baseline mismatch and candidate-marker first-parent mismatch as human-review while allowing later phases to rely on the pinned target and merge-base."
patterns-established:
  - "Baseline proof pattern: raw ls-remote output + structured merge-base evidence + JSON manifest + shell verifier."
  - "Discrepancy handling pattern: preserve unresolved ancestry interpretations in a dedicated review note and prohibit silent auto-resolution."
requirements-completed: [BASE-01]
duration: 4m 41s
completed: 2026-04-11
---

# Phase 01 Plan 01: Baseline Target Pinning Summary

**Pinned upstream `v3.38.1` to exact git hashes, recorded the true fork merge-base, and captured the baseline/marker ancestry disagreements as explicit human-review artifacts**

## Performance

- **Duration:** 4m 41s
- **Started:** 2026-04-11T13:32:12Z
- **Completed:** 2026-04-11T13:36:53Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added `tests/test-phase1-baseline.sh` with replayable `refs` and `graph` checks for the Phase 1 baseline artifacts.
- Wrote `.planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json` plus raw `refs.txt` and `merge-base.txt` evidence from live git commands.
- Recorded the remembered-baseline mismatch and candidate-marker semantic mismatch in `.planning/phases/01-fork-delta-baseline-intent-record/01-baseline-review.md` as `human-review`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Install replayable baseline verification checks** - `31b8770` (`feat`)
2. **Task 2: Record the authoritative upstream target and computed graph** - `8993602` (`feat`)
3. **Task 3: Classify baseline and marker mismatches as human-review** - `af91f94` (`feat`)

## Files Created/Modified
- `tests/test-phase1-baseline.sh` - Shell verifier for baseline refs and ancestry-review artifacts.
- `.planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json` - Pinned manifest of upstream URL, target hashes, merge-base, marker semantics, and disposition.
- `.planning/phases/01-fork-delta-baseline-intent-record/evidence/refs.txt` - Raw `git ls-remote --tags` output for `v3.37.0` and `v3.38.1`.
- `.planning/phases/01-fork-delta-baseline-intent-record/evidence/merge-base.txt` - Structured output from merge-base and descendant computations.
- `.planning/phases/01-fork-delta-baseline-intent-record/01-baseline-review.md` - Human-review note for ancestry disagreements and later-phase guardrails.
- `.planning/phases/01-fork-delta-baseline-intent-record/01-01-SUMMARY.md` - Execution summary for the pinned-baseline plan.

## Decisions Made
- Used the authoritative upstream URL instead of the fork remote so the pinned target came from `svunit/svunit`, not local mirror state.
- Preserved both descendant interpretations for the candidate marker and made the disagreement reviewable instead of collapsing it to one story.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created the planned `tests/` directory**
- **Found during:** Task 1 (Install replayable baseline verification checks)
- **Issue:** The repo had `test/` but not the plan-mandated `tests/` path, so the verifier could not be created where the plan expected it.
- **Fix:** Created `tests/` and added `tests/test-phase1-baseline.sh` there.
- **Files modified:** `tests/test-phase1-baseline.sh`
- **Verification:** `bash -n tests/test-phase1-baseline.sh`; `sh tests/test-phase1-baseline.sh refs`
- **Committed in:** `31b8770`

**2. [Rule 1 - Bug] Aligned the verifier with the planned manifest schema**
- **Found during:** Task 2 (Record the authoritative upstream target and computed graph)
- **Issue:** The initial verifier required an unplanned `remembered_baseline_tag_object` JSON key and did not explicitly pin the full-ancestry descendant to the expected candidate marker value.
- **Fix:** Kept the baseline tag-object check in raw evidence only and added the explicit full-ancestry descendant expectation.
- **Files modified:** `tests/test-phase1-baseline.sh`
- **Verification:** `bash -n tests/test-phase1-baseline.sh`; `bash tests/test-phase1-baseline.sh refs`
- **Committed in:** `8993602`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were required for correctness and plan compliance. No scope expansion beyond the baseline-verification surface.

## Issues Encountered
- `bash tests/test-phase1-baseline.sh graph` initially failed because the review note used equivalent wording but not the exact `silent auto-resolution` phrase enforced by the verifier. Updating the note resolved the failure without changing the intended disposition.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase `01-02` can consume the pinned target commit, merge-base, and raw evidence directly.
- The `human-review` status on the remembered baseline and candidate-marker first-parent semantics remains active and must not be collapsed silently in later phases.

## Self-Check: PASSED
