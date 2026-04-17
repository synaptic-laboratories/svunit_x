# Phase 3: Quartus Verification & Sign-Off - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a maintainer-facing sign-off record that proves the Phase 2 upstream-synced fork passes the required regression flow on this machine through the certified Quartus flake, and makes explicit what the sign-off does and does not cover. The phase delivers: (1) a pre-sign-off Xilinx-thematics audit of upstream-imported changes, and (2) a consolidated sign-off record citing per-target qualification runs.

This phase does NOT: build the Xilinx flake, run xsim-based verification, exercise Agilex/Stratix synth paths, or re-do Phase 2 intent reconciliation. Those belong to later phases or remain deferred per PROJECT.md.

</domain>

<decisions>
## Implementation Decisions

### Sign-off target coverage
- **D-01:** Sign-off is declared green when `svunit-certify-all` completes with every registered target reporting PASS. All 5 current targets are in scope: `quartus-23-4-qrun`, `quartus-23-4-modelsim`, `quartus-25-1-sim-only-qrun`, `quartus-25-1-sim-only-modelsim`, `verilator-5-044`. Matches the user instruction that "qualification results should run on all versions of Quartus/Xilinx Vivado flake as they become available" — today that set is these five.

### Pass criteria
- **D-02:** Per-target PASS bar follows the existing `scripts/certify.sh` definition: `failures=0`, `errors=0`, `passed>0`. The current pytest filter `"<tool> and not uvm_simple_model"` stays in place on Quartus targets — UVM tests need a svverification license the container does not have. Skipped and excluded tests are reported in each run's `build-info.json` and `timing-summary.json` and flow into the Phase 3 gap matrix (D-05), but they do not gate sign-off.

### Phase 2 residual handling
- **D-03:** The five `needs-maintainer-check` items from `02-decision-ledger.md` (LCU-01 `bin/runSVUnit` xsim residuals, LCU-03 `svunit_base/*.sv` parser-safe queue typing, LCU-04 experimental SV tree, HR-03 xsim flag/cleanup, HR-04 `test/utils.py` justified replacement) are documented in the Phase 3 sign-off record as carried-forward review items with ledger pointers. They do not block sign-off. Matches PROJECT.md — "Complex merge outcomes may require human checking — do not force unclear resolutions just to keep momentum."

### Sign-off artifact layout
- **D-04:** The consolidated sign-off record lives at `.planning/phases/03-quartus-verification-sign-off/03-sign-off.md` (exact filename chosen by planner). Per-target run artefacts stay where the existing flake already writes them (qualified-tools artefacts root, `YYYYMMDD-HHMM-…` run-id dirs). The phase-dir sign-off doc CITES the specific run-ids used (via relative path) and embeds the pass matrix and gap list inline. Copies nothing — links only. Phase dir is the maintainer entry point; artefacts root is the evidence archive.

### Coverage-gap documentation
- **D-05:** Gaps surface in the sign-off doc as a **structured gap matrix** with columns: `Dimension | Covered | Not covered | Why deferred | Owner / next phase`. Gaps known now to be in scope for this matrix:
  - Simulator: Vivado `xsim` deferred (XFLK-01, v2). Quartus/Questa covered via 23.4 and 25.1.
  - Device families: Agilex / Stratix / Arria synth paths not exercised by SVUnit regression.
  - Test categories: UVM simple model tests excluded (no svverification license in container).
  - Intent carry-forwards: Phase 1 HR-01 (ancestry disagreement), HR-02 (marker disagreement), and the five Phase 2 `needs-maintainer-check` items.
  - Native vs container divergence: Verilator native tests vs Questa container tests — same pytest suite, different execution path.

### Phase 3 plan layout
- **D-06:** The phase decomposes into exactly two plans, matching the ROADMAP's `Plans: 2`:
  - **Plan 1 — Xilinx-thematics audit.** Folds the pending todo `.planning/todos/pending/2026-04-12-audit-imported-changes-for-xilinx-thematics.md`. Deliverable: an audit report identifying which upstream-imported changes (from Phase 2) need follow-up against fork Xilinx themes (parser-safe queue typing `[$]`, explicit declarations/signatures, warning reduction). Findings feed the sign-off doc's gap matrix; code fixes for flagged items are NOT in Phase 3 scope — they surface as follow-up phases or maintainer-review items.
  - **Plan 2 — Sign-off run + consolidated sign-off doc.** Execute `svunit-certify-all`, verify every target lands STATUS=PASS, produce `03-sign-off.md` citing the run-ids, the pass matrix, the gap matrix (D-05), and the carried-forward residuals (D-03).

### Folded Todos
- **Audit imported changes for Xilinx thematics** (`.planning/todos/pending/2026-04-12-audit-imported-changes-for-xilinx-thematics.md`) — folded as Phase 3 Plan 1. The todo's "Solution" steps 1-3 (derive checklist, audit imports, classify findings) are Plan 1's scope. Steps 4-5 (report for approval, apply fixes) are out of Plan 1 scope and become follow-up phases.

### Claude's Discretion
- Exact filename for Plan 1's audit-report deliverable.
- Exact filename for Plan 2's sign-off doc (referred to as `03-sign-off.md` above — planner can choose something else as long as it's in the phase dir).
- Grouping heuristic for the Xilinx-thematics audit checklist (e.g. whether to group by file or by theme).
- Whether the gap matrix is inlined in the sign-off doc or split into a companion file.
- Whether Plan 2 runs `svunit-certify-all` directly or wraps it in a reproducibility script (Plan 2 may choose to add one for VERI-01 clarity, but it's not required).

</decisions>

<specifics>
## Specific Ideas

- Today's `svunit-certify-all` already writes `qualification-results.md`, `build-info.json`, `timing-summary.json`, `tests.xml`, and `test-log.txt` per target run. The Phase 3 sign-off doc should treat those as authoritative evidence and not reproduce their contents verbatim.
- The `latest` symlink in the artefacts root points to the most recent qualification run per target. The sign-off doc should cite the run-id used for sign-off explicitly (not rely on `latest`, which may move).
- The sign-off doc is the artifact VERI-03 ("Verification output records what was run, under which simulator/tooling path, and any remaining coverage gaps") lands against — the gap matrix is the literal "remaining coverage gaps" deliverable.
- The Phase 2 decision ledger uses a single markdown table as its intent record. Phase 3's gap matrix should follow that same single-table-per-concern convention for consistency.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project framing
- `.planning/PROJECT.md` — Quartus-as-sign-off-environment constraint, Xilinx-flake deferral, maintainer-visible intent preservation
- `.planning/REQUIREMENTS.md` — Phase 3 requirements `VERI-01`, `VERI-02`, `VERI-03`; v2 deferred requirement `XFLK-01`
- `.planning/ROADMAP.md` §"Phase 3: Quartus Verification & Sign-Off" — goal, depends-on, success criteria

### Prior-phase context
- `.planning/phases/01-fork-delta-baseline-intent-record/01-CONTEXT.md` — Phase 1 framing decisions
- `.planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json` — pinned upstream target, merge-base, and ancestry marker disagreements
- `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` — HR-01 (ancestry), HR-02 (marker) unresolved carry-forwards
- `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` — the five LCU/HR items with `needs-maintainer-check` status
- `.planning/phases/02-history-aware-upstream-integration/02-integration-baseline.json` — Phase 2 pre-merge anchor manifest
- `.planning/phases/02-history-aware-upstream-integration/02-integration-summary.md` — Phase 2 maintainer-approved summary

### Flake and certify tooling (produced outside GSD, today's refactor)
- `flake.nix` — top-level wiring, registry consumer, per-target package generation
- `nix/registry.nix` — simulator target registry; all 5 current sign-off targets are defined here
- `nix/mk-certify.nix` — per-target certify-wrapper factory, env-var exports
- `scripts/certify.sh` — shared adapter dispatch (container/native/fhs), pass-criteria definition
- `scripts/timing-summary.py`, `scripts/timing-report.py` — post-run analysis helpers

### Existing codebase understanding
- `.planning/codebase/STACK.md` — simulator/tooling surface
- `.planning/codebase/ARCHITECTURE.md` — simulator behavior locations in the codebase
- `.planning/codebase/CONCERNS.md` — known fragile areas (relevant to the Xilinx-thematics audit)

### Folded todo
- `.planning/todos/pending/2026-04-12-audit-imported-changes-for-xilinx-thematics.md` — Plan 1 scope definition

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `svunit-certify-all` — already produces the pass matrix across all 5 targets. Plan 2 consumes this; Phase 3 does not need to reimplement.
- `scripts/certify.sh` — the pass-criteria logic (failures=0, errors=0, passed>0) is already settled there. Plan 2 relies on it, does not re-define.
- Qualification artefacts root at `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/` — per-run dirs plus `latest` symlink. Sign-off doc cites run-ids from here.
- `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` table format — template for the Phase 3 sign-off carried-forward residuals section.

### Established Patterns
- Phase artefacts follow `NN-<kind>.md` naming (e.g. `01-fork-delta-matrix.md`, `02-decision-ledger.md`). Phase 3 deliverables follow this: `03-xilinx-thematics-audit.md`, `03-sign-off.md` (final names at planner discretion).
- Evidence tables use a single markdown table with clearly-scoped columns — continue that pattern for Phase 3 gap matrix.
- Commit messages use conventional-commits (`docs(03): …`, `feat(03): …`).

### Integration Points
- Plan 1 findings feed Plan 2's gap matrix (specifically the "intent carry-forwards" rows).
- Plan 2's run-id citations must remain stable — if the artefacts-root dir is rotated or pruned, the sign-off references break. Plan 2 should not rely on `latest`.
- Phase 4 (Maintainer Documentation & Handoff, DOCS-01/DOCS-02) will cite the Phase 3 sign-off doc; filename and location should be stable before Phase 4 starts.

</code_context>

<deferred>
## Deferred Ideas

- **Xilinx/xsim sign-off** — v2 requirement XFLK-01; Vivado flake at `g_xilinx_vivado/r_src_v2025_1` is buildFHSEnv-based (different adapter than container/native). The `fhs` adapter in `scripts/certify.sh` errors out cleanly as a stub today — wiring it up is future work.
- **Fixes for Xilinx-thematics audit findings** — the Plan 1 audit produces a report of likely fixes; applying those fixes is not Phase 3 scope. Surfaces as follow-up phases or maintainer-review items per D-06.
- **Baseline-compared regression** — keeping a stored baseline against which future runs are diffed was considered but rejected for Phase 3 (no 25.1 sim-only baseline yet). Could re-open in a future sign-off round once baselines exist.
- **Scheduled / CI-driven sign-off** — out of scope. Phase 3 is a point-in-time maintainer-run sign-off, not a continuous gate.
- **Reproducibility script (`03-reproduce.sh`)** — optional, planner discretion under D-06.
- **Machine-readable sign-off manifest for diffing future sign-offs** — surfaced during discussion, not folded. If Phase 3 sign-off becomes routine, this may warrant its own phase or a backlog item.

### Reviewed Todos (not folded)
None — the single pending todo (Xilinx thematics audit) was folded into Plan 1.

</deferred>

---

*Phase: 03-quartus-verification-sign-off*
*Context gathered: 2026-04-17*
