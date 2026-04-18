---
phase: 3
reviewers: [gemini, codex, opencode]
reviewed_at: 2026-04-18
plans_reviewed: [03-01-PLAN.md, 03-02-PLAN.md]
self_cli_skipped: claude (running inside Claude Code)
---

# Cross-AI Plan Review — Phase 3: Quartus Verification & Sign-Off

Three independent AI systems reviewed the Phase 3 plan set. Their raw
feedback is preserved verbatim below, followed by a consensus synthesis
grouping shared concerns by severity.

Reviewers:
- **Gemini** (Google Gemini CLI)
- **Codex** (OpenAI `gpt-5.4` via Codex CLI)
- **OpenCode** (GitHub Copilot `gpt-5.3-codex` via OpenCode CLI)

Claude CLI was skipped because this workflow is running inside Claude
Code — reviewing ourselves would not add independence.

---

## Gemini Review

# Cross-AI Plan Review: Phase 3 — Quartus Verification & Sign-Off

## Summary
The plan set for Phase 3 is exceptionally robust, transforming a potentially subjective "sign-off" into a data-driven, reproducible process. It leans heavily on the existing `nix`-based certification stack and correctly identifies the "meta" nature of this phase (orchestration and authoring) rather than HDL implementation. The decision to separate the Xilinx-thematics audit (Plan 1) from the regression execution (Plan 2) is tactically sound, ensuring that qualitative intent-preservation (Class A/B findings) is documented alongside quantitative pass/fail results.

## Strengths
- **Minute-Granularity Collision Guard:** The plan explicitly identifies and mitigates the high-risk `qh_build_run_id` collision bug (Pitfall 2) by verifying five distinct run-id directories after the aggregate run.
- **Surgical Audit Scope:** Plan 1 restricts the Xilinx audit to a specific 31-file list derived from the Phase 2 merge commit, effectively filtering out noise from golden files and Python infrastructure.
- **Strict Citation Policy (D-04):** The enforcement of full run-id strings over the fragile `latest` symlink ensures the sign-off record remains durable even after subsequent runs or artefact rotation.
- **Traceability Continuity:** The carry-forward of Phase 1 and 2 residuals (HR-01, LCU-03, etc.) ensures that unverified "parser-sensitive" logic remains on the maintainer's radar even if it passes functional simulation in Questa.
- **Executable Documentation (D-07):** `03-reproduce.sh` bridges the gap between a prose sign-off doc and a black-box command, giving the maintainer a clear path to re-verify the branch.

## Concerns
- **Brittle T2 Audit Heuristic (Plan 1):** The grep for explicit `input` keywords (Theme T2) relies on a hardcoded list of return types `(string|int|bit|logic|builder|test|testcase|testsuite)`. If upstream introduces a function returning a custom class or a type not on this list, the audit will miss it. **(Severity: MEDIUM)**
- **Regression Execution Time:** Task 2 of Plan 2 is estimated at 20–60 minutes. While the plan acknowledges this, such a long turn is a failure-multiplier if an environmental issue (like a transient network failure during `pip` bootstrap) occurs 45 minutes in. **(Severity: LOW)**
- **TSV Persistence in `/tmp`:** The reproducibility script writes its state to `/tmp`. While Task 3 consumes it immediately, a maintainer re-running this manually might find `/tmp` cleared between authoring and review. **(Severity: LOW)**
- **Information Disclosure Grep (T-03-01):** The check for license disclosure is a simple grep for FlexLM keywords (`SERVER`, `FEATURE`). This may not catch all sensitive fields (e.g., vendor-defined properties or specific site IDs). **(Severity: LOW)**

## Suggestions
- **Refine T2 Grep:** Instead of a type-list, use a more generic pattern for function signatures: `grep -rnE 'function\s+([a-zA-Z_][a-zA-Z0-9_]*(\s+\[.*\])?)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)'` and then filter for those missing `input` in the parameters.
- **Permanent TSV Location:** Consider writing the reproducibility TSV to the Phase 3 directory (git-ignored if necessary) or directly to the `ARTEFACTS_ROOT` as a `sign-off-manifest.tsv` to keep evidence adjacent to the run.
- **AI Meta-Lessons:** In `LESSONS-LEARNED.md`, distinguish between project-technical lessons (L3-01..L3-04) and AI-orchestration lessons (L3-05). A maintainer may find L3-05 ("Plans are prompts") less relevant than the run-id collision details.
- **Image Digest Verification:** In the preflight check, consider capturing the container image digest (`podman image inspect --format '{{.Id}}'`) and comparing it against a known-good digest to ensure "latest" tags haven't drifted on the host.

## Risk Assessment: LOW
The overall risk is low. The plan is grounded in empirical research of the existing `scripts/certify.sh` and `flake.nix` logic. It includes defensive "FAIL FAST" preflight checks and robust jq-based verification of the final status. The largest residual risk is the qualitative audit (Plan 1) missing a subtle Xilinx-incompatible signature, but this is a maintainability risk, not a functional sign-off blocker.

---

## Codex Review

**Summary**

The two-plan decomposition is directionally sound and matches Phase 3's purpose: Plan 1 produces a bounded Xilinx-thematics audit, and Plan 2 runs/captures the sign-off evidence plus maintainer-facing documentation. The main risks are not conceptual scope creep; they are evidence integrity risks. The reproduce flow still depends on "new directories appeared in a shared artefacts root" as its source of truth, acceptance checks are often grep-presence rather than cross-validation, and Plan 1's claimed "exact 31-file scope" does not match either the table or the actual grep commands.

**Strengths**

- The phase split respects D-06: exactly two plans, with Plan 1 feeding Plan 2 rather than applying fixes.
- Plan 2 correctly centers `svunit-certify-all` instead of reimplementing pass/fail logic; `scripts/certify.sh:262-266` is the canonical PASS rule.
- The plan explicitly avoids `latest` citations, which is necessary because `scripts/certify.sh:462` updates the symlink per target.
- The sign-off doc structure covers VERI-01/02/03 well: pass matrix, command, environment, gap matrix, residuals, and next-round guidance.
- Security posture around license files is mostly correct: cite paths only, do not copy license contents into repo docs.

**Concerns**

- **HIGH:** The run-id collision mitigation is detection-only and recovery is internally inconsistent. `03-reproduce.sh` derives evidence using `comm -13 "$BEFORE" "$AFTER"` and expects exactly 5 new dirs (`03-02-PLAN.md:403-404`, `436-439`). If collision happens, Task 2 says to possibly "write a manual TSV" (`03-02-PLAN.md:512-515`), but then forbids manually constructing the TSV (`03-02-PLAN.md:534`). This can block sign-off or produce undocumented recovery behavior.

- **HIGH:** Shared artefacts root and `/tmp` introduce evidence mix-up risk. The reproduce script snapshots a shared directory with no lock (`03-02-PLAN.md:389-404`), while Task 3 reads the "most recent" `/tmp/svunit-reproduce-runids.*.tsv` (`03-02-PLAN.md:560`, `701`). A concurrent run or stale TSV could be consumed. This is especially relevant because the trust boundary explicitly says the artefacts root is shared (`03-02-PLAN.md:843-847`).

- **MEDIUM:** Plan 1's scope is inconsistent. It says "31 total" (`03-01-PLAN.md:187`) but the table contains 33 rows, including `src/experimental/sv/testcase.svh (DELETED)` and host/test rows. The actual greps use broad directories (`svunit_base/`, `src/experimental/`, `src/testExperimental/`) at `03-01-PLAN.md:246-271`, not the exact file list. This conflicts with the "no scope drift" claim and will include files such as `svunit_base/uvm-mock/svunit_uvm_test.sv`, which is mentioned as a T3 anchor (`03-01-PLAN.md:137-140`) but not listed in scope.

- **MEDIUM:** Plan 1's audit greps are too weak for the stated guarantee "every Phase-2-imported file region" (`03-01-PLAN.md:19`). T1 scans current tree typedefs, not the Phase 2 diff (`03-01-PLAN.md:249-252`). T2 only catches single-line added `function` declarations lacking literal `input` (`03-01-PLAN.md:258-263`), missing multiline signatures, extern declarations, tasks, macro-generated signatures, and non-primitive argument types.

- **MEDIUM:** Acceptance checks are mostly presence checks, not evidence validation. Plan 1's automated verify only checks headings and a hash (`03-01-PLAN.md:322-323`), not that every raw grep hit has a classified row. Plan 2's sign-off doc verify greps headings/strings (`03-02-PLAN.md:715-716`) and counts `| PASS |` rows (`03-02-PLAN.md:727`), but does not compare the Pass Matrix against the TSV or run `jq` on each cited `build-info.json`.

- **MEDIUM:** `EXPECTED_TARGETS` is declared but unused (`03-02-PLAN.md:344-350`). The script checks only `distinct_targets == 5` (`03-02-PLAN.md:423`, `441-443`), not that the exact five expected target names are present. The automated verifier has the same gap (`03-02-PLAN.md:537`).

- **MEDIUM:** `03-reproduce.sh` assumes required host tools but does not preflight them. It uses `jq`, `awk`, `comm`, `tee`, `podman`, and `nix`; only the flake visibility check indirectly tests `nix` (`03-02-PLAN.md:385-387`). The container flow also fetches `get-pip.py` and installs packages over the network in `scripts/certify.sh:153-160`, but Plan 2 has no network/offline failure handling.

- **LOW:** Required summary deliverables are not in `files_modified` or acceptance criteria. Plan 1 asks for `03-01-SUMMARY.md` (`03-01-PLAN.md:381-388`), and Plan 2 asks for `03-02-SUMMARY.md` (`03-02-PLAN.md:881-892`), but neither appears in the frontmatter modified-file lists (`03-01-PLAN.md:7-8`, `03-02-PLAN.md:8-11`).

- **LOW:** The "no source files modified" check uses `git diff ... HEAD` (`03-01-PLAN.md:335`), which will fail in a dirty worktree even if the executor did not touch source. It should compare a pre-task snapshot to a post-task snapshot.

- **LOW:** The artefacts-root preflight is stricter than the tool. Plan 2 requires the root already exists (`03-02-PLAN.md:304-306`), while `scripts/certify.sh` does `mkdir -p "${OUTPUT_DIR}"` (`scripts/certify.sh:121-122`). If the root is pruned but the parent is writable, the plan blocks unnecessarily.

**Suggestions**

- Replace the run-id capture model with a unique, deterministic sign-off session. Best option: have `03-reproduce.sh` run each per-target app itself with a unique `--output-dir "$ARTEFACTS_ROOT/${STAMP}--${target}"`, then write TSV from those exact dirs. If `svunit-certify-all` must be exercised, run it separately as a smoke, but do not use shared "new dirs" as the only evidence source.

- Add a lock around the shared artefacts root, for example `flock "$ARTEFACTS_ROOT/.svunit-signoff.lock" ...`, or write session state under a unique phase-dir path. Store the TSV in the phase directory, not only `/tmp`, or at least copy the final TSV path into `03-02-SUMMARY.md`.

- Use `EXPECTED_TARGETS` for exact validation:
  ```bash
  for t in "${EXPECTED_TARGETS[@]}"; do
    awk -F'\t' -v t="$t" 'NR>1 && $1 == t {found=1} END {exit !found}' "$OUT"
  done
  ```
  Also validate each row has `tests_passed > 0`, `tests_failed == 0`, `tests_errors == 0`, and `run_id == basename(evidence_dir)`.

- Strengthen Task 3 verification by deriving the Pass Matrix from the TSV and then checking every cited evidence file:
  ```bash
  awk -F'\t' 'NR>1 {print $1, $2}' "$TSV" |
  while read -r target run_id; do
    bi="$ARTEFACTS_ROOT/$run_id/build-info.json"
    test -f "$bi" &&
    test "$(jq -r '.target' "$bi")" = "$target" &&
    test "$(jq -r '.qualification_status' "$bi")" = PASS
  done
  ```
  Add `! grep -qE '<[^>]+>' 03-sign-off.md` to catch unfilled placeholders.

- Fix Plan 1 scope before execution: either make the table truly 31 files or update the count to 33, and pass an explicit allowlist to greps rather than broad directories. If `svunit_base/uvm-mock/svunit_uvm_test.sv` is part of T3, add it to the scope list.

- For Plan 1, split "raw grep output" from "classified findings" and add a verifier that every raw hit appears in a findings table. At minimum, require no remaining `<N_A>` placeholders and require `Theme outcome` for all four themes.

- Add `command -v jq awk comm tee podman nix git` preflight checks to `03-reproduce.sh`. Consider an explicit network preflight or at least a documented failure mode for `bootstrap.pypa.io`/pip access.

- Add `03-01-SUMMARY.md` and `03-02-SUMMARY.md` to the relevant `files_modified` lists and acceptance criteria, or remove them from `<output>` if they are not real deliverables.

- Make `LESSONS-LEARNED.md` append/prepend policy more operational: "new sections may only be inserted above the previous newest `## Phase` section; existing lesson IDs are immutable." That avoids the contradiction between "append-only" and "PREPEND".

**Risk Assessment**

**MEDIUM** overall. The plan set covers the right requirements and is well-scoped, but the current evidence-capture and acceptance checks are not robust enough for a sign-off artifact until the shared-root/run-id handling and cross-validation checks are tightened.

---

## OpenCode Review

## Summary
The plan set is thorough and strongly evidence-driven, but it is also brittle in a few key operational places: it over-couples deliverable creation to environment readiness, has several grep-based acceptance checks that can pass/fail for formatting reasons rather than correctness, and leaves concurrency/permissions edge cases under-specified for the shared artefacts root. It likely delivers VERI-01/02/03 in a clean environment, but it needs hardening around failure paths and reproducibility mechanics to avoid "process green, evidence shaky."

## Strengths
- Clear 2-plan decomposition matches D-06 and avoids major scope drift.
- Strong traceability to prior artifacts (`01-human-review.md`, `02-decision-ledger.md`, merge-base `84b8803...`, merge commit `27232c2`).
- Good explicit handling of known risk: minute-granularity run-id collisions and `latest` symlink instability.
- Plan 2 includes a concrete reproducibility artifact (`03-reproduce.sh`) and ties it to sign-off evidence generation.
- Requirement coverage is explicit and mapped to concrete outputs (pass matrix, gap matrix, residuals, command path, forward-looking section).
- Security hygiene is considered (license path-only citation, no embedding license payload).

## Concerns
- **[HIGH] Environment-gated deliverable deadlock:** Plan 2 Task 1 says "fail task and do not proceed" if preflight fails, before authoring `03-reproduce.sh`. That can block required artifact creation (D-07) due transient environment issues unrelated to script authoring.
- **[HIGH] Shared artefact root race/concurrency risk not fully controlled:** `comm -13 BEFORE AFTER` in `03-reproduce.sh` assumes only this run writes to `ARTEFACTS_ROOT`. Concurrent writers can produce >5 new dirs and force false failure (or contaminate TSV).
- **[MEDIUM] Scope count inconsistency in Plan 1:** "31 files" does not match the enumerated table (it appears larger), which undermines audit boundary confidence and reproducibility.
- **[MEDIUM] Grep heuristics may miss real cases:**
  - T2 detection (`git diff ... | grep '^\+.*function' | grep -v 'input '`) misses multiline signatures and non-added lines changed by context.
  - T1 negative typedef grep is syntax-fragile for more complex typedef forms.
- **[MEDIUM] Acceptance criteria are formatting-fragile:** checks like `grep -cE '\| PASS \|' == 5` and heading-string exact matches may fail on harmless markdown formatting changes.
- **[MEDIUM] Hidden writeability assumption:** preflight checks `test -d "$ARTEFACTS_ROOT"` but not write permissions (`-w`) or available space; run may fail late.
- **[LOW] Tooling assumptions in checks:** `nix flake show | grep -c 'svunit-certify' >= 6` is output-format dependent and can break with Nix output changes.
- **[LOW] Lessons file policy contradiction:** "append-only" while also saying future phases "PREPEND new sections." Those are opposing mechanics and need one canonical rule.

## Suggestions
- Decouple script creation from environment checks:
  - Author and validate `03-reproduce.sh` first (`bash -n`, executable, static lint),
  - Then run host preflight and execution as separate task outcome states.
- Harden `03-reproduce.sh` against shared-root concurrency:
  - Add a run manifest keyed by `svunit_commit` + execution timestamp,
  - Filter candidate dirs by `build-info.json.svunit_commit == current HEAD`,
  - Validate expected target set by exact membership, not only count/distinctness.
- Replace brittle `nix flake show` grep checks with structural eval (e.g., `nix eval` on app attrs) for deterministic preflight.
- Tighten Plan 1 scope declaration:
  - Fix the file-count mismatch,
  - Keep one authoritative machine-readable list in the audit report to avoid drift.
- Improve T2 audit coverage:
  - Add a parser-tolerant check for multiline function signatures (or scan full files in changed paths, not only added diff lines).
- Strengthen artefact-root preflight:
  - Check `test -w "$ARTEFACTS_ROOT"` and maybe a minimal write/remove probe in a temp subdir.
- Make acceptance checks semantic-first:
  - Prefer `jq`-based validation over markdown text grep for status and row counts.
- Resolve LESSONS policy wording:
  - Choose one: "prepend new sections" (reverse-chronological) **or** "append-only" (chronological), and enforce consistently.

## Risk Assessment
**Overall risk: MEDIUM.**
The plans are well-structured and likely to work in ideal conditions, but current failure-mode handling and evidence extraction are brittle enough that environmental variance or concurrent artefact writes could cause false negatives or ambiguous sign-off evidence.

---

## Consensus Summary

### Agreed Strengths (2+ reviewers)

- **Two-plan decomposition respects D-06.** All 3 reviewers call out the clean audit-vs-execution split.
- **Run-id collision awareness is correctly surfaced.** All 3 acknowledge the `qh_build_run_id` minute-granularity risk is named and guarded.
- **Strict `latest` prohibition (D-04) is grounded in code behavior.** All 3 endorse the explicit run-id citation rule.
- **Traceability to prior phases is strong.** Codex + OpenCode cite the HR/LCU residual preservation and merge-base pinning.
- **Executable reproducibility bridges prose and command.** All 3 credit `03-reproduce.sh` as the right idea.
- **License-disclosure security hygiene is path-only.** Gemini + Codex + OpenCode agree this is correctly framed.

### Agreed Concerns (highest priority — raised by 2+ reviewers)

**HIGH severity (evidence integrity — blockers if unaddressed):**

1. **Shared-root concurrency / race risk in `03-reproduce.sh`.** Codex (HIGH) + OpenCode (HIGH) + Gemini (LOW echo via TSV-persistence concern).
   - `comm -13 BEFORE AFTER` assumes sole writer to `ARTEFACTS_ROOT`. A concurrent run (maintainer, CI, sibling session) produces >5 new dirs → false failure or TSV contamination.
   - Recommended fix set: (a) run the 5 per-target apps with explicit unique output-dir rather than snapshotting the shared root; (b) add `flock` around the shared root; (c) filter candidate dirs by `build-info.json.svunit_commit == HEAD` so even concurrent non-sign-off runs are naturally excluded.

2. **Run-id collision recovery is detection-only and internally contradictory.** Codex (HIGH) — flags that Plan 2 Task 2 both suggests "write a manual TSV" (l. 512-515) and forbids "manually constructing the TSV" (l. 534). The plan has no positive recovery path; today a minute-collision → stalled sign-off.
   - Recommended: unique per-target output-dirs eliminate the collision class entirely; retain the count guard as defense in depth.

**MEDIUM severity (raised by 2+ reviewers):**

3. **Plan 1 scope count mismatch (31 vs 33).** Codex + OpenCode — the narrative says 31 files but the table enumerates 33 (incl. `testcase.svh (DELETED)` and host/test rows). The actual grep commands use broad directory globs (`svunit_base/`, `src/experimental/`), not the enumerated list.
   - Recommended: reconcile count + make greps read an explicit file-allowlist, not directory globs.

4. **Xilinx-thematics grep heuristics are too weak.** Codex + OpenCode + Gemini — T1 scans current tree typedefs (not the Phase 2 diff); T2 catches only single-line added `function` declarations and hardcodes a return-type list that will miss custom classes/multiline/extern/task/macro-generated signatures.
   - Recommended: scan changed paths rather than added diff lines; generalize T2's function-signature regex and filter for missing `input`; T1 should diff-against-baseline, not scan the current tree.

5. **Acceptance criteria are formatting-fragile presence checks, not evidence validation.** Codex + OpenCode — `grep -cE '\| PASS \|' == 5` and heading string greps can flake on harmless markdown drift; no cross-check between Pass Matrix and TSV; no `jq` verification of each cited `build-info.json`.
   - Recommended: pivot to `jq`-driven semantic checks against the cited evidence files (Codex provides a concrete awk+jq loop).

6. **Preflight misses tool + permission + offline dependencies.** Codex + OpenCode — no `command -v jq awk comm tee podman nix git` check; no `test -w "$ARTEFACTS_ROOT"`; no offline/network handling for `scripts/certify.sh` bootstrap step (`bootstrap.pypa.io`, pip install).
   - Recommended: front-load `command -v` + `test -w` probes; document offline failure mode.

**LOW severity (unanimous or dual):**

7. **`LESSONS-LEARNED.md` policy contradicts itself** — Codex + OpenCode — "append-only" + "Phase 4+ PREPEND new sections" are opposing mechanics.
   - Recommended: adopt a single wording: *"new `## Phase N` sections are prepended above the previous newest phase section; existing lesson IDs are immutable — no section may be deleted or re-ordered."* (Content is append-only within a section; overall file is reverse-chronological by prepend.)

8. **Timestamped intermediate state in `/tmp` is fragile.** Gemini + Codex — `/tmp/svunit-reproduce-runids.*.tsv` can be pruned between Task 2 and Task 3, and Task 3 picks "most recent" by `ls -t` which risks stale-file capture.
   - Recommended: write TSV to the phase directory (e.g., `03-sign-off-manifest.tsv`) and reference that exact path in Task 3.

### Divergent Views

- **Overall risk level:** Gemini says **LOW**; Codex + OpenCode say **MEDIUM**.
  - Why it matters: Gemini frames the plan as empirically grounded and defensively preflighted, weighing the *conceptual design* positively. Codex + OpenCode dig into the *shared-root evidence mechanics* and find real operational brittleness that doesn't surface in a clean single-user run. In a shared-artefacts environment (which this project explicitly is per CONTEXT.md), Codex + OpenCode's framing is more accurate — but in a single-maintainer clean run, Gemini's framing holds.
  - Take it as: **LOW for happy path, MEDIUM for shared-environment + concurrent activity.** Both are correct with different priors.

- **Gemini raises container-image-digest drift** (not raised by Codex or OpenCode): `podman image inspect --format '{{.Id}}'` pinning against a known-good digest to guard against `:latest` container tag drift. Worth considering as a follow-up hardening, though the current flake pins specific image tags.

- **Gemini suggests splitting AI-orchestration lessons (L3-05 "Plans are prompts") from project-technical lessons** in `LESSONS-LEARNED.md`. Codex + OpenCode do not address — this is a stylistic preference that has merit.

### Recommended Next Action

Apply the following targeted revisions via `/gsd-plan-phase 3 --reviews` (in priority order):

1. **Replace shared-root snapshotting with explicit unique per-target output-dirs** (HIGH — addresses concerns #1 and #2 simultaneously).
2. **Reconcile Plan 1 scope count and switch greps to an explicit file allowlist** (MEDIUM — concern #3).
3. **Pivot acceptance criteria to `jq`-driven semantic validation of cited evidence** (MEDIUM — concern #5, with Codex's concrete awk+jq loop as a starting template).
4. **Strengthen T1/T2 grep heuristics** to diff-against-baseline and handle multiline signatures (MEDIUM — concern #4).
5. **Add `command -v` + `test -w` + offline-handling preflight** to `03-reproduce.sh` (MEDIUM — concern #6).
6. **Resolve LESSONS-LEARNED wording contradiction and move intermediate TSV out of `/tmp`** (LOW — concerns #7 and #8; opportunistic).
7. **Add `03-01-SUMMARY.md` / `03-02-SUMMARY.md` to `files_modified`** (LOW — Codex only, but an easy correctness fix).

Skip for now (unless maintainer requests):
- Container image digest pinning (Gemini only, and current flake pins tags).
- Splitting AI-orchestration lessons into a separate subsection (Gemini only, stylistic).

To incorporate this feedback into the plans: `/gsd-plan-phase 3 --reviews`
