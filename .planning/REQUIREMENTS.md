# Requirements: SVUnit X Upstream Catch-Up

**Defined:** 2026-04-11
**Core Value:** Bring upstream SVUnit changes into this fork without regressing the fork's Xilinx/Vivado-specific behavior, using Quartus-based verification as the sign-off gate for this stage.

## v1 Requirements

Requirements for the current upstream catch-up stage. Each maps to one roadmap phase.

### Baseline Identification

- [ ] **BASE-01**: Maintainer can confirm the exact upstream tag or commit to sync against for this stage and record that reference in the repo
- [ ] **BASE-02**: Maintainer can generate a file-backed comparison of this fork against the confirmed upstream target
- [ ] **BASE-03**: Maintainer can classify each fork-only change as `keep`, `superseded`, `rewrite`, or `human-review`

### Xilinx Preservation

- [ ] **XILX-01**: Maintainer can trace local Xilinx/Vivado-related behavior to the commits and files that introduced or adjusted it
- [ ] **XILX-02**: Maintainer can document the intent of each material Xilinx/Vivado-related fork change in a reviewable repo artifact
- [ ] **XILX-03**: Upstream integration preserves required Xilinx/Vivado-specific behavior or records an explicit justified replacement for it

### Upstream Integration

- [ ] **SYNC-01**: Maintainer can integrate changes from the confirmed upstream target into this fork without dropping required fork-specific behavior
- [ ] **SYNC-02**: Conflicts between upstream and fork changes are resolved using git history and documented intent rather than text-only merge choices
- [ ] **SYNC-03**: Any unresolved or risky conflict outcomes are recorded in a human-review artifact before sign-off

### Verification

- [ ] **VERI-01**: Maintainer can run the required regression flow on this machine through the certified Quartus flake for this stage
- [ ] **VERI-02**: Quartus-based sign-off demonstrates that the synchronized fork passes the required regression suite for this stage
- [ ] **VERI-03**: Verification output records what was run, under which simulator/tooling path, and any remaining coverage gaps

### Documentation

- [ ] **DOCS-01**: Repo documentation states that Quartus is the sign-off environment for this stage and that the Xilinx flake remains future work
- [ ] **DOCS-02**: Repo documentation points maintainers to the fork-delta intent record and the chosen upstream-sync method

## v2 Requirements

Deferred to later maintenance rounds.

### Future Tooling

- **XFLK-01**: Maintainer can run equivalent sign-off verification through a certified Xilinx flake once that environment is ready
- **SYNC-OPS-01**: Maintainer has a repeatable workflow for future upstream catch-up releases beyond this one

## Out of Scope

Explicitly excluded for this stage.

| Feature | Reason |
|---------|--------|
| Build the Xilinx flake now | The user stated it is still in progress and Quartus is the sign-off environment for this stage |
| Add broad new simulator capabilities unrelated to upstream catch-up | This stage is about synchronization and preservation, not feature expansion |
| Resolve complex conflicts without preserving intent records | The user expects history-aware and reviewable reconciliation, not blind text merges |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 1 | Pending |
| BASE-02 | Phase 1 | Pending |
| BASE-03 | Phase 1 | Pending |
| XILX-01 | Phase 1 | Pending |
| XILX-02 | Phase 1 | Pending |
| XILX-03 | Phase 2 | Pending |
| SYNC-01 | Phase 2 | Pending |
| SYNC-02 | Phase 2 | Pending |
| SYNC-03 | Phase 2 | Pending |
| VERI-01 | Phase 3 | Pending |
| VERI-02 | Phase 3 | Pending |
| VERI-03 | Phase 3 | Pending |
| DOCS-01 | Phase 4 | Pending |
| DOCS-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-11 after roadmap creation*
