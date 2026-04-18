---
phase: 3
slug: quartus-verification-sign-off
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
updated: 2026-04-18 (task IDs populated at plan-authoring time)
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

Task-ID convention: `{phase:02}-{plan:02}-{task:02}` (zero-padded throughout), e.g. `03-01-01` = Phase 3 / Plan 01 / Task 01. Matches the `depends_on: ["03-01"]` form used in plan frontmatter.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | VERI-02 (feeds gap matrix), VERI-03 (Plan 1 cross-reference) | T-03-02, T-03-03 | audit scope constrained to 31-file list; no source files modified | doc-structure | `grep -c '^## Theme T' 03-xilinx-thematics-audit.md` == `4` AND scope anchor `84b88033590a1469a238be84d8526b25a9f29d10` present AND `git diff --name-only HEAD -- bin/ svunit_base/ src/ test/utils.py` returns 0 | created by Plan 1 Task 1 | ⬜ pending |
| 03-02-01 | 02 | 2 | VERI-01 (D-07 preflight + reproduce script) | T-03-01, T-03-05 | preflight confirms licenses + images + flake; `03-reproduce.sh` does not cite `latest` | smoke | `bash -n 03-reproduce.sh` exit 0 AND `grep -q 'nix run .#svunit-certify-all' 03-reproduce.sh` AND `grep -q 'quartus-23-4-qrun' 03-reproduce.sh` AND (5 target greps all match) | created by Plan 2 Task 1 | ⬜ pending |
| 03-02-02 | 02 | 2 | VERI-01, VERI-02 (D-01, D-02) | T-03-04 | regression pass across all 5 targets with 5 distinct run-ids; all targets ran against one svunit_commit | integration | `awk -F'\t' 'NR>1' $TSV \| wc -l` == `5` AND `awk -F'\t' 'NR>1 {print $3}' $TSV \| sort -u` == `PASS` AND `awk -F'\t' 'NR>1 {print $2}' $TSV \| sort -u \| wc -l` == `5` AND `awk -F'\t' 'NR>1 {print $8}' $TSV \| sort -u \| wc -l` == `1` | created by Plan 2 Task 2 | ⬜ pending |
| 03-02-03 | 02 | 2 | VERI-01, VERI-02, VERI-03 (D-03, D-04, D-05, D-08) | T-03-01, T-03-02 | sign-off doc cites paths, not license contents; no `/latest/` citations; all 9 headings + 5 targets + 7 residuals + 3 requirement IDs + 5 gap columns present | doc-structure | 9 heading greps pass AND `grep -E '/latest/(build-info\|qualification-results)' 03-sign-off.md` returns nothing AND `grep -E 'SERVER [a-z0-9]\|FEATURE [A-Z0-9]{3,}\|INCREMENT [A-Z]' 03-sign-off.md` returns nothing | created by Plan 2 Task 3 | ⬜ pending |
| 03-02-04 | 02 | 2 | VERI-03 (D-09) | — | `.planning/LESSONS-LEARNED.md` seeded with Phase 3 section; 4+ lessons; append-only policy stated; no decision-ID recap | doc-structure | `grep -q '^## Phase 3' .planning/LESSONS-LEARNED.md` AND `grep -cE '^### L3-' .planning/LESSONS-LEARNED.md` >= `4` AND `grep -qiE 'run-id.*collision\|latest.*symlink\|Xilinx-thematic' .planning/LESSONS-LEARNED.md` AND `grep -qE 'append-only\|PREPEND' .planning/LESSONS-LEARNED.md` | created by Plan 2 Task 4 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No test file creation needed — Plan 1 and Plan 2 both rely on inline shell/grep/jq validation.
- [x] No framework install needed — `nix`, `jq`, `grep`, `podman` are in the dev shell or on the host.
- [x] `bash -n` syntax check available on the host for D-07's `03-reproduce.sh` (no install).

*(No blocking Wave 0 gaps.)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer judges gap-matrix completeness | VERI-03 | The structural greps confirm the matrix columns and residual IDs exist, but judging whether *the right gaps* are enumerated requires human review against PROJECT.md intent. | Maintainer reads `03-sign-off.md` §Gap Matrix and compares against PROJECT.md deferrals + PHASE 1/2 carry-forwards. |
| Maintainer judges forward-looking "Next Sign-Off Round" realism | VERI-03 (D-08) | Whether the section identifies the *right* drift risks is a judgement call informed by the environment. | Maintainer reads `03-sign-off.md` §Next Sign-Off Round and sanity-checks the flake-pin / license / XFLK-01 callouts. |
| Maintainer judges whether `LESSONS-LEARNED.md` captures non-obvious lessons | VERI-03 (D-09) | Content-floor greps exist (D-09 minimums), but "is this actually useful for the next revision" is human. | Maintainer reads `.planning/LESSONS-LEARNED.md` §Phase 3 and confirms it contains reusable lessons, not a decision recap. |
| Maintainer judges Plan 1 A/B findings severity | VERI-02 (via gap matrix) | Classification is rule-based (A/B/C grep hits) but the *materiality* of each finding for downstream fixes is a maintainer call. | Maintainer reads `03-xilinx-thematics-audit.md` Findings tables and confirms A-class findings represent real fork intent drift, not grep false positives. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s for per-task validators (full regression is gated per-wave only)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** populated at plan-authoring time; awaiting task execution.
