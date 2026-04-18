# SVUnit X Upstream Catch-Up

## What This Is

This project maintains a fork of SVUnit that already carries local Xilinx/Vivado support work and related fork-specific adjustments. The current goal is to catch this fork up to upstream `svunit/svunit` changes through the user-specified `3.38.1` target, while preserving the validated local behavior that makes this fork useful on this box.

The work is not a generic feature expansion. It is a careful upstream-sync and compatibility project for maintainers who need the fork to stay close to upstream without losing the local Xilinx/Vivado handling that was added here.

## Core Value

Bring upstream SVUnit changes into this fork without regressing the fork's Xilinx/Vivado-specific behavior, using Quartus-based verification as the sign-off gate for this stage.

## Requirements

### Validated

- ✓ SVUnit provides a file-system-driven SystemVerilog unit-test framework with generated suites, runner scripts, and supporting runtime code across `bin/` and `svunit_base/` — existing
- ✓ SVUnit supports multiple simulator backends through `bin/runSVUnit`, including flows relevant to Questa/Questa Advanced Simulator, Xilinx Vivado `xsim`, Verilator, and other vendor tools — existing
- ✓ This fork already contains local Xilinx/Vivado support changes and follow-on adjustments in history, including the local line around `8e7d8d3` and subsequent edits — existing
- ✓ The repository already has regression and documentation infrastructure through `test/`, `.github/workflows/ci.yml`, `docs/`, and the mapped codebase docs in `.planning/codebase/` — existing
- ✓ Phase 1 confirmed upstream `v3.38.1` at commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`, derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`, and recorded the remembered-baseline and marker disagreements explicitly as `human-review` — validated in Phase 1
- ✓ Phase 1 produced a classified fork-delta matrix, executive summary, and blocking human-review handoff for the local Xilinx/Vivado delta — validated in Phase 1
- ✓ Synchronized fork passes the required regression flow on this machine through the certified Quartus flake (all 5 certify targets PASS: Quartus 23.4 qrun/modelsim, Quartus 25.1 sim-only qrun/modelsim, Verilator 5.044); sign-off record at `.planning/phases/03-quartus-verification-sign-off/03-sign-off.md` with explicit run-ids, gap matrix, and `## Next Sign-Off Round` guidance — validated in Phase 3

### Active

- [ ] Catch this fork up to upstream `svunit/svunit` changes against the user-specified `3.38.1` target while preserving required local behavior
- [ ] Resolve upstream-vs-fork conflicts intelligently by using git history and change intent, not just textual diffs
- [ ] Document any conflicts or merge cases that still need human judgment after history-aware reconciliation

### Out of Scope

- Creating the future Xilinx flake — deferred because this stage signs off on Quartus, not Xilinx-flake bring-up
- Large new simulator features unrelated to upstream catch-up — this stage is about sync and preservation, not broad feature expansion
- Blind rebasing or conflict resolution by text-only merge rules — rejected because local fork intent must be preserved where it still matters

## Context

This is a brownfield maintenance project on an existing SVUnit fork. The codebase map in `.planning/codebase/` shows a mature multi-simulator SystemVerilog test framework with Perl-based orchestration in `bin/`, a stable runtime in `svunit_base/`, regression tests in `test/`, and existing support paths for Vivado and other simulators.

The local history shows fork-specific work on Xilinx/Vivado support, including a local milestone commit `8e7d8d3` (`Improved Xilinx Vivado Simulator Support complete.`) and later small follow-on changes. Some of those edits are likely semantic and some are likely formatting, argument-surface, or compatibility cleanups. The project should treat those as maintainable intent that must be classified during the sync, not as noise to discard automatically.

The user described the desired method clearly: use git history to understand what changed for Xilinx support, infer why those changes were made, and use that intent to merge upstream carefully. Complex corrections are expected to require explicit human review instead of forcing a brittle automated choice.

The execution environment for this stage is also constrained: the Xilinx flake is still in progress, so sign-off for this round should happen on this machine using the certified Quartus flake. That makes Quartus-based regression the practical acceptance gate even though the fork must continue to preserve its Xilinx/Vivado-specific behavior.

Phase 1 completed that verification step. The upstream target is now pinned to `https://github.com/svunit/svunit.git` tag `v3.38.1`, peeled commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`, with derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`. Phase 1 also preserved two deliberate review boundaries for later work: the remembered `v3.37.0` baseline does not equal the derived merge-base, and the candidate marker only resolves cleanly under one ancestry interpretation. Those disagreements are recorded as `human-review`, not unresolved execution blockers.

Phase 3 closed the sign-off gate. All 5 registered certify targets (Quartus 23.4 qrun/modelsim, Quartus 25.1 sim-only qrun/modelsim, Verilator 5.044) pass the regression suite on this machine. The consolidated sign-off record cites explicit run-ids, enumerates carried-forward residuals (HR-01, HR-02, LCU-01, LCU-03, LCU-04, HR-03, HR-04), and flags forward-looking concerns (flake-pin drift, UVM `svverification` license gate, Xilinx xsim flake XFLK-01). The Phase 3 work surfaced and fixed a Questa 2025.1 SALT licensing migration (`SALT_LICENSE_SERVER` replaces `LM_LICENSE_FILE`) in `scripts/certify.sh` and added a reproducibility script at `.planning/phases/03-quartus-verification-sign-off/03-reproduce.sh`.

## Constraints

- **Compatibility**: Preserve validated Xilinx/Vivado-specific behavior in the fork — that local value is the reason the fork exists
- **Verification**: Quartus is the sign-off environment for this stage — the Xilinx flake is not ready yet
- **Workflow**: Sync decisions must be informed by git history and documented intent — text-only merging is insufficient for this repo
- **Scope**: This stage is an upstream catch-up, not a broad redesign of SVUnit internals — keep divergence minimal unless local behavior requires it
- **Review**: Complex merge outcomes may require human checking — do not force unclear resolutions just to keep momentum

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat this as a brownfield upstream-sync project | The repo already exists, already works, and already carries local fork-specific behavior | ✓ Good |
| Make the local Xilinx/Vivado delta an explicit early analysis phase | Conflict resolution will be safer if local change intent is documented before upstream sync begins | ✓ Good |
| Use Quartus-based regression as the stage sign-off gate | The certified Quartus flake is available now, while the Xilinx flake is still future work | ✓ Good |
| Preserve local Xilinx/Vivado behavior where still needed, while minimizing unnecessary divergence from upstream | The fork should stay maintainable, but not at the cost of losing its local purpose | — Pending |
| Re-confirm the exact upstream `3.38.1` reference before execution | Phase 1 pinned the upstream tag object, peeled commit, and derived merge-base in repo artifacts | ✓ Good |
| Keep ancestry disagreement and unresolved Xilinx intent explicit for Phase 2 | Phase 1 found real ambiguity that should guide merge work, not be hidden by simplification | ✓ Good |
| Phase 3 sign-off requires all 5 registered certify targets PASS (D-01) | The project's verification contract names the current registered target set as the required coverage — fewer targets weakens the contract, more targets re-opens discussion | ✓ Good |
| Phase 3 uses unique per-target `--output-dir` rather than `svunit-certify-all` shared-root snapshot | Review-pass feedback (Codex+OpenCode) flagged `comm -13 BEFORE AFTER` as racy with concurrent writers; explicit per-target paths eliminate the collision class | ✓ Good |
| Phase 3 introduced `SALT_LICENSE_SERVER` alongside `LM_LICENSE_FILE` for Questa | Questa 2025.1 migrated to SALT licensing; older 2023.3 still reads LM. Setting both lets one container run cleanly with either Questa version — each ignores the variable it doesn't recognize | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-18 after Phase 3 completion*
