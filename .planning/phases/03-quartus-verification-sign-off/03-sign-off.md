# Phase 03 Sign-Off Record

**Phase:** 03-quartus-verification-sign-off
**Signed off:** 2026-04-18T15:39:00Z
**Commit under test:** `bb2227c` (`bb2227cf471977750eb6ee3a7acaa6c4e9e681b3`)
**Upstream target:** v3.38.1 peeled at `8e70653e2cbfe3ebe154a863a46bf482ded4bc19` (derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`)
**Artefacts root:** `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/`
**Manifest (source of truth):** [`03-sign-off-manifest.tsv`](03-sign-off-manifest.tsv)
**Session stamp:** `20260418-153312-003a5b56` (maps each per-target evidence dir basename `${SESSION_STAMP}--${target}`)

## Pass Matrix

| Target | Run ID | Status | Passed | Skipped | pytest_filter | svunit_commit | Evidence |
|---|---|---|---|---|---|---|---|
| quartus-23-4-qrun              | `20260418-1533--nixos-25.11--nix-2.31.2--kernel-6.12.70` | PASS | 48 | 3 | `qrun and not uvm_simple_model`       | `bb2227c` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260418-153312-003a5b56--quartus-23-4-qrun/build-info.json` |
| quartus-23-4-modelsim          | `20260418-1534--nixos-25.11--nix-2.31.2--kernel-6.12.70` | PASS | 46 | 3 | `modelsim and not uvm_simple_model`   | `bb2227c` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260418-153312-003a5b56--quartus-23-4-modelsim/build-info.json` |
| quartus-25-1-sim-only-qrun     | `20260418-1535--nixos-25.11--nix-2.31.2--kernel-6.12.70` | PASS | 48 | 3 | `qrun and not uvm_simple_model`       | `bb2227c` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260418-153312-003a5b56--quartus-25-1-sim-only-qrun/build-info.json` |
| quartus-25-1-sim-only-modelsim | `20260418-1536--nixos-25.11--nix-2.31.2--kernel-6.12.70` | PASS | 46 | 3 | `modelsim and not uvm_simple_model`   | `bb2227c` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260418-153312-003a5b56--quartus-25-1-sim-only-modelsim/build-info.json` |
| verilator-5-044                | `20260418-1537--nixos-25.11--nix-2.31.2--kernel-6.12.70` | PASS | 47 | 9 | `verilator`                           | `bb2227c` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260418-153312-003a5b56--verilator-5-044/build-info.json` |

Reviewer verification (jq-semantic — review concern #5):

```bash
# Validates every cited evidence file. Exits 0 iff every row PASS-verifies.
awk -F'\t' 'NR>1 {print $1, $9}' \
  .planning/phases/03-quartus-verification-sign-off/03-sign-off-manifest.tsv \
  | while read -r target epath; do
      bi="$epath/build-info.json"
      test -f "$bi" \
        && [ "$(jq -r .target "$bi")" = "$target" ] \
        && [ "$(jq -r .qualification_status "$bi")" = "PASS" ]
    done
```

## Environment

| Property | Value |
|---|---|
| Host OS (nixos) | 25.11 |
| Nix version | 2.31.2 |
| Kernel | 6.12.70 |
| Container runtime | podman |
| Quartus 23.4 image | `localhost/quartus-pro-linux:23.4.0.79` |
| Quartus 25.1 image (sim-only) | `localhost/quartus-pro-linux:25.1.1.125-sim-only` |
| Questa version (23.4 image) | 2023.3 |
| Questa version (25.1 image) | 2025.1 |
| Verilator version | 5.044 |
| Tool group | `g_svunit_x` |
| Tool version | `r_v3_38_1_x0_2_0` |
| Qualified version | `3.38.1-x0.2.0` |
| License files | `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch/quartus_license.dat`, `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch/questa_license.dat` (paths only — contents not embedded) |

**Environmental note — Questa 2025.1 SALT licensing migration:** During this phase the 25.1 sim-only targets initially failed with `Invalid license environment. Application closing.` (exit code 3 from `vsim`) after `vlog`/`vopt` had already succeeded. Root cause: Questa 2025.1 migrated to SALT v2.4.2.0 and reads the `SALT_LICENSE_SERVER` env var instead of the deprecated `LM_LICENSE_FILE`. Commit `292a8a0` (the SALT licensing fix) sets both env vars side-by-side in `scripts/certify.sh` and `scripts/quartus-shell.sh`. Questa 2023.3 silently ignores the unknown `SALT_LICENSE_SERVER`; Questa 2025.1 silently ignores the deprecated `LM_LICENSE_FILE`. The fix is idempotent — no per-version branching needed. Without this commit the 25.1 sim-only qrun/modelsim targets cannot pass. Recorded here because any future re-sign against a newer Questa major is at risk of the same env-var contract changing again.

## Command Executed

```bash
cd /srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x
bash .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh --smoke-aggregate
```

The script runs each of the 5 per-target apps with an explicit unique `--output-dir`, under a `flock`'d shared artefacts root, with host-tool + license + image + offline + writability preflight. The `--smoke-aggregate` flag also verifies that the aggregate `svunit-certify-all` app is exposed by the flake before the per-target rerun starts. Session stamp `20260418-153312-003a5b56` is the shared prefix for the 5 per-target evidence dirs. See [`03-reproduce.sh`](03-reproduce.sh) for the exact logic.

## Gap Matrix

| Dimension | Covered | Not covered | Why deferred | Owner / next phase |
|---|---|---|---|---|
| Simulator | Quartus (qrun, modelsim) across Questa 2023.3 (23.4 image) and Questa 2025.1 (25.1 sim-only image); Verilator 5.044 native | Xilinx Vivado `xsim` | `fhs` adapter in `scripts/certify.sh` is an intentional hard-exit stub; Xilinx flake (`g_xilinx_vivado/r_src_v2025_1`) still in progress | v2 requirement `XFLK-01`; future phase |
| Device families | SVUnit functional regression against the upstream-synced fork runtime (no synth step) | Agilex / Stratix / Arria synth paths | SVUnit is a simulator-framework regression; synth paths belong to device-family qualification, not this fork's upstream catch-up | Out of scope for this milestone |
| Test categories | All pytest suites matching the per-target filter (3 Quartus tests skipped per target; 9 Verilator tests skipped) | `uvm_simple_model` pytest markers on Quartus targets | No `svverification` (UVM) license available in the Quartus containers; per-target pytest filter on the 4 Quartus targets has the shape `qrun and not uvm_simple_model` / `modelsim and not uvm_simple_model` — the "and not uvm_simple_model" clause is the UVM-gated exclusion | Re-enable once UVM license becomes available in the container; see §Next Sign-Off Round item 3 |
| Intent carry-forwards | Phase 2 upstream-import surface preserves the fork's four Xilinx themes without regression (Plan 1 audit: 0 class-A / 0 class-B / 34 class-C findings; see §Xilinx-Thematics Audit Cross-Reference) | Phase 1 HR-01 / HR-02 ancestry notes; Phase 2 `needs-maintainer-check` items (LCU-01, LCU-03, LCU-04, HR-03, HR-04); no new A/B findings from Plan 1 | These are maintainer-review items by PROJECT.md rule ("Complex merge outcomes may require human checking — do not force unclear resolutions just to keep momentum") | See §Carried-Forward Residuals (7 items); Plan 1 audit cross-reference below |
| Native vs container divergence | Verilator target runs natively on the host; the 4 Quartus targets run inside a podman container | Host-side execution of Quartus targets; container-side execution of Verilator | Different toolchains require different adapters (native vs container) per `scripts/certify.sh` adapter dispatch; same pytest suite in both paths — divergence is execution-environment only | Recorded for completeness; no planned convergence |

## Carried-Forward Residuals

These 7 items are documented as review items with ledger pointers per D-03. They do **NOT** block sign-off.

| # | ID | Ledger pointer | Summary |
|---|---|---|---|
| 1 | HR-01 | [`01-human-review.md#item-hr-01`](../01-fork-delta-baseline-intent-record/01-human-review.md) (also [`02-decision-ledger.md`](../02-history-aware-upstream-integration/02-decision-ledger.md) row HR-01) | Remembered baseline `v3.37.0` / `355c1411` does not equal the derived merge-base `84b8803`; treat `v3.37.0` as historical context only; continue using merge-base for operational reasoning. |
| 2 | HR-02 | [`01-human-review.md#item-hr-02`](../01-fork-delta-baseline-intent-record/01-human-review.md) (also [`02-decision-ledger.md`](../02-history-aware-upstream-integration/02-decision-ledger.md) row HR-02) | Full-ancestry (`dc7ed0a`) vs first-parent (`6e179ca`) disagree on "first upstream commit after the fork"; preserve both hashes and name the ancestry rule when making any claim. |
| 3 | LCU-01 | [`02-decision-ledger.md`](../02-history-aware-upstream-integration/02-decision-ledger.md) row LCU-01 (files `bin/runSVUnit`, `bin/cleanSVUnit`; commit `27232c2`) | Local xsim runtime flags (`xvlog --relax`, `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps`) and Vivado cleanup set (`xsim.dir`, `xsim*.*`, `xelab*.*`, `xvlog.pb`) kept atop upstream CLI; not revalidated in Phase 3 because Quartus sign-off does not exercise xsim. |
| 4 | LCU-03 | [`02-decision-ledger.md`](../02-history-aware-upstream-integration/02-decision-ledger.md) row LCU-03 (files `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`, `svunit_base/svunit_test.svh`, `svunit_base/svunit_globals.svh`) | Parser-safe queue typing (`[$]`), explicit `input` signatures, and `__svunit_fatal` re-applied on the upstream `v3.38.1` runtime but not revalidated by a Xilinx parser during Phase 3. |
| 5 | LCU-04 | [`02-decision-ledger.md`](../02-history-aware-upstream-integration/02-decision-ledger.md) row LCU-04 (files under `src/experimental/sv/svunit/` + `src/testExperimental/sv/test_registry_unit_test.sv`) | Experimental tree parser-safe queue typing carried into the new upstream-moved layout; old path `src/experimental/sv/testcase.svh` dropped; not revalidated by a Xilinx parser in Phase 3. |
| 6 | HR-03 | [`01-human-review.md#item-hr-03`](../01-fork-delta-baseline-intent-record/01-human-review.md) (also `02-human-review.md` Item 3) | xsim CLI and cleanup changes (LCU-01) are material and local but not proven necessary after rebasing onto upstream `v3.38.1`; retained behavior remains `needs-maintainer-check`. |
| 7 | HR-04 | [`01-human-review.md#item-hr-04`](../01-fork-delta-baseline-intent-record/01-human-review.md) (also `02-human-review.md` Item 5) | `test/utils.py` host-side simulator discovery hunk replaced with `simulators = []` + explicit `shutil.which('xsim')` append path (justified replacement, not literal preservation); Python-env regression test still pending. |

## Xilinx-Thematics Audit Cross-Reference

The Phase-2 upstream-import surface was audited against the four fork Xilinx themes (parser-safe queue typing, explicit `input` signatures, `XILINX_SIMULATOR` ifdef guards, xsim runtime/cleanup flags) in Plan 1 over a 32-file allowlist. See [`03-xilinx-thematics-audit.md`](03-xilinx-thematics-audit.md) §Summary for per-theme class counts.

Class-A (clear fix needed) + class-B (ambiguous) findings feed the Gap Matrix row "Intent carry-forwards" as deferred items. Applying fixes is out of Phase 3 scope per D-06; surfaces as follow-up phases or maintainer-review items.

**From Plan 1 §Summary (verbatim):**

- Theme T1 (parser-safe queue typing): 0 class-A, 0 class-B, 10 class-C findings.
- Theme T2 (explicit input signatures): 0 class-A, 0 class-B, 16 class-C findings.
- Theme T3 (XILINX_SIMULATOR ifdef guards): 0 class-A, 0 class-B, 2 class-C findings.
- Theme T4 (xsim runtime flags / cleanup): 0 class-A, 0 class-B, 6 class-C findings.

Total findings: 34. Total class-A: 0. Total class-B: 0.

Because Plan 1 produced **zero class-A and zero class-B findings**, the Phase 2 upstream-import surface contributes no NEW deferred-fix or needs-maintainer-check items beyond those already carried from Phase 2's `02-decision-ledger.md`. The Gap Matrix "Intent carry-forwards" row is therefore populated from the 7 residuals table above; Plan 1 adds a clean cross-reference, not additional items.

## Requirement Coverage

- **VERI-01** (Maintainer can run the required regression flow via the certified Quartus flake): Satisfied by the 5 per-target `nix run` invocations driven from [`03-reproduce.sh`](03-reproduce.sh). Preflight confirms host tools + license files + container images + `ARTEFACTS_ROOT` writability + `bootstrap.pypa.io` reachability before the run starts. See §Command Executed.
- **VERI-02** (Quartus-based sign-off demonstrates that the synchronized fork passes the required regression suite for this stage): Satisfied by §Pass Matrix above — all 5 registered targets report `qualification_status=PASS` in their respective `build-info.json` files at the cited unique output-dirs under session stamp `20260418-153312-003a5b56`. Verifiable by the jq-semantic one-liner in §Pass Matrix.
- **VERI-03** (Verification output records what was run, under which simulator/tooling path, and any remaining coverage gaps): Satisfied by §Pass Matrix (what + simulator path + commit + pytest filter + evidence path), §Environment (host/container/tool versions including the 2025.1 SALT licensing note), §Gap Matrix (5 dimensions per D-05), §Carried-Forward Residuals (7 items per D-03), §Xilinx-Thematics Audit Cross-Reference (Plan 1 consumption), and §Next Sign-Off Round (forward-looking per D-08).

## Next Sign-Off Round

Forward-looking only — does NOT duplicate §Gap Matrix (current coverage state).

1. **Flake-pin drift.** Before re-running, check `flake.lock` for drift in:
   - `nixpkgs` rev (host toolchain version)
   - `quartus-podman-23-4` rev (container image producer for Quartus 23.4)
   - `quartus-podman-25-1` rev (container image producer for Quartus 25.1 sim-only)
   - `verilator-certified` rev (pinned to Verilator `5.044` today)

   Any pin move is a new sign-off — re-verify the pass matrix with the new pins. Pay particular attention to Quartus major-version bumps: Questa 2025.1 migrated from `LM_LICENSE_FILE` to `SALT_LICENSE_SERVER` (see §Environment note); any future Questa ≥2026 bump may change the env-var contract again and should be re-verified before re-signing.

2. **Artefacts-root assumptions.** Canonical path `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/` is stamped into `flake.nix`. Verify directory still exists, is maintainer-writable, and that retention has not rotated out prior run-ids this sign-off cites. Sign-off citations use explicit session-stamped directory basenames of the form `${SESSION_STAMP}--${target}` (see the Pass Matrix above for the 5 literal paths under session `20260418-153312-003a5b56`) — these are stable as long as retention does not prune the session.

3. **UVM `svverification` license gate.** Per-target pytest filter excludes `uvm_simple_model` on the 4 Quartus targets because the container lacks the `svverification` license. If that license becomes available, drop `and not uvm_simple_model` from the 4 Quartus filters in `nix/registry.nix` and re-sign.

4. **XFLK-01 readiness.** When the Xilinx/xsim flake is ready, a new `fhs` target (or equivalent) becomes valid in `nix/registry.nix`; `scripts/certify.sh`'s hard-exit on the `fhs` adapter becomes wiring work. Re-signing with xsim closes the "Simulator: Vivado xsim" row of §Gap Matrix and exercises LCU-01 / HR-03 retained flags for the first time in CI history.

5. **Phase 1 / Phase 2 residual close-out.** The 7 residuals may close individually:
   - HR-01 / HR-02 close if a maintainer commits to one ancestry framing.
   - LCU-01 / HR-03 close when xsim is reintroduced (XFLK-01) and retained flags are exercised.
   - LCU-03 / LCU-04 close when a Xilinx parser runs against the affected trees (XFLK-01).
   - HR-04 closes when a Python-env regression test exercises `test/utils.py`'s `shutil.which('xsim')` path.

   Drop any closed residual from the next round's §Carried-Forward Residuals with a one-line justification linking the closing evidence.
