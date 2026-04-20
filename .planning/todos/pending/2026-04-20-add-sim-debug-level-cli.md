---
created: 2026-04-20T09:29:32Z
title: Add sim debug level CLI
area: tooling
files:
  - bin/runSVUnit:65
  - bin/runSVUnit:448
  - scripts/certify.sh:43
  - test/test_frmwrk.py
  - docs/source/running_unit_tests.rst
  - README.md
---

## Problem

`runSVUnit` exposes backend pass-through options (`-c_arg`, `-e_arg`, and `-r_arg`) but does not provide a normalized simulator debug policy. The current xsim path hard-codes `xelab --debug all`, which was useful while porting Vivado support but forces maximum xelab debug cost for every xsim run.

The desired user-facing option is `--sim-debug-level`, not `-d`, because `-d` / `--define` is already the macro-define option and must remain backward compatible.

## Solution

Add a first-class `--sim-debug-level none|low|medium|med|high|all` option to `bin/runSVUnit`, with an environment equivalent for flake/certifier usage. Preserve expert override through existing `-c_arg`, `-e_arg`, and `-r_arg` options.

Implementation steps:

1. Add common CLI plumbing in `bin/runSVUnit`.
   - Parse `--sim-debug-level <level>`.
   - Accept `SVUNIT_SIM_DEBUG_LEVEL` for pytest/certifier-wide defaults.
   - Normalize `med` to `medium`.
   - Reject unknown levels with `CMDLINE_USAGE_ERROR`.
   - Document that `-d` remains `--define` and is not debug level.

2. Add xsim mapping first, because its Vivado `xelab --debug` choices are known.
   - `none` -> `xelab --debug off`
   - `low` -> `xelab --debug line`
   - `medium` / `med` -> `xelab --debug typical`
   - `high` / `all` -> `xelab --debug all`
   - Replace the hard-coded `xelab --debug all` while preserving `--relax --override_timeunit --timescale 1ns/1ps`.
   - If `@elabargs` already contains an explicit `--debug` or `-debug`, print a warning and let the explicit `-e_arg` value win.

3. Add warning behavior for unmapped simulator targets.
   - For `qrun`, `modelsim` / `questa`, `riviera`, `xrun` / `irun`, `vcs`, `dsim`, and `verilator`, initially warn that `--sim-debug-level` is not mapped for that simulator and no debug flags were added.
   - Keep the run non-fatal unless the implementation later adds a strict mode.
   - Do not invent backend flags without evidence from the target tool's current documentation or local verification.

4. Research and add simulator-specific mappings in small follow-up commits.
   - `qrun`: verify whether Questa qrun accepts a debug/access option in compile, optimize, or simulate phases, and decide whether mapping belongs in compile args, elab args, runtime args, or split commands.
   - `modelsim` / `questa`: verify vlog/vopt/vsim debug/access flags and how they interact with the current `-voptargs="@elabargs"` path.
   - `riviera`: verify Aldec compile/elab/runtime debug flags separately from ModelSim assumptions.
   - `xrun` / `irun`: verify Cadence debug/access switches and whether they belong in the single-step command or phase-specific args.
   - `vcs`: verify compile/elab/runtime debug flags, especially whether `-debug_access` or equivalent is appropriate for each level.
   - `dsim`: verify DSim debug/visibility flags and UVM interaction.
   - `verilator`: decide whether `--sim-debug-level` should map to generated C++ debug flags, tracing, assertions, or remain warning-only.

5. Wire certifier and docs.
   - Add `--sim-debug-level` to `scripts/certify.sh` and pass it to pytest through `SVUNIT_SIM_DEBUG_LEVEL`.
   - Record selected debug level in qualification metadata if the build-info schema is already being extended nearby.
   - Update README and `docs/source/running_unit_tests.rst`.

6. Add focused regression coverage.
   - xsim fake-tool test: default emits the compatibility debug level, `--sim-debug-level none` emits `--debug off`, `medium` emits `--debug typical`, `all` emits `--debug all`.
   - override test: explicit `-e_arg "--debug off"` suppresses/wins over `--sim-debug-level all` and prints a warning.
   - unmapped simulator test: `--sim-debug-level medium` with an unmapped simulator prints the warning and does not add guessed flags.
