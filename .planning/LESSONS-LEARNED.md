# Lessons Learned

Project-level, cross-phase reusable lessons.

## How To Use This File

- Each phase has one `## Phase N` section. Sections are ordered reverse-chronological: newest phase at the top.
- **Section policy:** New `## Phase N` sections are PREPENDED above the previous newest phase section. Existing lesson IDs (e.g. `L3-01`, `L3-02`) are IMMUTABLE — no section may be deleted, re-ordered, or retro-edited after the phase ships. Content within a section is append-only during that phase's authoring; once the phase ships, the section is frozen.
- Each entry captures a **non-obvious reusable lesson** — not a decision recap (CONTEXT.md does that).
- Lessons are for future-maintainer value: write each one as if the reader has no Phase-N context and will benefit from it on a totally different task.
- Cite sources: reference the artefact, file, or commit that revealed the lesson.

---

## Phase 3 — Quartus Verification & Sign-Off (2026-04-18)

### L3-01: Run-id minute collision risk in `qh_build_run_id` — eliminate at the caller, not the tool

**Lesson:** Qualification tooling that derives the run-id directory from `date -u +"%Y%m%d-%H%M"` (minute granularity) has no built-in uniqueness guard. When an aggregator runs `M` targets sequentially and two of them happen to start (or complete, depending on when the tool stamps the run-id) in the same UTC minute, their evidence dirs collide and the second silently overwrites the first. A safer pattern than patching the tool is to bypass the tool-side run-id entirely: run each target into a caller-supplied unique `--output-dir` of the form `$ARTEFACTS_ROOT/${SESSION_STAMP}--${target}` where `SESSION_STAMP` is `YYYYMMDD-HHMMSS-<8-char-hex>`. The tool's internal run-id stays informational (it still lands inside `build-info.json`), but the directory on disk is deterministic per caller-session per target. `scripts/certify.sh:121` already honors `OUTPUT_DIR="${OUTPUT_DIR:-$ARTEFACTS_ROOT/${QH_RUN_ID}}"`, so the unique-dir pattern is a zero-cost override. `03-reproduce.sh` demonstrates both forms — `nix run .#app -- --output-dir PATH` (preferred after commit `46b3307`) and `OUTPUT_DIR=PATH nix run ...` (env fallback).

**Evidence:** `scripts/qualification-helpers.sh:qh_build_run_id --no-gpu-suffix`; `scripts/certify.sh:118-131`; `03-reproduce.sh` SESSION_STAMP + per-target OUTDIRS; `03-REVIEWS.md` HIGH concern #1 (shared-root concurrency).

**Generalization:** Any timestamp-derived ID needs either finer granularity, a tool-side uniqueness guard, OR a caller-provided unique directory. For existing tooling that won't change, the third option is the cheapest fix because the caller is the one who knows how many concurrent targets it's driving.

**Applicability:** any cross-target qualification pipeline whose per-run directory is timestamp-derived.

### L3-02: The `latest` symlink is per-target, not per-sign-off — never cite it

**Lesson:** When an aggregator runs `M` targets sequentially and each per-target run ends with `qh_update_latest_symlink`, the final `latest` points at the LAST target run — not the sign-off session as a whole. Worse: any subsequent unrelated target run (a maintainer smoke-test, CI, an adjacent session) moves `latest` again. Citations using `latest/` in sign-off documents rot the moment another target runs, even within the same sign-off session. D-04's rule "sign-off doc cites explicit run-ids; never `latest`" is grounded in this behavior, and Phase 3's `03-sign-off.md` cites every evidence path by full session-stamped directory name to make the citations immutable against future non-sign-off activity in the artefacts root.

**Evidence:** `scripts/certify.sh:462` → `qh_update_latest_symlink`; the live artefacts root always showed `latest -> <last-verilator-run>` after every end-to-end sign-off attempt during Phase 3 development; `03-CONTEXT.md` D-04; `03-sign-off.md` Pass Matrix rows cite `${SESSION_STAMP}--${target}/build-info.json`, not `latest/...`.

**Generalization:** "latest"-style aliases are maintenance conveniences, not citation anchors. Any document claiming durable evidence must cite by a full, immutable, caller-owned identifier. Treat maintenance aliases as inherently mutable; treat caller-owned paths as the stable surface.

**Applicability:** sign-off docs, audit reports, compliance records, CI pass-log references, build provenance documents, anything that claims "on date D, run R produced output O".

### L3-03: Xilinx-thematic audit heuristics (T1-T4) — diff-against-baseline + file allowlist

**Lesson:** For auditing an upstream merge against fork-specific SystemVerilog conventions, four diff-against-baseline greps reliably surface candidates — but the greps must iterate an explicit file allowlist and diff against the merge-base, not scan the current tree. Plan 1 over a 32-file allowlist showed these heuristics work cleanly (0 class-A + 0 class-B + 34 class-C findings after 4 themes):

- **Parser-safe queue typing (T1):** `git diff $MERGE_BASE..HEAD -- "${AUDIT_FILES[@]}" | grep -E '^\+.*typedef\s+\S+\s+\S+\[' | grep -v '\[\$\]'` — new typedefs lacking `[$]`. Prior-art anchor is the marker comment `// This needs to be declared as a dynamic array[$] ...` — catching a POSITIVE grep on the comment confirms fork intent was preserved.
- **Explicit `input` signatures (T2):** `git diff $MERGE_BASE..HEAD -- "${AUDIT_FILES[@]}" | grep -E '^\+.*function[[:space:]]+.*\([^)]+[^)[:space:]]' | grep -vE 'input[[:space:]]' | grep -v '<<SLL-FIX>>'` — new function signatures (restricted to non-empty arg lists) lacking `input` and not carrying the `<<SLL-FIX>>` marker. Complemented by a parallel `task` scan and a multi-line awk function-block scan because SV signatures can span lines.
- **`XILINX_SIMULATOR` ifdef guards (T3):** `git diff $MERGE_BASE..HEAD -- "${AUDIT_FILES[@]}" | grep -E '^-' | grep XILINX_SIMULATOR` — any REMOVED guard is the anti-pattern. A current-tree scan would miss the deletion signal.
- **xsim runtime flags (T4):** presence grep on `bin/runSVUnit` and `bin/cleanSVUnit` for LCU-01 markers (`xvlog --relax`, `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps`, `xsim.dir`, `xsim*.*`, `xelab*.*`, `xvlog.pb`) — here a current-tree positive grep is correct because the flags must be present.

The file-allowlist discipline matters: globs like `svunit_base/**` pull in `.gold` fixtures and pre-existing fork files (e.g. `svunit_base/uvm-mock/svunit_uvm_test.sv` — a T3 ANCHOR, not a Phase 2 import). An explicit `AUDIT_FILES` bash array, locked once from `git diff --name-only $MERGE_BASE..HEAD -- <scope>`, makes scope-drift greppable: any findings row outside the array fails an acceptance check. Plan 1 used a 32-file allowlist (31 live + 1 deleted).

**Evidence:** `.planning/phases/03-quartus-verification-sign-off/03-xilinx-thematics-audit.md` §Theme T1-T4; `03-RESEARCH.md` §Focus Area 1 + §Focus Area 5; `03-REVIEWS.md` concerns #3 + #4 (allowlist, diff-against-baseline); Plan 1 SUMMARY: 0/0/34 A/B/C counts confirm the heuristics are reusable.

**Generalization:** For any "fork-specific convention preserved across an upstream merge" audit: (a) enumerate prior-art markers in-tree, (b) for each convention pick whether absence-of-marker or presence-of-anti-pattern is the probe, (c) always diff against merge-base — not the current tree — for deletion-sensitive themes, (d) iterate an explicit file allowlist, never a directory glob. The allowlist catches absence (something NOT in the glob that should be) as easily as presence.

**Applicability:** any future upstream catch-up where fork intent is documented in prior-art markers. Reusable for theme-driven code audits more broadly (dependency audits, security reviews, compliance checks).

### L3-04: Questa 2025.1 migrated to SALT licensing — `SALT_LICENSE_SERVER` replaces `LM_LICENSE_FILE`

**Lesson:** Questa 2025.1 (the simulator shipped in the Quartus Pro 25.1 sim-only image) migrated to SALT v2.4.2.0 licensing. The new reader is the `SALT_LICENSE_SERVER` env var (semicolon-delimited for multi-value). The deprecated `LM_LICENSE_FILE` and `MGLS_LICENSE_FILE` env vars are documented as going away in future releases; Questa 2025.1 already ignores them for Questa licensing. Questa 2023.3 (in the 23.4 image) still reads `LM_LICENSE_FILE`, which is why the 23.4 targets stayed green during the Phase 3 regression while the 25.1 sim-only targets failed with `Invalid license environment. Application closing.` (vsim exit code 3) AFTER `vlog`/`vopt` had already succeeded. The failure surfaced deep into pytest — `buildSVUnit` completed, compile succeeded, then `vsim` at simulation time bailed because no license could be checked out. Two-env-var fix: set BOTH `LM_LICENSE_FILE` AND `SALT_LICENSE_SERVER` to the same license-file path, unconditionally. Older Questa ignores the unknown `SALT_LICENSE_SERVER`; newer Questa ignores the deprecated `LM_LICENSE_FILE`. No per-version branching needed — the fix is idempotent. Applied to both `scripts/certify.sh` (non-interactive certify path) and `scripts/quartus-shell.sh` (interactive REPL path) so either entry point works. This was unblocked only after a sibling Perl-module fix (`libperl5.38t64` install for `IO::Dir`) — two stacked bugs with the Perl fault masking the licensing fault in the first regression run.

**Evidence:** `.planning/debug/resolved/quartus-25-1-sim-only-pytest-subprocess-failure.md` (full debug session); commit `292a8a0` (`fix(certify): set SALT_LICENSE_SERVER for Questa 2025.1 licensing`); commit `0680482` (`fix(certify): install full perl metapackage, not just perl-modules` — the upstream stacked bug); Phase 3 sign-off §Environment note; 25.1 sim-only qrun/modelsim went from 2/46 + 2/44 PASS to 48/0/3 + 46/0/3 PASS after the two fixes.

**Generalization:** When a simulator / EDA tool vendor deprecates a licensing env var across a major bump, the "old var is silently ignored by the new version" failure mode can surface as a subprocess error arbitrarily deep in the test harness (post-compile, at simulation runtime). Set BOTH old and new env vars side-by-side; each version reads the one it knows and ignores the other cleanly. When sign-off breaks after a container / tool version bump, license env-var migration is a high-probability root cause — faster to check upfront than to debug subprocess stacks.

**Applicability:** Any future Quartus / Questa major bump (≥26), any other EDA tool that historically used FlexLM and may migrate to vendor-owned licensing (Xilinx / AMD has done similar migrations historically). Also applies to any long-running bash pipeline that spawns licensed tools late in the run — the failure may look like "pytest broken" when it's really "license env var deprecated".

### L3-05: Preflight covers tools AND permissions AND network, not just domain inputs

**Lesson:** A "preflight" that only checks for domain-specific inputs (license files, container images) misses the three classes that break reproducibility most often in shared environments:

1. **Host tools:** `command -v jq awk flock podman nix git curl` before doing anything. A missing host tool fails mid-regression with a cryptic shell error.
2. **Write permission:** `test -w $ARTEFACTS_ROOT` — a read-only mount passes `test -d` but fails an hour into the regression when the first target tries to create its output-dir.
3. **Network reachability for hidden transitive fetches:** `scripts/certify.sh:153-160` downloads `get-pip.py` from `bootstrap.pypa.io` inside the container on EVERY run. A firewall or offline session breaks the regression silently mid-flight. `curl -Isf --max-time 10 https://bootstrap.pypa.io/get-pip.py` catches it up front.

Also worth guarding with `flock -n $ARTEFACTS_ROOT/.svunit-signoff.lock`: a second sign-off session running in parallel would produce a concurrent-writer mess. Non-blocking `flock` fails fast (better than queueing silently).

**Evidence:** `03-REVIEWS.md` concern #6 (multi-AI reviewers flagged preflight gaps); `scripts/certify.sh:121-122, 153-160`; `03-reproduce.sh` Preflight sections A/E/F plus the `flock` lock at section H.

**Generalization:** Fail-fast preflight for any reproducibility script should cover: (a) host-tool presence, (b) write-permission on every target path, (c) any hidden transitive network dependency in the tool chain, (d) concurrency guard if the tool writes to a shared filesystem. Domain-specific inputs (licenses, images, config files) are necessary but not sufficient.

**Applicability:** any reproducible-regression script that wraps a third-party tool with hidden fetches; CI sign-off workflows; qualification pipelines that share a multi-tenant artefacts archive.

### L3-06: Diff-against-baseline beats current-tree scan for fork-vs-upstream audits

**Lesson:** Research-pass heuristics for the Xilinx-thematics audit originally scanned the current tree for Xilinx signatures (e.g. "grep for `[$]` across `svunit_base/**`"). That approach double-counts prior-art fork markers on every merge: a file that carried `[$]` from the pre-merge fork still carries it after the merge, so a current-tree scan re-flags the same lines forever. The reviews pass pivoted T1 / T2 / T3 to `git diff $MERGE_BASE..HEAD -- <scope>` against the upstream-merge baseline — finds only changes introduced by THIS merge, not ambient state. Prior-art markers survive because they're not in the diff; anti-patterns show up because they are. T4 is the exception: `xsim` runtime flags are a presence-in-HEAD check (the flags must still be there), so current-tree grep is correct for T4.

**Evidence:** `03-REVIEWS.md` concern #4 (OpenCode reviewer flagged current-tree T1 + T3 would re-flag pre-existing fork markers); `03-xilinx-thematics-audit.md` theme heuristics now diff against `84b88033590a1469a238be84d8526b25a9f29d10`; Plan 1 §Summary 0/0/34 A/B/C counts are a post-pivot result.

**Generalization:** For any "what did THIS merge introduce" audit, diff against the merge-base — not the current tree. Pick the probe direction per theme: if removal is the anti-pattern, diff for removed lines; if addition is the anti-pattern, diff for added lines; if current-state is what matters (like runtime flags that must still be present), scan HEAD. A single probe-direction across all themes is wrong; per-theme probe-direction selection is right.

**Applicability:** upstream-merge audits, security diff review, compliance-baseline diffs, "what did this PR change" code review tooling.

### L3-07: Plans-are-prompts — embed interface values verbatim so the executor doesn't re-derive them

**Lesson:** For downstream executors to author maintainer-facing docs (like `03-sign-off.md`) without re-deriving inputs, the plan must embed interface values verbatim — full paths, full command strings, exact field names, exact heading order, exact grep patterns. Plan 2 embedded the 5 target names, 7 residual IDs, ARTEFACTS_ROOT path, 9-heading sign-off structure, and jq-semantic acceptance commands as an `<interfaces>` block; the executor didn't have to open `flake.nix`, `nix/registry.nix`, `02-decision-ledger.md`, or the research document to author the sign-off. Compare to a plan that says "author the sign-off doc per the conventions" — that's a scavenger hunt. Compare also to a plan that pastes the conventions verbatim — that's a prompt. The prompt is faster, less context-hungry, and less ambiguous. Acceptance commands embedded in the plan also become the executor's self-check before committing, reducing round-trips with the verifier.

**Evidence:** `03-02-PLAN.md` `<interfaces>` section (locked values, command signatures, grep patterns); each task's `<automated>` block duplicates the acceptance commands inline so the executor can run them before committing; reviews-pass concerns #5 + #8 (jq-semantic acceptance; phase-dir-resident TSV path) both manifested as precise commands in the plan, not prose recommendations.

**Generalization:** A plan that says "do X per the conventions" is a scavenger hunt. A plan that says "do X with these literal values, verified by this literal command" is a prompt. The plan-as-prompt pattern pays off in executor clarity and in reduced verifier churn. This is independent of project domain.

**Applicability:** every plan that authors structured deliverables against a known schema; any automation flow where a downstream agent needs to template against interface values.
