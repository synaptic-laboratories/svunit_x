# Roadmap: SVUnit X Upstream Catch-Up

## Overview

This roadmap treats the repo as a brownfield maintenance fork, not a greenfield product build. The work starts by freezing and explaining the fork-specific Xilinx/Vivado delta, then integrates upstream `svunit/svunit` changes against the confirmed `3.38.1` target with history-aware conflict handling, signs the result off in the certified Quartus environment, and finishes with maintainer-facing documentation that preserves the review trail for future catch-up work.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Fork Delta Baseline & Intent Record** - Confirm the upstream target and classify the fork-specific Xilinx/Vivado delta before merge work starts. (completed 2026-04-12)
- [x] **Phase 2: History-Aware Upstream Integration** - Catch the fork up to upstream while preserving required local behavior and isolating risky merge outcomes for human review. (completed 2026-04-12)
- [ ] **Phase 3: Quartus Verification & Sign-Off** - Prove the synchronized fork passes this stage's required regression flow in the certified Quartus environment.
- [ ] **Phase 4: Maintainer Documentation & Handoff** - Leave maintainers with the sign-off boundary, sync method, and deferred-work guidance in repo documentation.

## Phase Details

### Phase 1: Fork Delta Baseline & Intent Record
**Goal**: Maintainer can confirm the upstream sync target and review a classified, file-backed record of fork-specific Xilinx/Vivado divergences before merge work begins.
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, BASE-02, BASE-03, XILX-01, XILX-02
**Success Criteria** (what must be TRUE):
  1. Maintainer can identify the exact upstream tag or commit for this sync round and find it recorded in a repo artifact.
  2. Maintainer can open a file-backed fork-vs-upstream comparison and see every fork-only change classified as `keep`, `superseded`, `rewrite`, or `human-review`.
  3. Maintainer can trace each material Xilinx/Vivado behavior change to the commits and files that introduced or modified it.
  4. Maintainer can review a written intent record explaining why each material Xilinx/Vivado divergence exists and why it should be preserved, rewritten, or reconsidered.
**Plans**: 3 plans
Plans:
- [ ] `01-01-PLAN.md` — Pin the authoritative upstream baseline, record ancestry discrepancies, and install replayable baseline verification checks
- [ ] `01-02-PLAN.md` — Build the fork-only evidence set and master logical-change matrix from the verified merge-base
- [ ] `01-03-PLAN.md` — Package the executive summary, Xilinx intent record, and human-review handoff for Phase 2

### Phase 2: History-Aware Upstream Integration
**Goal**: Maintainer can bring this fork up to the confirmed upstream target while preserving required local Xilinx/Vivado behavior and isolating ambiguous outcomes for human review.
**Depends on**: Phase 1
**Requirements**: XILX-03, SYNC-01, SYNC-02, SYNC-03
**Success Criteria** (what must be TRUE):
  1. Maintainer can inspect the synchronized fork and see the confirmed upstream changes integrated without losing required local Xilinx/Vivado behavior.
  2. Maintainer can trace each non-trivial merge or conflict decision back to git history and the recorded fork-change intent instead of relying on unexplained text-only picks.
  3. Maintainer can identify which local divergences were kept, rewritten, or replaced during the sync and why.
  4. Maintainer can find a human-review artifact listing any unresolved or risky merge outcomes before Quartus sign-off begins.
**Plans**: 3 plans
Plans:
- [x] `02-01-PLAN.md` — Install the Phase 2 validator, pre-merge anchor, and seeded decision/review ledgers from the Phase 1 evidence set
- [x] `02-02-PLAN.md` — Merge upstream `v3.38.1` and reconcile the CLI, runtime, experimental, helper-library, and host-side overlap by logical change unit
- [x] `02-03-PLAN.md` — Package the integration summary, pre-Quartus review ledger, and Phase 3 handoff with the final non-Quartus gate

### Phase 3: Quartus Verification & Sign-Off
**Goal**: Maintainer can prove the synchronized fork passes this stage's required regression flow on this machine through the certified Quartus flake and can review what that sign-off does and does not cover.
**Depends on**: Phase 2
**Requirements**: VERI-01, VERI-02, VERI-03
**Success Criteria** (what must be TRUE):
  1. Maintainer can run the required regression flow on this machine through the certified Quartus flake for this stage.
  2. Maintainer can inspect sign-off output showing the synchronized fork passed the required regression suite for this stage.
  3. Maintainer can see which simulator or tooling path, commands, and artifacts produced the sign-off result.
  4. Maintainer can review any remaining verification gaps or unverified areas called out alongside the Quartus sign-off record.
**Plans**: 2 plans
Plans:
- [ ] `03-01-PLAN.md` — Xilinx-thematics audit of the Phase 2 import surface, grouped by theme with A/B/C classified findings (feeds the sign-off gap matrix)
- [ ] `03-02-PLAN.md` — Sign-off regression run via `svunit-certify-all`, `03-sign-off.md` authoring (pass matrix + gap matrix + residuals + forward-looking), `03-reproduce.sh` reproducibility script, and `.planning/LESSONS-LEARNED.md` seed

### Phase 4: Maintainer Documentation & Handoff
**Goal**: Maintainer can understand the sync method, sign-off boundary, deferred Xilinx-flake work, and any remaining review obligations without reconstructing project history.
**Depends on**: Phase 3
**Requirements**: DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):
  1. Maintainer can read repo documentation and see that Quartus is the sign-off environment for this stage.
  2. Maintainer can read repo documentation and see that the Xilinx flake remains future work rather than part of this round.
  3. Maintainer can follow documentation links to the fork-delta intent record and the history-aware upstream-sync method used in this repo.
  4. Maintainer can locate the human-review trail for complex merge outcomes from repo documentation.
**Plans**: 2 plans

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Fork Delta Baseline & Intent Record | 3/3 | Complete    | 2026-04-12 |
| 2. History-Aware Upstream Integration | 3/3 | Complete | 2026-04-12 |
| 3. Quartus Verification & Sign-Off | 0/2 | Not started | - |
| 4. Maintainer Documentation & Handoff | 0/2 | Not started | - |
