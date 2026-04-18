---
phase: 03-quartus-verification-sign-off
plan: 01
subsystem: testing
tags: [xilinx, xsim, audit, upstream-integration, parser-safe-queue, sll-fix, verilator, quartus]

# Dependency graph
requires:
  - phase: 02-history-aware-upstream-integration
    provides: "Phase 2 upstream v3.38.1 merge commit 27232c2; decision ledger LCU-01/03/04, HR-03/04"
  - phase: 01-fork-delta-baseline-intent-record
    provides: "Derived merge-base 84b88033590a1469a238be84d8526b25a9f29d10; HR-01/02 residuals"
provides:
  - "Theme-grouped classification-bearing Xilinx-thematics audit over the 32-file Phase 2 import surface"
  - "Zero class-A and zero class-B findings — Phase 2 preserved all four fork Xilinx themes without regression"
  - "Plan-1 input for 03-sign-off.md §Gap Matrix row 'Intent carry-forwards'"
  - "Confirmation that LCU-01 xsim runtime flags + cleanup strings are retained verbatim"
  - "Confirmation that LCU-04 experimental-tree rename removed the legacy testcase.svh from HEAD"
affects: ["03-02 sign-off plan", "Phase 4 maintainer handoff"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "32-file AUDIT_FILES bash allowlist (no directory globs) as the single source of truth for audit scope"
    - "Diff-against-baseline theme heuristics (T1/T2/T3) instead of current-tree scans"
    - "Multi-line awk function-block scan complementing single-line diff greps for T2"
    - "Scope-fenced classification (A/B/C) with n/a row for empty themes"

key-files:
  created:
    - ".planning/phases/03-quartus-verification-sign-off/03-xilinx-thematics-audit.md"
    - ".planning/phases/03-quartus-verification-sign-off/03-01-SUMMARY.md"
  modified: []

key-decisions:
  - "Drive greps from an explicit 32-file bash allowlist, not directory globs, per reviews concern #3"
  - "Diff heuristics (T1/T2/T3) compare against merge-base 84b8803 rather than scanning current tree, per reviews concern #4"
  - "T2 uses a generic function-signature regex plus parallel task scan plus multi-line awk scan"
  - "LCU-04 sanity references git HEAD (authoritative tracked state), not working-tree file presence"
  - "Group by theme (T1..T4) per D-06 discretion recommendation and RESEARCH §Focus Area 1"

patterns-established:
  - "32-file allowlist-driven audit: declare scope fence once in bash, reuse across every grep"
  - "Marker-based classification-C evidence: prior-art comments and <<SLL-FIX>> markers count as consistent-with-theme findings"
  - "T3 anchor isolation: uvm-mock guards referenced as prior-art context only, never appearing in findings rows"

requirements-completed: [VERI-02, VERI-03]

# Metrics
duration: 3min
completed: 2026-04-18
---

# Phase 3 Plan 1: Xilinx-Thematics Audit Summary

**Theme-grouped audit of the 32-file Phase 2 upstream-integration surface (bin/, svunit_base/, src/experimental/, src/testExperimental/sv/, src/test/sv/, test/utils.py) confirming zero class-A and zero class-B findings across all four fork Xilinx themes — the upstream v3.38.1 merge preserved parser-safe queue typing, explicit input signatures, XILINX_SIMULATOR ifdef guards, and xsim runtime flags without regression.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-18T09:10:26Z
- **Completed:** 2026-04-18T09:13:25Z
- **Tasks:** 1
- **Files modified:** 2 (`03-xilinx-thematics-audit.md`, `03-01-SUMMARY.md`)

## Accomplishments

- Authored `03-xilinx-thematics-audit.md` (334 lines) with theme-grouped classification-bearing findings over all 31 live Phase 2 imported files plus the 1 deleted legacy `src/experimental/sv/testcase.svh` path.
- Confirmed Theme T1 (parser-safe queue typing): 10 prior-art dynamic-array marker comments preserved, 0 anti-pattern hits against merge-base, 58 `[$]` sites across scope.
- Confirmed Theme T2 (explicit input signatures): 16 `<<SLL-FIX>>` markers across 8 files preserved; single-line diff, multi-line awk, and parallel task scans all returned zero args-bearing anti-pattern hits.
- Confirmed Theme T3 (XILINX_SIMULATOR ifdef guards): 2 guards in scope preserved (`svunit_base/junit-xml/XmlElement.svh:62`, `svunit_base/svunit_internal_defines.svh:23`); zero guards removed by the merge.
- Confirmed Theme T4 (xsim runtime flags / cleanup): all six LCU-01 required strings present (xvlog `--relax`, xelab flag set, xsim.dir, xsim\*.\*, xelab\*.\*, xvlog.pb).
- Confirmed LCU-04 sanity: `src/experimental/sv/testcase.svh` is absent from git HEAD (the canonical path is now `src/experimental/sv/svunit/testcase.svh`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Derive 4-theme checklist + run audit greps + author audit report** — `ba39e5b` (docs)

## Files Created/Modified

- `.planning/phases/03-quartus-verification-sign-off/03-xilinx-thematics-audit.md` — Theme-grouped classification audit report (Plan 1 primary deliverable)
- `.planning/phases/03-quartus-verification-sign-off/03-01-SUMMARY.md` — This summary

**No source files were modified.** `git diff --name-only HEAD -- bin/ svunit_base/ src/ test/utils.py` returns 0 files, confirming the audit was READ-ONLY on source per D-06.

## Key Findings (Integer Counts)

| Theme | Name | Class A | Class B | Class C | Total |
|---|---|---|---|---|---|
| T1 | Parser-safe queue typing | 0 | 0 | 10 | 10 |
| T2 | Explicit input signatures | 0 | 0 | 16 | 16 |
| T3 | XILINX_SIMULATOR ifdef guards | 0 | 0 | 2 | 2 |
| T4 | xsim runtime flags / cleanup | 0 | 0 | 6 | 6 |
| **Total** | | **0** | **0** | **34** | **34** |

## Handoff to Plan 2

Plan 2's sign-off doc (`03-sign-off.md`) §Gap Matrix row "Intent carry-forwards" consumes this audit directly:

- With 0 class-A findings, no new deferred-fix items are contributed beyond those already carried from Phase 2's `02-decision-ledger.md` (LCU-01, LCU-03, LCU-04, HR-03, HR-04).
- With 0 class-B findings, no new needs-maintainer-check items are contributed either.
- The gap-matrix row can reference this audit by path and state that the Phase 2 merge preserved the fork's four Xilinx themes without regression.

## Decisions Made

- **Grep scope comes from an explicit 32-file bash allowlist** (revised from reviews concern #3 pre-execution; executed verbatim as the plan specified).
- **Theme heuristics diff against merge-base `84b8803`**, not the current tree, for T1/T2/T3 (revised from reviews concern #4).
- **T2 includes three complementary scans** — single-line diff grep, multi-line awk function-block scan, and parallel task-declaration grep — to catch multi-line signatures, tasks, and any upstream-introduced anti-patterns.
- **LCU-04 sanity references git HEAD** rather than working-tree file presence. A residual untracked copy of the legacy `src/experimental/sv/testcase.svh` existed on disk due to an unrelated pre-reset worktree state but is not tracked in git; the audit notes this explicitly for transparency.

## Deviations from Plan

None — plan executed exactly as written. The revised plan (reviews-pass 2026-04-18) already addressed reviewer concerns #3 (scope count reconciliation to 32) and #4 (T1/T2/T3 heuristic fixes) before execution, so no mid-execution deviations were needed.

One noteworthy observation (not a deviation, just transparency): the worktree started on a branch based from an older feature-branch HEAD (`c2cb871`) rather than the planned base `6c2d76c`. The worktree_branch_check protocol was invoked and a `git reset --hard 6c2d76c` aligned the branch before any audit work began. This left a small set of untracked experimental SV files from the pre-reset state on disk (`src/experimental/sv/{full_name_extraction,global_test_registry,test,test_registry,testcase,testsuite}.svh`) that are NOT tracked by git HEAD and therefore do not affect the audit — but the audit report documents this for LCU-04 clarity.

## Issues Encountered

None.

## Next Phase Readiness

- `03-xilinx-thematics-audit.md` is ready for Plan 2 to consume as the "Intent carry-forwards" gap-matrix input.
- No blockers for Plan 2 (sign-off run + consolidated sign-off doc).
- With zero class-A/class-B findings, Plan 2's gap-matrix authoring simplifies: the Xilinx-thematics row is a "no new items" cross-reference.

## Self-Check: PASSED

- `03-xilinx-thematics-audit.md`: FOUND
- `03-01-SUMMARY.md`: FOUND
- Task 1 commit `ba39e5b`: FOUND in git log
- Source file modifications: 0 (bin/, svunit_base/, src/, test/utils.py untouched)
- All 8 required headings present in audit doc (Phase 03 Xilinx-Thematics Audit, Scope, Classification Scheme, Theme T1-T4, Summary)
- Merge-base literal `84b88033590a1469a238be84d8526b25a9f29d10` present
- Scope count `32` present
- Zero unfilled `<N_[ABC]>` placeholders
- Classification tokens (`class A`, `class B`, `class C`) all present (case-insensitive)
- Theme-specific must-includes (`<<SLL-FIX>>`, `XILINX_SIMULATOR`, `xvlog --relax`, `xsim.dir`) all present

---
*Phase: 03-quartus-verification-sign-off*
*Completed: 2026-04-18*
