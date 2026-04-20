---
created: 2026-04-19T14:05:56Z
title: Add xsim reuse/cache mode
area: tooling
files:
  - scripts/certify.sh
  - bin/runSVUnit
  - test/test_sim.py
  - .planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off.md
---

## Problem

Phase 4 Vivado timing shows the deterministic sign-off path repeatedly runs
fresh `xvlog`, `xelab`, and `xsim` flows in pytest fixture directories. The
final sign-off session `20260419-155633-5ca6b545` recorded 49 `xsim`
invocations totaling 129.463s, 49 `xelab` invocations totaling 83.794s, and 49
`xvlog` invocations totaling 40.757s. This is correct for clean qualification,
but it is slow for iterative performance experiments.

## Solution

Add an explicit non-sign-off mode for xsim that cleans once at the start/end of
a target run and reuses Vivado build products inside a stable work directory.
Keep the current clean rebuild behavior as the default deterministic certify
path. The reuse mode should be opt-in, clearly excluded from sign-off manifests
unless separately qualified, and instrumented so compile/elaboration/simulation
cache hits are visible.

## Status

Initial implementation is in place:

- `runSVUnit -s xsim --xsim-reuse-build`
- `SVUNIT_XSIM_REUSE_BUILD=1`
- `svunit-certify-vivado-2025-2-1-synth-sim-full-xsim -- --xsim-reuse-build`

The mode hashes generated xsim filelist inputs and include directories, logs
cache hits/misses to `.svunit_xsim_reuse.log`, and preserves the deterministic
clean path by default.

Targeted real Vivado evidence:

- Command: `nix run .#svunit-certify-vivado-2025-2-1-synth-sim-full-xsim -- --output-dir /tmp/svunit-vivado-xsim-reuse-targeted-2 --filter 'xsim and (test_filter or test_filter_wildcards or test_filter_with_partial_widlcard or profile_compile_once)' --xsim-reuse-build`
- Result: PASS, 6 passed, 0 failed, 0 errors, 0 skipped.
- Cache behavior: repeated filter fixtures logged miss/hit or miss/hit/hit in `.svunit_xsim_reuse.log`.
- Tool timing: repeated filter fixtures emitted one `xvlog` and one `xelab` call, then xsim-only reruns.

Remaining work, if desired, is a full xsim reuse benchmark compared against the
clean Phase 4 evidence.

## Outcome (2026-04-20)

Closed. Feature is landed and benchmarked; no further work required inside the v3.38.1 milestone.

**Implementation (verified against HEAD):**
- `bin/runSVUnit`: `--xsim-reuse-build` flag (help at :90, option parsing at :583, env-truthy at :593, xsim-only guard at :667) and `SVUNIT_XSIM_REUSE_BUILD` env var (help at :99).
- `scripts/certify.sh`: `--xsim-reuse-build` backward-compatible alias for `--reuse-build` (:48, :58), xsim-only guard (:75-77), threaded to runSVUnit via env (:262, :884, :972), and reflected in the JSON manifest (:1181, :1186, :1204).

**Full-suite reuse benchmark (closes the "remaining work" bullet above):**
- STATE decision entry (2026-04-20) records the full-suite run `20260420-1044--host_nixos_25.11_x86_64-linux--nix-2.31.2--kernel-6.12.70` with `--xsim-reuse-build --sim-debug-level none`: PASS, 53 passed / 6 skipped / 0 failed / 0 errors.
- Per-fixture wall time improved from `240.956s` → `232.568s`. `xsim` still ran 47 times; reuse reduced per-fixture `xvlog`/`xelab` invocations from 47 → 43 only, because pytest fixture isolation creates separate workspaces. This is the structural reason reuse gains are modest on the sign-off surface.
- Additional captured evidence: `/tmp/svunit-vivado-xsim-reuse-full-20260420-1/` (run `20260420-0837`, PASS 49/0/6, `xsim_reuse_build: true` in `build-info.json`).

**Sign-off status:** `04-sign-off.md:86` records the reuse mode as opt-in and explicitly outside the deterministic sign-off path until a full-suite reuse benchmark is separately accepted. The 2026-04-20 benchmark provides that evidence, but the reuse mode remains opt-in by design — the deterministic per-fixture clean path is still the sign-off default per Phase 4 decisions.

**Follow-up (not blocking closure):** if a future milestone wants to reduce `xsim` re-invocations below 47, the structural lever is pytest fixture consolidation (compile-once already does this for a subset), not further work on the reuse cache itself.
