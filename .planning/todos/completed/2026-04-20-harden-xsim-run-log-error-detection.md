---
created: 2026-04-20T09:24:26Z
title: Harden xsim run log error detection
area: tooling
files:
  - bin/runSVUnit:448
  - test/test_run_script.py
  - test/test_frmwrk.py
---

## Problem

Vivado xsim can emit fatal startup errors in `run.log` while still returning process exit code 0. Observed patterns include `ERROR: unexpected exception when evaluating tcl command` and `ERROR: [Simtcl 6-50] Simulation engine failed to start`. That creates a false-success path for `runSVUnit -s xsim`: the Perl wrapper currently trusts the simulator process status, so pytest can treat a broken xsim invocation as passed if the command exits cleanly.

This surfaced during xsim debug/plusarg probing on 2026-04-20. It is separate from the xelab `--debug all` performance question and should be handled as correctness hardening for the xsim backend.

## Solution

Teach `bin/runSVUnit` to treat known fatal Vivado xsim log patterns as an internal execution error after xsim returns. The current guarded patterns are `ERROR: unexpected exception when evaluating tcl command` and `ERROR: [Simtcl ...] Simulation engine failed to start` in the selected simulation log file, scoped to the xsim path.

Add focused regression coverage with fake xsim tooling that writes the Vivado error text to `run.log` and exits 0. The expected behavior should be `runSVUnit -s xsim` returning `INTERNAL_EXECUTION_ERROR` instead of success. Keep the check narrow enough to avoid reclassifying ordinary SVUnit assertion failures, which are expected to appear as `ERROR:` lines in user tests.

Because the guard depends on `run.log`, reject xsim runtime args containing `-nolog` or `--nolog` with `CMDLINE_USAGE_ERROR` instead of forwarding them to Vivado.
