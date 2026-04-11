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

### Active

- [ ] Identify the fork-specific delta from upstream and document the intent of each local Xilinx/Vivado-related change before applying upstream sync work
- [ ] Catch this fork up to upstream `svunit/svunit` changes against the user-specified `3.38.1` target while preserving required local behavior
- [ ] Resolve upstream-vs-fork conflicts intelligently by using git history and change intent, not just textual diffs
- [ ] Verify that the synchronized fork still passes the required regression flow on this machine using the certified Quartus flake as the sign-off environment for this stage
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

The upstream target needs one careful verification step during execution. The user specified upstream `https://github.com/svunit/svunit` release `3.38.1`, but the official GitHub releases page I checked before writing this file visibly listed `3.38.0` and did not clearly show `3.38.1`. That means the exact upstream tag/commit should be re-confirmed before the synchronization phase begins.

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
| Re-confirm the exact upstream `3.38.1` reference before execution | The user named `3.38.1`, but the official release page I checked did not clearly confirm it | — Pending |

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
*Last updated: 2026-04-11 after initialization*
