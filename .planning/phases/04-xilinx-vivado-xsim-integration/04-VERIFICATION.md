# Phase 04 Verification

## Result

PASS. Phase 4 requirements XFLK-01 and XFLK-02 are satisfied by the two-mode, six-target sign-off session `20260419-155633-5ca6b545`.

## Checks

| Check | Evidence | Result |
|---|---|---|
| Vivado target exposed as a Nix app | `nix eval --raw .#apps.x86_64-linux.svunit-certify-vivado-2025-2-1-synth-sim-full-xsim.program` during `04-reproduce.sh` preflight | PASS |
| Aggregate wrapper includes all six targets | `04-reproduce.sh` builds `.#svunit-certify-all` and greps every expected `Target:` header | PASS |
| All six targets pass on current Phase 4 tree | [`04-sign-off-manifest.tsv`](04-sign-off-manifest.tsv): all rows PASS with zero failures/errors in per-fixture and compile-once modes | PASS |
| Vivado `fhs` adapter runs real tool smoke | `vivado-smoke/vivado-version.log`, `xvlog-smoke.log`, `xelab-smoke.log`, `xsim-smoke.log` under the Vivado evidence dir | PASS |
| Vivado xsim SVUnit regression passes | Vivado row in [`04-sign-off-manifest.tsv`](04-sign-off-manifest.tsv): 47 passed, 0 failed, 0 errors, 6 skipped; per-fixture 46 passed / 6 skipped; compile-once 1 passed / 0 skipped | PASS |
| Performance telemetry exists | [`04-performance-summary.tsv`](04-performance-summary.tsv) | PASS |
| Vivado per-tool timing exists | `vivado-tool-timing/tool-invocations.tsv` under the Vivado evidence dir; `04-reproduce.sh --reuse-session 20260419-155633-5ca6b545` validates `xvlog`, `xelab`, and `xsim` entries | PASS |

## Caveats

- Evidence was produced from a dirty working tree on top of `7a1db7ddda58f91cde0da550490aeccf8f26e99f`; the dirty diff is the Phase 4 implementation itself.
- Timing telemetry is pytest/JUnit wall time for each target's filtered per-fixture and compile-once test sets. It is not total certifier elapsed time.
- Vivado per-tool timing includes FHS wrapper startup and the underlying tool process runtime, but it does not yet separate wrapper startup from Vivado internal compile/elaboration/simulation phases.
- Post-verification closure: the Vivado input now uses the pushed qualified `git+ssh://` repository in `flake.nix`/`flake.lock`.
- The future Vivado container target remains deferred because the Xilinx flake does not expose that container path yet.
