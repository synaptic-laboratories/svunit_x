# Phase 04 Sign-Off Record

**Phase:** 04-xilinx-vivado-xsim-integration
**Signed off:** 2026-04-19T16:15:02Z
**Source under test:** `7a1db7ddda58f91cde0da550490aeccf8f26e99f` plus the dirty Phase 4/5 working-tree diff listed in this phase.
**Upstream target:** v3.38.1 peeled at `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`.
**Artefacts root:** `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/`
**Manifest:** [`04-sign-off-manifest.tsv`](04-sign-off-manifest.tsv)
**Performance summary:** [`04-performance-summary.tsv`](04-performance-summary.tsv)
**Session stamp:** `20260419-155633-5ca6b545`

## Pass Matrix

| Target | Status | Total passed | Skipped | Per-fixture | Compile-once | pytest filter | Run ID | Evidence |
|---|---:|---:|---:|---:|---:|---|---|---|
| quartus-23-4-qrun | PASS | 49 | 3 | 48 passed / 3 skipped | 1 passed / 0 skipped | `qrun and not uvm_simple_model` | `20260419-1601--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--quartus-23-4-qrun/build-info.json` |
| quartus-23-4-modelsim | PASS | 47 | 3 | 46 passed / 3 skipped | 1 passed / 0 skipped | `modelsim and not uvm_simple_model` | `20260419-1602--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--quartus-23-4-modelsim/build-info.json` |
| quartus-25-1-sim-only-qrun | PASS | 49 | 3 | 48 passed / 3 skipped | 1 passed / 0 skipped | `qrun and not uvm_simple_model` | `20260419-1603--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--quartus-25-1-sim-only-qrun/build-info.json` |
| quartus-25-1-sim-only-modelsim | PASS | 47 | 3 | 46 passed / 3 skipped | 1 passed / 0 skipped | `modelsim and not uvm_simple_model` | `20260419-1605--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--quartus-25-1-sim-only-modelsim/build-info.json` |
| verilator-5-044 | PASS | 48 | 9 | 47 passed / 9 skipped | 1 passed / 0 skipped | `verilator` | `20260419-1606--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--verilator-5-044/build-info.json` |
| vivado-2025-2-1-synth-sim-full-xsim | PASS | 47 | 6 | 46 passed / 6 skipped | 1 passed / 0 skipped | `xsim` | `20260419-1608--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` | `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/20260419-155633-5ca6b545--vivado-2025-2-1-synth-sim-full-xsim/build-info.json` |

Reviewer verification:

```bash
bash .planning/phases/04-xilinx-vivado-xsim-integration/04-reproduce.sh --reuse-session 20260419-155633-5ca6b545
```

That validation regenerates the manifest and performance summary from the existing evidence directories, verifies every `build-info.json` has `qualification_status == "PASS"`, checks zero failures/errors and nonzero passes for both per-fixture and compile-once modes, and checks the Vivado smoke logs.

## Vivado Coverage

The Vivado target performs two checks in one certify run:

1. Direct package smoke: `vivado`, `xvlog`, `xvhdl`, `xelab`, and `xsim` must be present in the wrapper closure. The run then executes a tiny `xvlog -> xelab -> xsim` Verilog flow in `vivado-smoke/` with a temporary `HOME`.
2. SVUnit xsim regression: the normal pytest suite runs with `-k xsim` in per-fixture mode and compile-once mode, proving this fork's retained `runSVUnit -s xsim` behavior against Vivado 2025.2.1.

The Vivado `build-info.json` records:

- `vivado_version = 2025.2.1`
- `vivado_profile = synth-sim-full`
- `vivado_is_stub = false`
- `vivado_qualified_root = /srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_xilinx_vivado/r_src_v2025_1`

The `fhs` adapter is no longer a stub. Stub Vivado inputs are refused before artefacts are created.

## Performance

Timing comes from each target's `timing-summary.json` and `timing-summary-compile-once.json`, which are derived from pytest JUnit XML. They measure pytest suite time for each target's filtered test set, not total `nix run` elapsed time and not container bootstrap time.

| Target | Per-fixture tests | Per-fixture wall time | Compile-once tests | Compile-once wall time | Vivado wall / target wall |
|---|---:|---:|---:|---:|---:|
| quartus-23-4-qrun | 51 | 42.173s | 1 | 0.874s | 5.905x |
| quartus-23-4-modelsim | 49 | 43.403s | 1 | 0.887s | 5.738x |
| quartus-25-1-sim-only-qrun | 51 | 58.983s | 1 | 1.220s | 4.222x |
| quartus-25-1-sim-only-modelsim | 49 | 59.896s | 1 | 1.269s | 4.158x |
| verilator-5-044 | 56 | 127.249s | 1 | 3.483s | 1.957x |
| vivado-2025-2-1-synth-sim-full-xsim | 52 | 249.045s | 1 | 5.143s | 1.000x |

In this run, Vivado xsim is slower, not faster: about 5.7-5.9x slower than Quartus 23.4 qrun/modelsim, 4.2x slower than Quartus 25.1 qrun/modelsim, and 2.0x slower than Verilator for the target-filtered per-fixture pytest suites. The test counts are not identical across targets, so use this as qualification-run performance telemetry rather than a strict microbenchmark.

### Vivado Tool Breakdown

The Vivado evidence directory also contains `vivado-tool-timing/tool-invocations.tsv`, written by transparent wrappers around the FHS-wrapped Vivado tools. These timings include `buildFHSEnv`/bubblewrap startup plus the underlying Vivado process runtime.

| Tool | Invocations | Total | Avg / invocation | Share | Max |
|---|---:|---:|---:|---:|---:|
| xsim | 49 | 129.463s | 2.642s | 50.1% | 2.744s |
| xelab | 49 | 83.794s | 1.710s | 32.4% | 7.349s |
| xvlog | 49 | 40.757s | 0.832s | 15.8% | 0.946s |
| vivado | 1 | 3.594s | 3.594s | 1.4% | 3.594s |
| xvhdl | 1 | 0.921s | 0.921s | 0.4% | 0.921s |

This points to repeated compile/elaborate/simulate flows inside pytest, not Xilinx flake self-tests or repeated package generation. The Nix flake contributes already-built tools on `PATH`; pytest then invokes fresh `xvlog`, `xelab`, and `xsim` processes in fresh fixture directories.

## Requirement Coverage

- **XFLK-01:** Satisfied. Vivado xsim is exposed as `nix run .#svunit-certify-vivado-2025-2-1-synth-sim-full-xsim`, and Phase 4 reran all six registered targets into session `20260419-155633-5ca6b545`.
- **XFLK-02:** Satisfied. The `fhs` adapter is implemented, pass criteria are jq-verified through `04-reproduce.sh`, and the consolidated six-target manifest includes per-fixture and compile-once result columns plus the Vivado row with Vivado metadata.

## Remaining Gaps

- Closed after sign-off: the repo flake now points the Vivado input at the pushed qualified `git+ssh://.../g_xilinx_vivado/r_src_v2025_1` repository and locks revision `83072bfe622493a11eb713afd01ba952412ee7f3`. The evidence directories record the qualified root used during the signed run.
- The direct Vivado flake input currently expands `flake.lock` substantially because it brings the Vivado flake's full transitive qualified-dev-tool graph. The lock is valid for the current implementation, but a future consumer-facing Vivado flake or source-only package adapter should reduce this.
- The future Vivado container path is not implemented in the Xilinx flake yet. When it exists, add it as a distinct target and evidence layer rather than replacing this native `buildFHSEnv` target.
- After sign-off, an opt-in xsim reuse/cache experiment was added through `runSVUnit -s xsim --xsim-reuse-build`, `SVUNIT_XSIM_REUSE_BUILD=1`, and the certify app's `--xsim-reuse-build` switch. A targeted real Vivado run passed at `/tmp/svunit-vivado-xsim-reuse-targeted-2`, showing repeated filter invocations skip `xvlog`/`xelab` after the first cache miss. This remains outside the deterministic sign-off path until a full-suite reuse benchmark is separately accepted.
