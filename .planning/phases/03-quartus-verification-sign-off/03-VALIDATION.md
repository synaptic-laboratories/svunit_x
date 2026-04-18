---
phase: 3
slug: quartus-verification-sign-off
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
updated: 2026-04-18 (revised post --reviews pass — see §Revision note)
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `03-RESEARCH.md` §Validation Architecture.
> Revised 2026-04-18 post `03-REVIEWS.md` cross-AI review pass.

---

## Revision note (reviews pass, 2026-04-18)

Changes driven by `03-REVIEWS.md`:

- **Task count per Plan 2 unchanged (4 tasks)** but acceptance commands tightened.
- **Source of truth for run-ids shifted** from `/tmp/svunit-reproduce-runids.*.tsv` to `.planning/phases/03-quartus-verification-sign-off/03-sign-off-manifest.tsv` (phase-dir-resident). All acceptance commands reference the phase-dir path, not `ls -t /tmp/...`.
- **jq-semantic acceptance replaces presence-grep** for Task 03-02-03: verification now walks the manifest and asserts `.target` + `.qualification_status` per cited `build-info.json`.
- **Preflight scope widened** for Task 03-02-01: `command -v` for host tools, `test -w` for ARTEFACTS_ROOT, `curl -Isf` for `bootstrap.pypa.io`.
- **Plan 1 scope count** corrected to 32 (was 31 narrative / 33 enumerated). Greps iterate the `AUDIT_FILES` allowlist, not directory globs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + `jq` + `awk` (no new Python test framework); `nix run` drives the regression |
| **Config file** | none — validators are inline shell commands in task `<acceptance_criteria>` |
| **Quick run command** | Plan 1: iterate `AUDIT_FILES` with the 4-theme diff-against-baseline + positive greps (< 1s). Plan 2 (post-run): `awk -F'\t' 'NR>1 {print $1, $9}' .../03-sign-off-manifest.tsv \| while read -r t p; do jq -r .qualification_status "$p/build-info.json"; done \| sort -u` (< 1s) should return `PASS` only. |
| **Full suite command** | `bash .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh` (5 sequential per-target apps; estimated 20–60 min) |
| **Estimated runtime** | full suite: 20–60 min; per-task validators: < 1s |

---

## Sampling Rate

- **After every task commit:** Plan 1 — run the 4-theme greps over `AUDIT_FILES`; Plan 2 — if the task touches `03-sign-off.md`, re-run the jq-semantic acceptance loop; if the task touches `03-reproduce.sh`, run `bash -n 03-reproduce.sh`.
- **After every plan wave:** Plan 2 — at most one full regression per wave that writes the manifest (expensive; typically once per plan).
- **Before `/gsd-verify-work`:** manifest's `qualification_status` column is `PASS` for all 5 rows (jq-verified against `build-info.json`) AND `03-sign-off.md` doc-structure greps pass AND no unfilled `<...>` placeholders in the sign-off doc.
- **Max feedback latency:** per-task < 1s; per-wave regression 20–60 min.

---

## Per-Task Verification Map

Task-ID convention: `{phase:02}-{plan:02}-{task:02}` (zero-padded throughout).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | VERI-02 (feeds gap matrix), VERI-03 (Plan 1 cross-reference) | T-03-02, T-03-03 | audit scope constrained to 32-file allowlist; no source files modified; uvm-mock anchor does not appear as a findings row | doc-structure | `grep -c '^## Theme T' 03-xilinx-thematics-audit.md` == `4` AND scope anchor `84b88033590a1469a238be84d8526b25a9f29d10` present AND scope count `32` present AND `! grep -qE '<N_[ABC]>' 03-xilinx-thematics-audit.md` AND `git diff --name-only HEAD -- bin/ svunit_base/ src/ test/utils.py` returns 0 | created by Plan 1 Task 1 | ⬜ pending |
| 03-02-01 | 02 | 2 | VERI-01 (D-07 preflight + reproduce script) | T-03-01, T-03-05 | `command -v` host tools + `test -w $ARTEFACTS_ROOT` + `curl -Isf bootstrap.pypa.io` + `flock` concurrency guard; unique per-target `--output-dir`; no `/latest/` citations | smoke | `bash -n 03-reproduce.sh` exit 0 AND script contains `flock`, `03-sign-off-manifest.tsv`, `bootstrap.pypa.io`, `command -v`, `test -w`, and all 5 per-target app names AND `! grep -qE '/latest/build-info' 03-reproduce.sh` | created by Plan 2 Task 1 | ⬜ pending |
| 03-02-02 | 02 | 2 | VERI-01, VERI-02 (D-01, D-02) | T-03-04, T-03-05 | 5 per-target runs into 5 unique evidence paths; all ran against one `svunit_commit`; `flock` held throughout | integration | `TSV=.planning/phases/03-quartus-verification-sign-off/03-sign-off-manifest.tsv; test -f "$TSV" && [ "$(awk -F'\t' 'NR>1' "$TSV" \| wc -l)" -eq 5 ] && [ "$(awk -F'\t' 'NR>1 {print $3}' "$TSV" \| sort -u)" = "PASS" ] && [ "$(awk -F'\t' 'NR>1 {print $1}' "$TSV" \| sort -u \| wc -l)" -eq 5 ] && [ "$(awk -F'\t' 'NR>1 {print $8}' "$TSV" \| sort -u \| wc -l)" -eq 1 ] && awk -F'\t' 'NR>1 {print $1, $9}' "$TSV" \| while read -r t p; do bi="$p/build-info.json"; test -f "$bi" && [ "$(jq -r .target "$bi")" = "$t" ] && [ "$(jq -r .qualification_status "$bi")" = "PASS" ]; done` | created by Plan 2 Task 2 | ⬜ pending |
| 03-02-03 | 02 | 2 | VERI-01, VERI-02, VERI-03 (D-03, D-04, D-05, D-08) | T-03-01, T-03-02 | jq-semantic acceptance against each cited evidence file; all 9 headings + 5 targets + 7 residuals + 3 requirement IDs + 5 gap columns; no `/latest/` citations; no unfilled placeholders; no FlexLM tokens | doc-structure | 9 heading greps pass AND all 5 target names, 7 residuals, 3 VERI-IDs, 5 gap-matrix column headers present AND `! grep -qE '/latest/(build-info\|qualification-results)' 03-sign-off.md` AND `! grep -qE 'SERVER [a-z0-9]\|FEATURE [A-Z0-9]{3,}\|INCREMENT [A-Z]' 03-sign-off.md` AND `! grep -qE '<[^>/][^>]*>' 03-sign-off.md` (no unfilled `<run_id>`/`<N>` placeholders; allows `<br/>` and similar) AND the jq-semantic loop from 03-02-02 still returns 0 | created by Plan 2 Task 3 | ⬜ pending |
| 03-02-04 | 02 | 2 | VERI-03 (D-09) | — | `.planning/LESSONS-LEARNED.md` seeded; 4+ lessons; unified prepend-immutable policy stated (no "append-only + PREPEND" contradiction); no decision-ID recap bullets | doc-structure | `grep -q '^## Phase 3' .planning/LESSONS-LEARNED.md` AND `grep -cE '^### L3-' .planning/LESSONS-LEARNED.md` >= `4` AND `grep -qiE 'run-id.*collision\|latest.*symlink\|Xilinx-thematic' .planning/LESSONS-LEARNED.md` AND `grep -q 'PREPENDED' .planning/LESSONS-LEARNED.md` AND `grep -qE 'immutable\|IMMUTABLE' .planning/LESSONS-LEARNED.md` AND `[ "$(grep -cE '^- D-0[1-9]:' .planning/LESSONS-LEARNED.md)" -eq 0 ]` | created by Plan 2 Task 4 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No test file creation needed — Plan 1 and Plan 2 both rely on inline shell/grep/jq validation.
- [x] No framework install needed — `nix`, `jq`, `grep`, `awk`, `flock`, `podman`, `curl` are in the dev shell or on the host. Plan 2 Task 1 preflight validates their presence up front via `command -v`.
- [x] `bash -n` syntax check available on the host for D-07's `03-reproduce.sh` (no install).
- [x] Plan 1 depends on `git diff --name-only 84b8803..HEAD -- <scope>` returning the 32-entry file list reproducibly — verified in research pass; the allowlist is checked in by reference at plan-authoring time.

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
- [x] Reviews-pass concerns #1–#9 reflected in updated acceptance commands (jq-semantic for 03-02-03; manifest path for 03-02-02; preflight scope for 03-02-01; scope count 32 for 03-01-01; unified policy for 03-02-04)

**Approval:** populated at plan-authoring time; awaiting task execution.
</content>
</invoke>
