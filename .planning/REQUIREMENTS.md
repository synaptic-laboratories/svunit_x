# Requirements: SVUnit X Upstream Catch-Up

**Defined:** 2026-04-11
**Core Value:** Bring upstream SVUnit changes into this fork without regressing the fork's Xilinx/Vivado-specific behavior, using Quartus-based verification as the sign-off gate for this stage.

## v1 Requirements

Requirements for the current upstream catch-up stage. Each maps to one roadmap phase.

### Baseline Identification

- [x] **BASE-01**: Maintainer can confirm the exact upstream tag or commit to sync against for this stage and record that reference in the repo
- [x] **BASE-02**: Maintainer can generate a file-backed comparison of this fork against the confirmed upstream target
- [x] **BASE-03**: Maintainer can classify each fork-only change as `keep`, `superseded`, `rewrite`, or `human-review`

### Xilinx Preservation

- [x] **XILX-01**: Maintainer can trace local Xilinx/Vivado-related behavior to the commits and files that introduced or adjusted it
- [x] **XILX-02**: Maintainer can document the intent of each material Xilinx/Vivado-related fork change in a reviewable repo artifact
- [x] **XILX-03**: Upstream integration preserves required Xilinx/Vivado-specific behavior or records an explicit justified replacement for it

### Upstream Integration

- [x] **SYNC-01**: Maintainer can integrate changes from the confirmed upstream target into this fork without dropping required fork-specific behavior
- [x] **SYNC-02**: Conflicts between upstream and fork changes are resolved using git history and documented intent rather than text-only merge choices
- [x] **SYNC-03**: Any unresolved or risky conflict outcomes are recorded in a human-review artifact before sign-off

### Verification

- [x] **VERI-01**: Maintainer can run the required regression flow on this machine through the certified Quartus flake for this stage
- [x] **VERI-02**: Quartus-based sign-off demonstrates that the synchronized fork passes the required regression suite for this stage
- [x] **VERI-03**: Verification output records what was run, under which simulator/tooling path, and any remaining coverage gaps

### Xilinx Vivado xsim Integration (promoted from v2 on 2026-04-18)

- [ ] **XFLK-01**: Maintainer can run equivalent sign-off verification through a certified Xilinx Vivado xsim flake as a sixth sign-off target alongside the five Quartus/Verilator targets
- [ ] **XFLK-02**: The `fhs` adapter in `scripts/certify.sh` is implemented (no longer a stub) and handles the `buildFHSEnv`-based Vivado flake invocation path; pass criteria are defined for xsim and surfaced in the consolidated sign-off manifest

### Documentation

- [ ] **DOCS-01**: Repo documentation states which sign-off environments cover this stage (Quartus targets + Xilinx Vivado xsim) and identifies remaining verification dimensions that are future work
- [ ] **DOCS-02**: Repo documentation points maintainers to the fork-delta intent record and the chosen upstream-sync method

## v2 Requirements

Deferred to later maintenance rounds.

### Future Tooling

- **SYNC-OPS-01**: Maintainer has a repeatable workflow for future upstream catch-up releases beyond this one

## Out of Scope

Explicitly excluded for this stage.

| Feature | Reason |
|---------|--------|
| Add broad new simulator capabilities unrelated to upstream catch-up | This stage is about synchronization, preservation, and sign-off; not feature expansion |
| Resolve complex conflicts without preserving intent records | The user expects history-aware and reviewable reconciliation, not blind text merges |

_Note: "Build the Xilinx flake now" was in this table as of 2026-04-11. It was promoted to active scope on 2026-04-18 as XFLK-01/XFLK-02 once Phase 3 sign-off confirmed the certify tooling surface could absorb a Vivado-xsim target._

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 1 | Complete |
| BASE-02 | Phase 1 | Complete |
| BASE-03 | Phase 1 | Complete |
| XILX-01 | Phase 1 | Complete |
| XILX-02 | Phase 1 | Complete |
| XILX-03 | Phase 2 | Complete |
| SYNC-01 | Phase 2 | Complete |
| SYNC-02 | Phase 2 | Complete |
| SYNC-03 | Phase 2 | Complete |
| VERI-01 | Phase 3 | Complete |
| VERI-02 | Phase 3 | Complete |
| VERI-03 | Phase 3 | Complete |
| XFLK-01 | Phase 4 | Pending |
| XFLK-02 | Phase 4 | Pending |
| DOCS-01 | Phase 5 | Pending |
| DOCS-02 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 16 total (was 14; XFLK-01/XFLK-02 promoted from v2 on 2026-04-18)
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-18 after Phase 3 completion + Xilinx-integration scope amendment (Phase 4 inserted, Maintainer Docs renumbered to Phase 5)*
