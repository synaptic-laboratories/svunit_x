---
status: awaiting_human_verify
trigger: "quartus-25-1-sim-only pytest subprocess failure during Phase 3 sign-off regression (run-id 20260418-094233-c0c1a4ce)"
created: 2026-04-18T00:00:00Z
updated: 2026-04-18T12:45:00Z
---

## Current Focus

hypothesis: (resolved) Two stacked bugs masked each other: (1) Perl IO::Dir missing in 25.1 sim-only image, and (2) Questa 2025.1 SALT_LICENSE_SERVER env var required (LM_LICENSE_FILE deprecated).
test: re-ran all 4 Quartus container targets against HEAD + SALT_LICENSE_SERVER patch in a scratch output dir
expecting: all 4 container targets PASS, matching the 23.4 baseline
next_action: commit the SALT_LICENSE_SERVER fix; orchestrator re-runs full .#svunit-certify-all for Phase 3 sign-off to get a single committed manifest row

## Symptoms

expected: All 5 certify targets PASS (svunit-certify-all green; each build-info.json qualification_status == PASS).

actual:
  - quartus-23-4-qrun              PASS  48 passed / 0 failed / 3 skipped
  - quartus-23-4-modelsim          PASS  46 passed / 0 failed / 3 skipped
  - quartus-25-1-sim-only-qrun     FAIL   2 passed / 46 failed / 3 skipped
  - quartus-25-1-sim-only-modelsim FAIL   2 passed / 44 failed / 3 skipped
  - verilator-5-044                PASS  47 passed / 0 failed / 9 skipped

errors: Systemic subprocess.CalledProcessError + FileNotFoundError wrapping pytest invocations on 25.1 sim-only. Pattern spans test_example, test_frmwrk, test_junit_xml, test_list_tests, test_run_script, test_sim. 2 tests per target pass — so the container starts; the shell-out chain from pytest → SVUnit runner → qrun/vsim breaks.

reproduction:
  - Full suite: bash .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh
  - Single target: nix run .#svunit-certify-quartus-25-1-sim-only-qrun
  - Artefacts root: /srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/

started: First end-to-end regression run of v3.38.1-x0.2.0 against new 25.1 sim-only flake input (commit 5599d08). 23.4 path working since Phase 2 merged.

## Eliminated

- hypothesis: H1 (missing simulator binary qrun/vsim/vlog)
  evidence: test-log.txt lines 66-68 show "OK: qrun/vlog/vsim version matches 2025.1" — all simulator binaries present and correct version
  timestamp: 2026-04-18T00:15:00Z
- hypothesis: H2 (missing Quartus env var)
  evidence: stderr shows pure Perl module error "Can't locate IO/Dir.pm in @INC" at /sll/bin/buildSVUnit line 25 — unrelated to env vars
  timestamp: 2026-04-18T00:15:00Z
- hypothesis: H3 (PATH inheritance)
  evidence: same as H1 — simulator tools resolve correctly; error is from a Perl module, not command resolution
  timestamp: 2026-04-18T00:15:00Z
- hypothesis: H4 (Questa 2025.1 arg parsing change)
  evidence: buildSVUnit never reaches the simulator — it aborts at Perl module load time (BEGIN failed at line 25)
  timestamp: 2026-04-18T00:15:00Z

## Evidence

- timestamp: 2026-04-18T00:10:00Z
  checked: qualification-results.md for 25.1-sim-only-qrun
  found: First failure block (test_example_modules_apb_slave[qrun]) shows stderr: "Can't locate IO/Dir.pm in @INC ... at /sll/bin/buildSVUnit line 25. BEGIN failed--compilation aborted at /sll/bin/buildSVUnit line 25." Every subsequent failure is the same error — 44+ tests fail identically because each one calls `runSVUnit` which invokes `buildSVUnit` which requires IO::Dir.
  implication: H5 confirmed — the 2 passing tests (test_example_uvm_uvm_express and test_mock_uvm_report_ius) are presumably tests that don't exercise buildSVUnit's IO::Dir path. The break is uniform: any test that shells out through buildSVUnit dies at Perl module load.

- timestamp: 2026-04-18T00:11:00Z
  checked: Bootstrap log (test-log.txt lines 60-61) vs current scripts/certify.sh
  found: The regression run logged "--- bootstrap: installing perl-modules (File::Find missing) --- / OK: perl-modules-5.38 installed". This matches PRIOR certify.sh behavior (commit 2d71b3e, which only installed perl-modules-5.38 for File::Find). Current HEAD certify.sh (commit 0680482 "install full perl metapackage, not just perl-modules") at lines 160-168 installs the `perl` metapackage and probes with `perl -MFile::Find -MIO::Dir -e 1`.
  implication: The regression was run against commit 2d71b3e (as build-info.json confirms: svunit_commit 2d71b3e180bb4a8ca72d81c1bb98fabc14ad76f1). The fix for IO::Dir landed 4 hours later as commit 0680482 but the regression has not been re-run since. The "fix" likely already exists in HEAD — need to verify by running the certify target against HEAD.

- timestamp: 2026-04-18T00:12:00Z
  checked: git log scripts/certify.sh
  found: HEAD has commit 0680482 "fix(certify): install full perl metapackage, not just perl-modules" with commit message: "the 25.1 sim-only container is missing not only File::Find (perl-modules-5.38) but also IO::Dir (libperl5.38t64) that bin/buildSVUnit needs. Installing the `perl` apt metapackage pulls in both deps ... Discovered during Plan 03-02 Task 2 re-run: after fixing File::Find, the next error was IO::Dir.pm missing from bin/buildSVUnit line 25."
  implication: The author already diagnosed this same root cause on 2026-04-18 13:47 UTC+4 and committed a fix. The failing regression run at timestamp 2026-04-18T09:45:27Z was against svunit_commit 2d71b3e — the state BEFORE the fix. The regression.sh script needs to be re-run against current HEAD (0680482+) to verify the fix is effective end-to-end.

- timestamp: 2026-04-18T12:28:00Z
  checked: Ran `nix run .#svunit-certify-quartus-25-1-sim-only-qrun` against HEAD a17110b (which contains the perl metapackage fix)
  found: Pass rate improved from 2/49 to 4/48 — perl fix did resolve IO::Dir failures. But 44 tests still failed. test-log.txt now shows a DIFFERENT error: `Unable to find the license file. It appears that your license file environment variable (SALT_LICENSE_SERVER) is not set correctly. Unable to checkout a license. Vsim is closing. ** Error: Invalid license environment. Application closing.` (exit code 3, not 255 — vsim-level failure, not buildSVUnit-level).
  implication: Second bug, downstream of the first. Questa 2025.1 expects SALT_LICENSE_SERVER, not LM_LICENSE_FILE. Stacked bugs: once buildSVUnit can actually run (perl fix), the next layer (vsim licensing) breaks. The 4 passing tests don't need to run vsim — they either extract simulator paths (extract_sim, extract_qrun) or parse outputs (uvm_uvm_express, uvm_report_mock_ius).

- timestamp: 2026-04-18T12:30:00Z
  checked: Web search for SALT_LICENSE_SERVER semantics (Intel FPGA docs + community)
  found: Questa 2025.1 migrated to SALT v2.4.2.0 licensing. "SALT_LICENSE_SERVER is semicolon ';' delimited by default unlike LM_LICENSE_FILE". "LM_LICENSE_FILE and MGLS_LICENSE_FILE are deprecated in this release. Future versions of Questa Intel FPGA Edition will not read them." For a single file: SALT_LICENSE_SERVER=/path/to/license.dat (no delimiter needed).
  implication: Fix is to set SALT_LICENSE_SERVER alongside existing LM_LICENSE_FILE in the podman run invocation. Keep LM_LICENSE_FILE for 23.4 (Questa 2023.3) and quartus_sh. Since only one license file per var, semicolon vs colon doesn't matter.

- timestamp: 2026-04-18T12:33:00Z
  checked: Ran `nix run .#svunit-certify-quartus-25-1-sim-only-qrun` with SALT_LICENSE_SERVER fix applied
  found: PASS 48 passed / 0 failed / 3 skipped — exactly matches 23.4 qrun baseline
  implication: Fix works for 25.1 sim-only qrun

- timestamp: 2026-04-18T12:35:00Z
  checked: Ran `nix run .#svunit-certify-quartus-25-1-sim-only-modelsim` with fix
  found: PASS 46 passed / 0 failed / 3 skipped — matches 23.4 modelsim baseline
  implication: Fix works for 25.1 sim-only modelsim

- timestamp: 2026-04-18T12:37:00Z
  checked: Ran `nix run .#svunit-certify-quartus-23-4-qrun` with fix (regression guard)
  found: PASS 48 passed / 0 failed / 3 skipped — 23.4 path unchanged
  implication: The added SALT_LICENSE_SERVER does not break Questa 2023.3 (it cleanly ignores the unknown var)

- timestamp: 2026-04-18T12:38:00Z
  checked: Ran `nix run .#svunit-certify-quartus-23-4-modelsim` with fix (regression guard)
  found: PASS 46 passed / 0 failed / 3 skipped — 23.4 modelsim path unchanged
  implication: Full regression guard passes; safe to commit

## Resolution

root_cause: TWO STACKED BUGS, one shadowing the other in the original regression run:

  (1) Perl IO::Dir missing — FIXED ALREADY at HEAD commit 0680482 (`fix(certify): install full perl metapackage, not just perl-modules`). The 25.1 sim-only image (quartus-pro-linux:25.1.1.125-sim-only) ships with `perl-base` only; SVUnit's `/sll/bin/buildSVUnit` line 25 does `use IO::Dir;` which requires the `libperl5.38t64` deb. The 23.4 image happens to have a full perl install, so 23.4 was green.

  (2) Questa 2025.1 licensing env var migration — NEW FIX in this debug session. Questa 2025.1 migrated to SALT v2.4.2.0 and reads `SALT_LICENSE_SERVER` (semicolon-delimited), not `LM_LICENSE_FILE`. The deprecated LM_LICENSE_FILE env var is ignored by Questa 2025.1's `vsim`, causing "Invalid license environment. Application closing." as soon as vsim tries to check out a license (after vlog/vopt have completed). Questa 2023.3 (in the 23.4 image) still reads LM_LICENSE_FILE, which is why 23.4 stayed green.

fix: Added `SALT_LICENSE_SERVER=/opt/questa_license.dat` alongside the existing `LM_LICENSE_FILE=...` env var in two places:
  - scripts/certify.sh podman run invocation (primary fix)
  - scripts/quartus-shell.sh interactive CONTAINER_ENV array (parity fix, so `nix run .#svunit-quartus-shell-quartus-25-1-sim-only` also works)
Both paths set both env vars unconditionally. Older Questa (2023.3) ignores SALT_LICENSE_SERVER; newer Questa (2025.1) ignores LM_LICENSE_FILE for Questa licensing (though other tools on the full 23.4 image like quartus_sh still use it). No per-version branching needed — setting both is idempotent.

verification: Ran all 4 Quartus container certify targets end-to-end against HEAD with fix applied:
  - quartus-25-1-sim-only-qrun      PASS 48/0/3 ✅ (was 2/46/3)
  - quartus-25-1-sim-only-modelsim  PASS 46/0/3 ✅ (was 2/44/3)
  - quartus-23-4-qrun               PASS 48/0/3 ✅ (regression guard, unchanged)
  - quartus-23-4-modelsim           PASS 46/0/3 ✅ (regression guard, unchanged)
  Verilator native target was already PASS 47/0/9 and was not touched by this fix, so no re-run needed.

files_changed: [scripts/certify.sh, scripts/quartus-shell.sh]
