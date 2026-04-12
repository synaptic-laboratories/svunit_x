---
phase: 01-fork-delta-baseline-intent-record
reviewed: 2026-04-12T06:53:07Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - tests/test-phase1-baseline.sh
  - tests/test-phase1-matrix.sh
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-04-12T06:53:07Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the two phase-1 shell validators at standard depth and sanity-ran their exposed subcommands against the current phase artifacts. The current artifacts pass, but `tests/test-phase1-matrix.sh` has two reliability gaps: one lets validation modes succeed without confirming the cited evidence files exist, and one can reject legitimate Xilinx-related rows because the path allowlist is narrower than the repo's actual experimental test surface.

## Warnings

### WR-01: Non-`files` Modes Skip Evidence Presence Checks

**File:** `tests/test-phase1-matrix.sh:33-36`
**Issue:** `check_table()` only requires `01-fork-delta-matrix.md`, while the `classifications`, `xilinx-trace`, and `intent` subcommands all call that function directly. If a caller runs one of those modes without first running `files`, the script can report success even when `evidence/fork-only.log`, `evidence/range-diff.txt`, or `evidence/path-overlap.txt` are missing. That weakens the test's reliability because `evidence_refs` is validated mostly as text, not as a real artifact dependency.
**Fix:**
```sh
check_table() {
    mode=$1

    check_presence

    awk -v mode="$mode" '
        ...
    ' "$MATRIX_FILE"
}
```

### WR-02: Xilinx Path Allowlist Excludes Experimental Regression Files

**File:** `tests/test-phase1-matrix.sh:82-84`
**Issue:** `has_allowed_path()` accepts `src/experimental/sv/` and `test/`, but not `src/testExperimental/sv/`, which is a real repo test surface for the experimental flow. A future Xilinx/Vivado-relevant row that only cites experimental regression files under `src/testExperimental/sv/` will fail `xilinx-trace` even though the row names legitimate touched files.
**Fix:**
```awk
function has_allowed_path(value) {
    return value ~ /(bin\/|svunit_base\/|src\/experimental\/sv\/|src\/testExperimental\/sv\/|test\/|README\.md|CHANGELOG\.md|docs\/)/
}
```

---

_Reviewed: 2026-04-12T06:53:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
