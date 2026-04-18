---
phase: 3
slug: quartus-verification-sign-off
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `03-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + `grep` + `jq` (no new Python test framework); `nix run` drives the regression |
| **Config file** | none — validators are inline shell commands in task `<acceptance_criteria>` |
| **Quick run command** | Plan 1: `grep -rn '<<SLL-FIX>>\|XILINX_SIMULATOR\|needs to be declared as a dynamic array\[\$\]' svunit_base/ src/experimental/` (< 1s). Plan 2 (post-run): `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json \| sort -u` (< 1s) |
| **Full suite command** | `nix run .#svunit-certify-all` (5 sequential targets; estimated 20–60 min — no prior run on this machine to benchmark) |
| **Estimated runtime** | full suite: 20–60 min; per-task validators: < 1s |

---

## Sampling Rate

- **After every task commit:** Plan 1 — run the 4-theme grep; Plan 2 — if the task touches `03-sign-off.md`, grep the doc for required headings and gap-matrix columns; if the task touches `03-reproduce.sh`, run `bash -n 03-reproduce.sh`.
- **After every plan wave:** Plan 2 — at most one `nix run .#svunit-certify-all` per wave that writes or updates the sign-off doc (expensive; typically once per plan, not per task).
- **Before `/gsd-verify-work`:** `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json | sort -u` == `PASS` (single value, 5 occurrences) AND `03-sign-off.md` doc-structure greps all pass.
- **Max feedback latency:** per-task < 1s; per-wave regression 20–60 min.

---

## Per-Task Verification Map

*(Populated by planner when PLAN.md files are authored. Contract: every task MUST have either an `<automated>` check or a Wave 0 dependency row here.)*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-?? | 01 | ? | VERI-02 (Plan 1 feeds gap matrix) | — | audit scope stays within 31-file boundary | doc-structure | `grep -qE 'T1\|T2\|T3\|T4' 03-xilinx-thematics-audit.md` | created by Plan 1 | ⬜ pending |
| 3-02-?? | 02 | ? | VERI-01 | — | preflight confirms flake + images + licenses | smoke | `nix flake show 2>&1 \| grep -c 'svunit-certify'` ≥ 6 | existing `flake.nix` | ⬜ pending |
| 3-02-?? | 02 | ? | VERI-02 | — | regression pass across all 5 targets with 5 distinct run-ids | integration | `nix run .#svunit-certify-all` exit 0 AND `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json \| sort -u` == `PASS` (5 dir count) | created by certify-all |  ⬜ pending |
| 3-02-?? | 02 | ? | VERI-03 | T-03-01 (license-disclosure) | sign-off doc cites paths, not license contents | doc-structure | `! grep -l 'SERVER.*\\|FEATURE\\|INCREMENT' 03-sign-off.md` AND gap-matrix columns grep passes | created by Plan 2 |  ⬜ pending |
| 3-02-?? | 02 | ? | VERI-01 (D-07) | — | `03-reproduce.sh` drives certify-all and captures 5 run-ids | smoke | `bash -n .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh` exit 0 | created by Plan 2 |  ⬜ pending |
| 3-02-?? | 02 | ? | VERI-03 (D-08) | — | `03-sign-off.md` contains `## Next Sign-Off Round` section | doc-structure | `grep -q '^## Next Sign-Off Round' 03-sign-off.md` | created by Plan 2 |  ⬜ pending |
| 3-02-?? | 02 | ? | VERI-03 (D-09) | — | `.planning/LESSONS-LEARNED.md` seeded with Phase 3 section | doc-structure | `grep -q '^## Phase 3' .planning/LESSONS-LEARNED.md` AND `grep -qE 'run-id.*collision\|latest.*symlink\|Xilinx.*theme' .planning/LESSONS-LEARNED.md` | created by Plan 2 |  ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No test file creation needed — Plan 1 and Plan 2 both rely on inline shell/grep/jq validation.
- [ ] No framework install needed — `nix`, `jq`, `grep`, `podman` are in the dev shell or on the host.
- [ ] `bash -n` syntax check available on the host for D-07's `03-reproduce.sh` (no install).

*(No blocking Wave 0 gaps.)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer judges gap-matrix completeness | VERI-03 | The structural greps confirm the matrix columns and residual IDs exist, but judging whether *the right gaps* are enumerated requires human review against PROJECT.md intent. | Maintainer reads `03-sign-off.md` §Gap Matrix and compares against PROJECT.md deferrals + PHASE 1/2 carry-forwards. |
| Maintainer judges forward-looking "Next Sign-Off Round" realism | VERI-03 (D-08) | Whether the section identifies the *right* drift risks is a judgement call informed by the environment. | Maintainer reads `03-sign-off.md` §Next Sign-Off Round and sanity-checks the flake-pin / license / XFLK-01 callouts. |
| Maintainer judges whether `LESSONS-LEARNED.md` captures non-obvious lessons | VERI-03 (D-09) | Content-floor greps exist (D-09 minimums), but "is this actually useful for the next revision" is human. | Maintainer reads `.planning/LESSONS-LEARNED.md` §Phase 3 and confirms it contains reusable lessons, not a decision recap. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for per-task validators (full regression is gated per-wave only)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
