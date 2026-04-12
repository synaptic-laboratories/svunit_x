---
phase: 01-fork-delta-baseline-intent-record
reviewed: 2026-04-12T06:53:07Z
fixed_at: 2026-04-12T07:10:00Z
status: fixed
findings_in_scope: 2
fixed: 2
skipped: 0
iteration: 1
review_path: .planning/phases/01-fork-delta-baseline-intent-record/01-REVIEW.md
---

# Phase 01: Code Review Fix Report

## Summary

Applied both warning-level fixes from `01-REVIEW.md` to `tests/test-phase1-matrix.sh`.

## Fixes Applied

### WR-01: Non-`files` Modes Skip Evidence Presence Checks

- **Status:** fixed
- **Commit:** `63e5c1d`
- **Change:** `check_table()` now calls `check_presence`, so `classifications`, `xilinx-trace`, and `intent` fail if any required evidence artifact is missing.
- **Verification:**
  - `bash tests/test-phase1-matrix.sh files`
  - `bash tests/test-phase1-matrix.sh classifications`
  - `bash tests/test-phase1-matrix.sh xilinx-trace`
  - `bash tests/test-phase1-matrix.sh intent`
  - targeted missing-evidence check by temporarily removing `evidence/path-overlap.txt` and confirming `classifications` fails

### WR-02: Xilinx Path Allowlist Excludes Experimental Regression Files

- **Status:** fixed
- **Commit:** `d32ee67`
- **Change:** expanded the Xilinx/Vivado touched-file allowlist to include `src/testExperimental/sv/`.
- **Verification:**
  - `awk` check confirming `src/testExperimental/sv/test_registry_unit_test.sv` matches the allowlist
  - `bash tests/test-phase1-matrix.sh files`
  - `bash tests/test-phase1-matrix.sh classifications`
  - `bash tests/test-phase1-matrix.sh xilinx-trace`
  - `bash tests/test-phase1-matrix.sh intent`

## Result

All findings in scope were fixed. The original `01-REVIEW.md` remains as the historical review snapshot; this file records the remediation outcome.
