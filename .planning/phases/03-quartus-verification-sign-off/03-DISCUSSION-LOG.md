# Phase 3: Quartus Verification & Sign-Off - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `03-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 03-quartus-verification-sign-off
**Mode:** discuss (interactive)
**Areas discussed:** Sign-off target coverage, Pass criteria + Phase 2 residuals, Sign-off artifact layout + gap docs, Pre-sign-off Xilinx-thematics audit

---

## Sign-off target coverage

| Option | Description | Selected |
|--------|-------------|----------|
| All 5 targets (svunit-certify-all) | 23.4 qrun + 23.4 modelsim + 25.1 sim-only qrun + 25.1 sim-only modelsim + verilator-5.044; matches earlier "run on all versions" instruction; highest confidence, longest wall time | ✓ |
| Quartus-only (4 targets) | 23.4 qrun + 23.4 modelsim + 25.1 sim-only qrun + 25.1 sim-only modelsim; Verilator alongside but not gating | |
| 23.4 qrun only (conservative baseline) | Pre-existing qualified baseline only; 25.1 sim-only and modelsim are exploratory | |
| 23.4 both + Verilator cross-check | 23.4 qrun/modelsim gate; Verilator reported alongside non-blocking; 25.1 sim-only shown as provisional | |

**User's choice:** All 5 targets (svunit-certify-all) (recommended).
**Notes:** Aligns with the explicit instruction that qualification results should run on all versions of Quartus/Xilinx Vivado flake as they become available. Today's flake refactor registered exactly 5 targets — sign-off must cover all of them.

---

## Pass criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Target STATUS=PASS, current filters OK | Keep existing certify logic (failures=0, errors=0, passed>0); keep `not uvm_simple_model` filter | ✓ |
| Strict zero-skip | Every test must run; implies provisioning svverification license or accepting UVM failure | |
| Baseline-compared | Diff each run against a stored baseline; regressions block even if STATUS=PASS | |
| STATUS=PASS + log every skip to gap doc | Same bar as option 1 plus auto-flow skips into gap matrix | |

**User's choice:** Target STATUS=PASS with current filters (recommended).
**Notes:** UVM license isn't part of this sign-off environment; 25.1 sim-only has no baseline yet, so baseline-compare isn't viable. The existing certify logic is already trusted — reuse it.

---

## Phase 2 residual handling

| Option | Description | Selected |
|--------|-------------|----------|
| Document, don't block | Green regression IS the sign-off; needs-maintainer-check items listed as carried-forward review items | ✓ |
| Explicit per-item tick required | Maintainer must tick each of 5 items to resolved/accepted before sign-off goes green | |
| Regression pass + smoke-test assertions | Add targeted smoke tests for specific residuals (xsim flags, parser-queue typing) | |
| Separate sign-off section, maintainer countersigns | Two verdicts: regression (auto) and intent (line-by-line countersign) | |

**User's choice:** Document, don't block (recommended).
**Notes:** Matches PROJECT.md philosophy — "complex merge outcomes may require human checking — do not force unclear resolutions just to keep momentum." The residuals stay visible but don't stall verification.

---

## Sign-off artifact layout

| Option | Description | Selected |
|--------|-------------|----------|
| Both: phase-dir doc references artefacts | Phase-dir 03-sign-off.md cites run-ids into qualified-tools artefacts root; links only, no copying | ✓ |
| Phase-dir doc only | Self-contained phase-dir doc, artefacts-root runs not formally referenced | |
| Artefacts-root doc only | Rely on certify-all's final output as THE sign-off record; phase dir only has a pointer | |
| Both + a reproducibility script | Option 1 plus 03-reproduce.sh scripting the exact sign-off invocation | |

**User's choice:** Both: phase-dir doc references artefacts (recommended).
**Notes:** The phase-dir is the maintainer entry point; artefacts-root is the evidence archive. Reproducibility script remains planner-discretion under D-06.

---

## Coverage-gap documentation format

| Option | Description | Selected |
|--------|-------------|----------|
| Structured gap matrix | Table: Dimension \| Covered \| Not covered \| Why deferred \| Owner/next phase | ✓ |
| Free-prose "What this sign-off does NOT cover" | Bulleted list under a Limits heading; easier to write, less parseable | |
| Gap matrix + auto-generated untested-targets list | Structured matrix PLUS machine-generated registry-vs-plausible-combos list | |
| Single gap-register JSON + rendered table | Source-of-truth JSON with schema, table rendered from it; reusable for future sign-offs | |

**User's choice:** Structured gap matrix (recommended).
**Notes:** Parseable enough for audits without being over-engineered. JSON source-of-truth was tempting for XFLK-01 reuse but deferred to backlog.

---

## Pre-sign-off Xilinx-thematics audit

| Option | Description | Selected |
|--------|-------------|----------|
| Fold as Phase 3 Plan 1, sign-off is Plan 2 | Audit first (from todo), findings feed sign-off gap matrix; matches roadmap 2-plan count | ✓ |
| Keep as separate todo, run before sign-off but outside Phase 3 | User runs /gsd-check-todos, audit completes, then Phase 3 is pure sign-off | |
| Punt audit to Phase 4 or backlog | Sign off as-is; audit becomes Phase 4 or backlog; risks silent upstream regression | |
| Fold audit + elevate findings to maintainer-review | Fold as Plan 1 but all "likely needs fixing" findings auto-escalate; fixes happen later | |

**User's choice:** Fold as Phase 3 Plan 1, sign-off is Plan 2 (recommended).
**Notes:** Matches the roadmap's exact "2 plans" count. Audit produces findings; fix work surfaces as follow-up phases (not in Phase 3 scope).

---

## Claude's Discretion

- Exact filenames for Plan 1's audit report and Plan 2's sign-off doc (kept default `03-sign-off.md` but planner can adjust).
- Grouping heuristic for the Xilinx-thematics audit checklist (by file vs by theme).
- Whether the gap matrix is inlined in the sign-off doc or split into a companion file.
- Whether Plan 2 wraps `svunit-certify-all` in a reproducibility script.

## Deferred Ideas

- Xilinx/xsim sign-off (XFLK-01, v2) — Vivado flake uses `buildFHSEnv`, the `fhs` adapter in `scripts/certify.sh` is a stub today.
- Fixes for Xilinx-thematics audit findings — out of Phase 3 scope; follow-up phase or maintainer-review.
- Baseline-compared regression — no 25.1 baseline yet; future sign-off round could add.
- Scheduled / CI-driven sign-off — out of scope, point-in-time only.
- Machine-readable sign-off manifest (for diffing future sign-offs) — backlog-worthy if sign-off becomes routine.

## Reviewed Todos (not folded)

None — the single pending todo (Xilinx thematics audit) was folded into Plan 1.
