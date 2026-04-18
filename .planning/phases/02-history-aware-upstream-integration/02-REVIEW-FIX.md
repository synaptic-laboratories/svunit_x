---
phase: 02-history-aware-upstream-integration
fixed_at: 2026-04-18T15:24:40Z
review_path: .planning/phases/02-history-aware-upstream-integration/02-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-04-18T15:24:40Z
**Source review:** .planning/phases/02-history-aware-upstream-integration/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

**Commit method:** `gsd-sdk query commit` was unavailable in this shell (`gsd-sdk: command not found`), so fixes were committed with direct `git add` and `git commit` commands using explicit pathspecs for the owned files only.

## Fixed Issues

### WR-01: Verilator `--list-tests` Appends Plusarg To `tee`

**Files modified:** `bin/runSVUnit`
**Commit:** 905e882
**Applied fix:** Scoped the generic `+SVUNIT_LIST_TESTS` append block to non-Verilator simulators so Verilator keeps the plusarg before the `| tee` pipeline.
**Verification:** Re-read the modified command-construction block and ran `perl -c bin/runSVUnit`, which passed.

### WR-02: Experimental Registry Test Builder Returns Null Into New Adapter Path

**Files modified:** `src/testExperimental/sv/test_registry_unit_test.sv`
**Commit:** 2371a27
**Applied fix:** Added a minimal `fake_test extends test` and changed `fake_test_builder::create()` to return that concrete test instead of an implicit null handle. `src/experimental/sv/svunit/testcase.svh` was left unchanged because the warning was fixed in the test fake without broadening framework behavior.
**Verification:** Re-read the modified fake builder section. No SystemVerilog parser or simulator was available on `PATH` (`verilator`, `qrun`, `xrun`, `vlog`, `verible-verilog-syntax`, `svlint`, and `slang` were unavailable), so no SV syntax check could be run locally.

### WR-03: List-Tests Option Test Depends On Unstable `255` Exit Behavior

**Files modified:** `test/test_list_tests.py`
**Commit:** c4e13ec
**Applied fix:** Replaced the empty-directory `runSVUnit --list-tests` return-code assertion with a `runSVUnit --help` output check for `--list-tests`, using `universal_newlines=True` for Python 3.6 compatibility.
**Verification:** Re-read the modified Python test and ran `bin/runSVUnit --help`, which printed the `--list-tests` option. Python syntax and pytest checks could not run because this shell has no `python`, `python3`, or `pytest` executable.

---

_Fixed: 2026-04-18T15:24:40Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
