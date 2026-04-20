# Plan 04-01 Summary: Vivado xsim Certify Target and Six-Target Sign-Off

## Outcome

Complete. Vivado xsim is now registered as `vivado-2025-2-1-synth-sim-full-xsim`, the `fhs` adapter runs real Vivado smoke plus SVUnit xsim pytest, and the two-mode six-target Phase 4 sign-off passed.

## Evidence

- Reproduce script: [`04-reproduce.sh`](04-reproduce.sh)
- Sign-off record: [`04-sign-off.md`](04-sign-off.md)
- Six-target manifest: [`04-sign-off-manifest.tsv`](04-sign-off-manifest.tsv)
- Performance summary: [`04-performance-summary.tsv`](04-performance-summary.tsv)
- Verification report: [`04-VERIFICATION.md`](04-VERIFICATION.md)

Fresh sign-off session: `20260419-155633-5ca6b545`

Results:

- Quartus 23.4 qrun: PASS, 49 passed, 3 skipped (per-fixture 48 passed / 3 skipped; compile-once 1 passed)
- Quartus 23.4 modelsim: PASS, 47 passed, 3 skipped (per-fixture 46 passed / 3 skipped; compile-once 1 passed)
- Quartus 25.1 sim-only qrun: PASS, 49 passed, 3 skipped (per-fixture 48 passed / 3 skipped; compile-once 1 passed)
- Quartus 25.1 sim-only modelsim: PASS, 47 passed, 3 skipped (per-fixture 46 passed / 3 skipped; compile-once 1 passed)
- Verilator 5.044: PASS, 48 passed, 9 skipped (per-fixture 47 passed / 9 skipped; compile-once 1 passed)
- Vivado 2025.2.1 `synth-sim-full` xsim: PASS, 47 passed, 6 skipped (per-fixture 46 passed / 6 skipped; compile-once 1 passed)

## Performance Note

The Phase 4 timing telemetry shows Vivado xsim is slower on this target-filtered per-fixture pytest suite: 249.045s versus 42.173s for Quartus 23.4 qrun, 58.983s for Quartus 25.1 qrun, and 127.249s for Verilator. This is pytest/JUnit timing, not total `nix run` elapsed time.

Per-tool Vivado timing in the final run shows the runtime is dominated by repeated tool invocations: 49 `xsim` calls total 129.463s, 49 `xelab` calls total 83.794s, and 49 `xvlog` calls total 40.757s. This points to repeated compile/elaborate/simulate flows inside pytest rather than Xilinx flake self-tests.

## Follow-Up

- Closed after sign-off: the Vivado input now uses the pushed qualified `git+ssh://` repository in `flake.nix`/`flake.lock`.
- Reduce the Vivado lock graph when a slimmer consumer-facing qualified flake or package adapter exists.
- Add a separate Vivado container target after the Xilinx flake exposes a container image.
- Added after sign-off: an explicit non-sign-off xsim reuse/cache experiment via `runSVUnit -s xsim --xsim-reuse-build` / `SVUNIT_XSIM_REUSE_BUILD=1` and `svunit-certify-... -- --xsim-reuse-build`. A targeted real Vivado run passed at `/tmp/svunit-vivado-xsim-reuse-targeted-2`; full-suite reuse benchmarking remains separate from Phase 4 sign-off evidence.
