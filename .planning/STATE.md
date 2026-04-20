---
gsd_state_version: 1.0
milestone: v3.38.1
milestone_name: milestone
status: complete
stopped_at: "Two-mode certifier evidence refresh completed after fast Verilator and full six-target PASS"
last_updated: "2026-04-20T10:24:53Z"
last_activity: 2026-04-20
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 11
  completed_plans: 11
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-19)

**Core value:** Bring upstream SVUnit changes into this fork without regressing the fork's Xilinx/Vivado-specific behavior, using Quartus-based verification plus Xilinx Vivado xsim as the sign-off boundary for this stage.
**Current focus:** v3.38.1 catch-up milestone complete after two-mode certify evidence refresh

## Current Position

Phase: 5
Plan: Complete
Status: Complete — milestone handoff and two-mode certifier evidence refresh are complete
Last activity: 2026-04-20

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 11
- Average duration: 6m 12s (excluding checkpointed plan)
- Total execution time: 31m 00s (excluding checkpointed plan)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | - | - |
| 2 | 3 | - | - |
| 3 | 2 | - | - |
| 4 | 1 | - | - |
| 5 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: 03 P01, 03 P02, 04 P01, 05 P01, 05 P02
- Trend: Stable

| Phase 01-fork-delta-baseline-intent-record P01 | 4m41s | 3 tasks | 6 files |
| Phase 01-fork-delta-baseline-intent-record P02 | 8m33s | 3 tasks | 6 files |
| Phase 01-fork-delta-baseline-intent-record P03 | checkpointed | 3 tasks | 3 files |
| Phase 02 P01 | 5m 15s | 3 tasks | 5 files |
| Phase 02 P02 | 9m 37s | 3 tasks | 13 files |
| Phase 02 P03 | 2m 53s | 3 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Phase 1: Document the fork-specific Xilinx/Vivado delta and classify divergences before any upstream merge work.
- Phase 2: Use git history plus recorded change intent for non-trivial upstream conflict resolution.
- Phase 3: Use Quartus-based regression as the sign-off gate; the Xilinx flake remains future work.
- [Phase 01-fork-delta-baseline-intent-record]: Use https://github.com/svunit/svunit.git as the authoritative upstream and pin the exact tag object and peeled commit in repo artifacts.
- [Phase 01-fork-delta-baseline-intent-record]: Treat the remembered v3.37.0 baseline mismatch and candidate-marker first-parent mismatch as human-review while allowing later phases to rely on the pinned target and merge-base.
- [Phase 01-fork-delta-baseline-intent-record]: Split 8e7d8d35e68a2deb0923871de998b13782f5f5ec only along clean subsystem threads, and keep c2cb87111cf93cbf0f3f485730d314dbad3cb858 separate because range-diff identifies a direct upstream counterpart.
- [Phase 01-fork-delta-baseline-intent-record]: Treat stable-runtime and experimental parser-compatibility edits as rewrite candidates, keep helper-library parser fixes as local until proven unnecessary, and leave the suspicious test/utils.py simulator edit as human-review.
- [Phase 01-fork-delta-baseline-intent-record]: Keep the remembered baseline mismatch and candidate-marker semantic split explicit in the Phase 2 handoff instead of collapsing them into one narrative. — Phase 2 needs exact unresolved ancestry context, not a simplified story that hides disagreement.
- [Phase 01-fork-delta-baseline-intent-record]: Require unresolved xsim-behavior and host-side simulator-discovery questions to carry safe defaults before upstream integration starts. — Phase 2 can proceed only if unresolved local behavior stays explicit and does not get replayed blindly.
- [Phase 02]: Freeze the clean pre-merge branch head in a dedicated local anchor before any upstream merge attempt.
- [Phase 02]: Seed one decision ledger with all LCU and inherited HR rows so Phase 2 conflict resolution stays tied to Phase 1 intent.
- [Phase 02]: Keep the upstream CLI and experimental layout as the baseline, then carry forward only the narrow xsim and parser-safe differences that still have local justification.
- [Phase 02]: Treat test/utils.py as a justified replacement rather than pretending the original fork hunk was valid Python.
- [Phase 02]: Keep unresolved ancestry wording and xsim/parser-sensitive residuals as explicit Phase 3 inputs instead of forcing them closed during Phase 2.
- [Phase 02]: Use the integrated summary plus human-review handoff as the Quartus sign-off entry point, not the raw merge diff.
- Phase 3 (2026-04-18): All 5 registered certify targets PASS; sign-off green; Questa 2025.1 SALT licensing fix landed as `292a8a0`.
- Roadmap amendment (2026-04-18): Phase 4 inserted as **Xilinx Vivado xsim Integration** (whole-number renumbering). XFLK-01/XFLK-02 promoted from v2 deferred to v1 active. Maintainer Documentation & Handoff renumbered Phase 4 → Phase 5. Rationale: Phase 3 confirmed the certify tooling surface is ready to absorb a Vivado-xsim target, and the docs phase should describe the final post-Xilinx state rather than retroactively revising.
- Phase 4 implementation spike (2026-04-19): `vivado-2025-2-1-synth-sim-full-xsim` wired as an `fhs` certify target using the Vivado `synth-sim-full` package input. Full `/tmp` evidence run passed: direct Vivado smoke plus pytest `-k xsim` with 46 passed / 6 skipped / 0 failed.
- Phase 4 sign-off (2026-04-19): final two-mode all-six session `20260419-155633-5ca6b545` PASS. Vivado xsim row: 47 passed / 6 skipped / 0 failed / 0 errors, split as per-fixture 46 passed / 6 skipped and compile-once 1 passed / 0 skipped. Per-tool timing shows 49 `xsim` invocations totaling 129.463s, 49 `xelab` invocations totaling 83.794s, and 49 `xvlog` invocations totaling 40.757s; runtime is repeated compile/elaborate/simulate flow, not Xilinx flake self-tests.
- Phase 5 handoff (2026-04-19): README and `docs/source/maintainer_handoff.rst` now state the final two-mode six-target sign-off boundary, point to the Phase 1/2 review trail and Phase 3/4 sign-off records, and separate future-work dimensions from the current milestone.
- Flake input closure (2026-04-19): `quartus-podman-25-1` and `xilinx-vivado` now use pushed `git+ssh` qualified repositories in `flake.nix`/`flake.lock` instead of local `git+file` inputs.
- Two-mode certifier update (2026-04-19): each certify target now runs both the existing per-fixture regression and a compile-once multi-fixture regression for profiling and local-development coverage. Fast Verilator validation passed in `/tmp/svunit-verilator-profile-test`, and the full six-target session `20260419-155633-5ca6b545` passed with compile-once green on every target.
- xsim debug-level and false-success hardening (2026-04-20): `runSVUnit` now has `--sim-debug-level` / `SVUNIT_SIM_DEBUG_LEVEL` with a Vivado xsim `xelab --debug` mapping. A/B certifier runs showed `--debug all` modestly increases wall time but does not explain the `xsimk -simmode gui -wdb -socket` kernel launch shape. xsim runs now fail if `run.log` contains Vivado false-success patterns (`ERROR: unexpected exception when evaluating tcl command` or `ERROR: [Simtcl ...] Simulation engine failed to start`), and xsim `-r_arg -nolog` / `--r_arg --nolog` is rejected because it disables the log surface needed for that guard. Post-fix Vivado xsim certifier run `20260420-1028--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` passed with 53 passed / 6 skipped / 0 failed / 0 errors.
- Certifier timing instrumentation (2026-04-20): tool timing wrappers now append end timestamps, epoch millisecond bounds, and wrapper pids to `tool-invocations.tsv`, while preserving the leading columns used by earlier analysis. Certifier runs also write `tool-summary.tsv` and `tool-by-cwd.tsv` so xsim/xelab/xvlog totals can be inspected without ad hoc aggregation.
- xsim reuse-build measurement (2026-04-20): instrumented Vivado run `20260420-1044--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` with `--xsim-reuse-build --sim-debug-level none` passed with 53 passed / 6 skipped / 0 failed / 0 errors. Per-fixture wall time improved from `240.956s` to `232.568s`, but `xsim` still ran 47 times; reuse only reduced per-fixture `xvlog`/`xelab` invocations from 47 to 43 because pytest fixture isolation creates separate workspaces.
- xsim/runtime stats and cross-simulator probe (2026-04-20): `runSVUnit` now accepts `--sim-runtime-stats` / `SVUNIT_SIM_RUNTIME_STATS=1`, mapped conservatively to xsim `-stats`, ModelSim/Questa `-printsimstats`, qrun `-stats=all`, and Verilator `--stats`, with warnings for unmapped simulators. Certifier runs retain pytest workspaces and parse supported simulator stats into `sim-runtime-stats.tsv/json`: xsim simulation CPU/memory, ModelSim `vsim` memory plus sim/total CPU/wall time, qrun `vlog`/`vopt`/`vsim` phase stats, and Verilator generated-model CPU/wall/memory from the normal simulation report. Full stats certifiers passed for Vivado xsim (`/tmp/svunit-vivado-xsim-full-stats-20260420-rerun`, 58 passed / 6 skipped, 43 entries), ModelSim (`/tmp/svunit-modelsim-full-stats-20260420`, 49 passed / 3 skipped, 44 entries), qrun (`/tmp/svunit-qrun-full-stats-20260420`, 51 passed / 3 skipped, 130 entries), and Verilator (`/tmp/svunit-verilator-full-stats-20260420`, 50 passed / 9 skipped, 37 entries). Focused probes and full-run comparisons show xsim/qrun/ModelSim wrapper time is much larger than simulator-reported short-test execution time, while Verilator generated-model execution rounds to `0.000s` and compile/build dominates. `runSVUnit -s xsim --xsim-run-mode standalone` exposes the faster `xelab -standalone -R` path for unfiltered runs; probes cut APB rerun time from `4.018s` to `1.973s` and UVM simple model from `8.931s` to `7.025s`, but standalone is guarded away from SVUnit's runtime filter/list/stats arg paths; see `optimise_xsim.md`.
- ModelSim/Questa and Verilator debug-level mapping (2026-04-20): `--sim-debug-level` now maps ModelSim/Questa to documented vopt/vsim debug controls and Verilator to documented runtime-debug controls. A first live ModelSim high-debug run showed `+acc=mnprt` is rejected by Questa 2025.1 as deprecated-letter usage (`vopt-14401`); the final policy uses accepted `+access+r` / `+access+rw` instead. Corrected live acceptance run `/tmp/svunit-modelsim-debug-high-20260420-rerun` passed with 51 passed / 3 skipped.

### Roadmap Evolution

- 2026-04-18: Phase 4 (Xilinx Vivado xsim Integration) inserted after Phase 3 via whole-number renumbering. Phase 5 is the former Phase 4 (Maintainer Documentation & Handoff) renumbered, depends_on updated to Phase 4.
- 2026-04-19: Phase 5 complete. The v3.38.1 catch-up milestone is fully planned and executed.

### Pending Todos

(none)

### Blockers/Concerns

- Complex merge outcomes should stop for explicit human review instead of being forced automatically.

## Session Continuity

Last session: 2026-04-20
Stopped at: Closed both remaining todos — xilinx-thematics audit (T5 supplement appended, 46 findings, all class-C) and xsim reuse-cache (feature landed, full-suite benchmark 53/6/0/0 documented, remains opt-in outside sign-off). Zero pending todos; milestone v3.38.1 remains at 100%.
Resume file: none
Human-readable checkpoint: none
