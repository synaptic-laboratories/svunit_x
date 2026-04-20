# Phase 4 Context: Xilinx Vivado xsim Integration

## Resumption Context

Phase 4 started from a discuss checkpoint on 2026-04-19. The first completed
decision area established the Vivado target contract:

- Use the current working Vivado flake profile: `synth-sim-full`.
- Name the SVUnit target with version and profile in the same style as existing
  registry targets: `vivado-2025-2-1-synth-sim-full-xsim`.
- Hard-gate the target on `xilinx-vivado.lib.x86_64-linux.isStub == false`.
- Consume the Vivado package through the SVUnit certify wrapper inputs rather
  than nesting `nix develop` inside `scripts/certify.sh`.

## Test Strategy Decision

There are two checks to run now, and a third check to add later when the Vivado
container path exists:

1. **Vivado flake/package smoke** — a direct `vivado`, `xvlog`, `xelab`, `xsim`
   smoke with a temporary `HOME` and a tiny Verilog design. This proves the
   `g_xilinx_vivado/r_src_v2025_1` `synth-sim-full` package and FHS wrappers are
   usable from the SVUnit certifier closure.
2. **SVUnit xsim regression** — the normal SVUnit pytest suite filtered to
   `xsim`, now in both per-fixture and compile-once modes. This proves this
   fork's `runSVUnit -s xsim` behavior still works with the Vivado package.
3. **Future Vivado container SVUnit regression** — a later execution shape once
   the Xilinx flake exposes a container image. This should be added as a distinct
   target/evidence layer, not used to replace the native `buildFHSEnv` target.

The Phase 4 implementation should therefore do both current checks in
`nix run .#svunit-certify-vivado-2025-2-1-synth-sim-full-xsim`.

## Initial Evidence

On 2026-04-19, the native Vivado target passed a full xsim certify run against
the local dirty Vivado flake input:

- Command: `nix run .#svunit-certify-vivado-2025-2-1-synth-sim-full-xsim -- --output-dir /tmp/svunit-vivado-xsim-full`
- Output: `/tmp/svunit-vivado-xsim-full`
- Result: `PASS` — 46 passed, 0 failed, 0 errors, 6 skipped, 64 deselected.
- Tool smoke: direct `vivado`, `xvlog`, `xvhdl`, `xelab`, and `xsim` path checks plus `xvlog -> xelab -> xsim` Verilog flow passed before pytest.
- Pytest filter: `xsim`.

## Final Evidence

On 2026-04-19, Phase 4 produced the final two-mode all-six sign-off session
`20260419-155633-5ca6b545` under the qualified artefacts root:

- Manifest: `04-sign-off-manifest.tsv`
- Sign-off record: `04-sign-off.md`
- Performance summary: `04-performance-summary.tsv`
- Result: all six targets PASS, including Vivado xsim with 47 passed, 0 failed,
  0 errors, and 6 skipped, split as per-fixture 46 passed / 6 skipped and
  compile-once 1 passed / 0 skipped.

The final Vivado row includes direct package smoke, SVUnit `pytest -k xsim` in
both regression modes, and `vivado-tool-timing/tool-invocations.tsv` evidence.
The timing evidence shows repeated `xvlog`/`xelab`/`xsim` invocations dominate
runtime; this is not evidence of Xilinx flake self-tests running for every
pytest case.
