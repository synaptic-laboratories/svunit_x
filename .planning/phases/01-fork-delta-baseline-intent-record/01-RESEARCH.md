# Phase 1: Fork Delta Baseline & Intent Record - Research

**Researched:** 2026-04-11
**Domain:** Git ancestry verification and fork-delta classification for upstream sync
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim content below is copied from `.planning/phases/01-fork-delta-baseline-intent-record/01-CONTEXT.md`. [VERIFIED: .planning/phases/01-fork-delta-baseline-intent-record/01-CONTEXT.md]

### Locked Decisions

### Upstream Reference Resolution
- **D-01:** Treat the authoritative upstream source as `https://github.com/svunit/svunit`.
- **D-02:** Record the exact upstream target ref and resolved commit hash in the Phase 1 artifact, not just a release label.
- **D-03:** Record the parent repo URL, target release or tag name, and the exact resolved upstream commit hash together in the artifact.
- **D-04:** Record the derived fork baseline or merge-base alongside the upstream target ref.
- **D-05:** Use `v3.37.0` as the remembered fork baseline to verify against fetched upstream history.
- **D-06:** Use `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` as a user-supplied candidate marker for the first upstream commit after the fork, but verify it against fetched upstream history before relying on it.
- **D-07:** If the exact upstream target, remembered baseline, marker commit, and computed history do not agree cleanly, stop and classify the discrepancy as `human-review` instead of guessing.
- **D-08:** If Phase 1 cannot resolve a clean upstream `3.38.1` target, stop and require explicit human confirmation before proceeding.

### Delta Inventory Scope
- **D-09:** Inventory the explicit Xilinx/Vivado support commits plus later fork-only commits that touched the same files or behaviors.
- **D-10:** Treat parser-facing, static type-casting, formal-semantics, and warning-reduction edits in Xilinx-affected areas as material by default unless there is clear evidence they are purely cosmetic.
- **D-11:** Follow behavior threads across direct file overlap, command-line behavior, generated code, parser-facing syntax, and simulator-warning behavior.
- **D-12:** Include later non-Xilinx-specific fork changes in the inventory when they affect the same parser-facing or simulator-facing behavior.
- **D-13:** For every included non-Xilinx-specific fork change, record an interpretation of what the change was about so later conflicts have context.

### Intent Record Format
- **D-14:** The primary Phase 1 artifact is one master matrix or table, not per-file-only or per-commit-only notes.
- **D-15:** Each matrix row represents a logical change unit, which may correspond to one commit or several closely related edits.
- **D-16:** Each row should include at minimum: logical change id, files touched, commit(s), likely purpose or interpretation, Xilinx relevance, conflict-risk classification (`keep`, `superseded`, `rewrite`, `human-review`), and merge-handling notes.
- **D-17:** Produce a short executive summary of the main change themes alongside the master matrix.

### Human-Review Thresholds
- **D-18:** Automatically classify a logical change unit as `human-review` when history and current diff do not clearly explain the original change intent.
- **D-19:** If upstream changes the same behavior but it is unclear whether upstream fully subsumes the fork's local fix, classify that case as `human-review`.
- **D-20:** Small text diffs that may be parser-sensitive, warning-sensitive, or simulator-sensitive go to `human-review` when their intent or effect is not clearly proven.
- **D-21:** If a logical change unit spans several small commits and its interpretation is plausible but not certain, classify it as `human-review` and explain the uncertainty.

### Claude's Discretion
- Exact artifact filenames for the Phase 1 matrix and executive summary.
- The heuristic for grouping commits into logical change units, as long as the grouping remains reviewable and traceable.
- The concrete git commands and comparison workflow used to derive the merge-base and classify fork-only changes.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement descriptions below are copied from `.planning/REQUIREMENTS.md`. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Maintainer can confirm the exact upstream tag or commit to sync against for this stage and record that reference in the repo. [VERIFIED: .planning/REQUIREMENTS.md] | Pin the upstream URL, target tag object, peeled target commit, remembered tag object, peeled remembered commit, derived merge-base, and marker status in one baseline manifest. [VERIFIED: local git evidence] |
| BASE-02 | Maintainer can generate a file-backed comparison of this fork against the confirmed upstream target. [VERIFIED: .planning/REQUIREMENTS.md] | Save a master delta matrix plus raw evidence files for refs, merge-base, fork-only commits, `range-diff`, and path overlap. [VERIFIED: D-14, D-16, D-17, local git evidence] |
| BASE-03 | Maintainer can classify each fork-only change as `keep`, `superseded`, `rewrite`, or `human-review`. [VERIFIED: .planning/REQUIREMENTS.md] | Use logical change units derived from the true merge-base and attach upstream counterpart evidence before classifying. [VERIFIED: local git evidence] |
| XILX-01 | Maintainer can trace local Xilinx/Vivado-related behavior to the commits and files that introduced or adjusted it. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the large Xilinx patch as a reviewable logical unit unless later evidence proves a clean split, because it spans CLI, runtime, parser-facing SV code, and tests. [VERIFIED: local git diff for 8e7d8d3] |
| XILX-02 | Maintainer can document the intent of each material Xilinx/Vivado-related fork change in a reviewable repo artifact. [VERIFIED: .planning/REQUIREMENTS.md] | Require each matrix row to carry likely purpose, Xilinx relevance, evidence refs, and merge-handling notes. [VERIFIED: D-10, D-16, local git evidence] |
</phase_requirements>

## Summary

The authoritative upstream must be queried by URL, not by `origin`: this repo's only configured remote is the internal mirror `ssh://pub.git.i01.synaptic-labs.com/repo/pub/com/github/synaptic-laboratories/svunit_x.git`, and the local repo currently has no `v3.37.0` or `v3.38.x` tags. `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*'` resolves `v3.38.1` cleanly to tag object `e8adb554f99b579db6199b3aab547b4e68a16501` and peeled commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`; `v3.37.0` resolves to tag object `93cc95519ca2696ec31bdd80c39743f48a9075c5` and peeled commit `355c1411baf4d0233cb7862e53873ae90ec807e5`. [VERIFIED: git remote -v; git tag --list; git ls-remote upstream]

The remembered baseline does not equal the true fork point. `git merge-base c2cb87111cf93cbf0f3f485730d314dbad3cb858 8e70653e2cbfe3ebe154a863a46bf482ded4bc19` resolves to `84b88033590a1469a238be84d8526b25a9f29d10`, while `v3.37.0` peels to `355c1411baf4d0233cb7862e53873ae90ec807e5`; `v3.37.0` is an ancestor of the merge-base, but there are 44 upstream commits between them. The candidate marker `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` is real and is an ancestor of the target commit, but it is the first descendant in full ancestry order, not the first first-parent commit after the fork point; first-parent order starts at merge commit `6e179cadaa036554452f8e82e9ca9e94bf307c40`. That mismatch is exactly the kind of baseline ambiguity that should be flagged as `human-review` before Phase 2 relies on it. [VERIFIED: git merge-base; git rev-list; git merge-base --is-ancestor; git show; git ls-remote upstream]

The reusable delta inventory should start from the true merge-base, not the remembered release tag. From `84b88033590a1469a238be84d8526b25a9f29d10` to fork head `c2cb87111cf93cbf0f3f485730d314dbad3cb858`, the fork has 2 local commits touching 22 files; 8 of those files were also modified upstream by `v3.38.1`. `git range-diff` leaves the large Xilinx patch `8e7d8d35e68a2deb0923871de998b13782f5f5ec` unmatched and shows the small help-text patch `c2cb87111cf93cbf0f3f485730d314dbad3cb858` as only a partial match to upstream `93d3e7e`, so the planner should require row-level evidence before marking anything `superseded`. [VERIFIED: git rev-list --left-right --count; git diff; comm; git range-diff]

**Primary recommendation:** Use a two-layer Phase 1 output: one pinned baseline manifest with exact hashes and discrepancy flags, plus one master logical-change matrix backed by saved git evidence; classify the remembered-baseline mismatch and the marker-semantics mismatch as `human-review` immediately. [VERIFIED: BASE-01, BASE-02, BASE-03, XILX-01, XILX-02, local git evidence]

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Git CLI | 2.51.2 [VERIFIED: local env] | Resolve remote refs, derive merge-base, enumerate fork-only commits, compare patch series | `git ls-remote` lists remote refs, `git merge-base` finds best common ancestors, and `git range-diff` compares commit ranges. [CITED: https://git-scm.com/docs/git-ls-remote, https://git-scm.com/docs/git-merge-base, https://git-scm.com/docs/git-range-diff] |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `jq` | 1.8.1 [VERIFIED: local env] | Emit a small machine-readable manifest | Use if Phase 1 writes `01-upstream-baseline.json`; fall back to plain text if the planner keeps everything in Markdown. [VERIFIED: local env] |
| `rg` | 15.1.0 [VERIFIED: local env] | Fast artifact/content validation | Use for requirement checks against the matrix and evidence files. [VERIFIED: local env] |
| POSIX shell (`bash`, `sed`, `comm`) | Available [VERIFIED: environment context + local commands] | Glue commands and overlap checks | Use for replayable one-liners and saved evidence snippets. [VERIFIED: local command usage] |

### Alternatives Considered
| Instead of | Use | Tradeoff |
|------------|-----|----------|
| `origin` or local tag names | Explicit upstream URL `https://github.com/svunit/svunit.git` plus resolved hashes | Safer here because `origin` is an internal mirror and local upstream tags are absent. [VERIFIED: git remote -v; git tag --list] |
| Manual ancestry guessing from commit dates or subjects | `git merge-base` and `git rev-list` | Removes subject/date ambiguity and produces a reusable base commit. [CITED: https://git-scm.com/docs/git-merge-base] |
| Machine-parsing `git range-diff` output | Use `range-diff` as human evidence only | Git documents `range-diff` as human-readable and not textually stable across versions. [CITED: https://git-scm.com/docs/git-range-diff] |

## Architecture Patterns

### Recommended Project Structure
```text
.planning/phases/01-fork-delta-baseline-intent-record/
├── 01-upstream-baseline.json   # Pinned refs, resolved hashes, discrepancy flags
├── 01-fork-delta-matrix.md     # Executive summary + logical change units
└── evidence/
    ├── refs.txt                # ls-remote output for target and remembered tags
    ├── merge-base.txt          # merge-base and marker checks
    ├── fork-only.log           # rev-list and show summaries for fork-only commits
    ├── range-diff.txt          # upstream counterpart evidence
    └── path-overlap.txt        # overlap between local and upstream-touched files
```
A split between manifest, matrix, and raw evidence is warranted here because Phase 2 needs exact hashes for automation and human-readable intent notes for conflict resolution. [VERIFIED: BASE-01, BASE-02, BASE-03, XILX-01, XILX-02]

### Pattern 1: Pin Upstream and Baseline Before Any Classification
**What:** Resolve the official upstream tag, peeled target commit, remembered baseline tag, peeled baseline commit, derived merge-base, and marker status before looking at diffs. [VERIFIED: local git evidence]
**When to use:** First step of Phase 1, and again if the phase is re-run later. [VERIFIED: Phase 1 goal + local tag absence]
**Example:**
```bash
UPSTREAM=https://github.com/svunit/svunit.git
FORK_REF=c2cb87111cf93cbf0f3f485730d314dbad3cb858

git ls-remote --tags "$UPSTREAM" 'v3.38.1*' 'v3.37.0*'
# Verified on 2026-04-11:
# e8adb554f99b579db6199b3aab547b4e68a16501  refs/tags/v3.38.1
# 8e70653e2cbfe3ebe154a863a46bf482ded4bc19  refs/tags/v3.38.1^{}
# 93cc95519ca2696ec31bdd80c39743f48a9075c5  refs/tags/v3.37.0
# 355c1411baf4d0233cb7862e53873ae90ec807e5  refs/tags/v3.37.0^{}

MERGE_BASE=$(git merge-base "$FORK_REF" 8e70653e2cbfe3ebe154a863a46bf482ded4bc19)
git rev-list --reverse "${MERGE_BASE}..8e70653e2cbfe3ebe154a863a46bf482ded4bc19" | head -n 1
git rev-list --first-parent --reverse "${MERGE_BASE}..8e70653e2cbfe3ebe154a863a46bf482ded4bc19" | head -n 1
```
Source: local git commands plus official upstream ref resolution. [VERIFIED: git ls-remote upstream; git merge-base; git rev-list]

### Pattern 2: Derive Reusable Logical Change Units From the True Fork Point
**What:** Start from `git rev-list --reverse ${merge_base}..${fork_ref}`, then group commits into logical units by parent-child fixups, behavior thread, and simulator or parser intent rather than by file or by commit count alone. [VERIFIED: local fork range has 2 commits; 8e7d spans CLI, parser-facing SV code, runtime, and tests]
**When to use:** Immediately after baseline pinning, before any `keep`, `superseded`, `rewrite`, or `human-review` labels are assigned. [VERIFIED: BASE-02, BASE-03, XILX-01, XILX-02]
**Example:**
```bash
git rev-list --reverse 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858
git show --stat --name-only 8e7d8d35e68a2deb0923871de998b13782f5f5ec
git show --stat --name-only c2cb87111cf93cbf0f3f485730d314dbad3cb858
```
For this repo, the big Xilinx patch `8e7d8d3...` should stay one logical unit unless later evidence proves it decomposes cleanly, because it mixes `xsim` flags, dynamic-array declarations, `input` qualifiers, and `__svunit_fatal` substitutions across runtime and tests. [VERIFIED: local git diff for 8e7d8d3]

### Pattern 3: Attach Upstream Counterpart Evidence Per Logical Unit
**What:** For each logical change unit, collect three evidence views: upstream commits touching the same paths, `range-diff` comparison against the target range, and path-overlap counts. [VERIFIED: local git evidence]
**When to use:** Before choosing `superseded` or `rewrite`; `keep` is safer only when upstream overlap is absent or clearly non-subsuming. [VERIFIED: D-18, D-19, D-20]
**Example:**
```bash
git log --oneline 84b88033590a1469a238be84d8526b25a9f29d10..8e70653e2cbfe3ebe154a863a46bf482ded4bc19 -- bin/runSVUnit
git range-diff 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 \
               84b88033590a1469a238be84d8526b25a9f29d10..8e70653e2cbfe3ebe154a863a46bf482ded4bc19
comm -12 \
  <(git diff --name-only 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 | sort) \
  <(git diff --name-only 84b88033590a1469a238be84d8526b25a9f29d10..8e70653e2cbfe3ebe154a863a46bf482ded4bc19 | sort)
```
On current evidence, `c2cb871...` has a probable upstream counterpart in `93d3e7e...`, but `range-diff` marks it `!` rather than `=` because upstream also changed adjacent help text; that is enough to keep the unit reviewable even if the final classification becomes `superseded`. [VERIFIED: local git range-diff]

### Anti-Patterns to Avoid
- **Using `origin/master` as upstream:** `origin` points to the internal fork, not `svunit/svunit`. [VERIFIED: git remote -v]
- **Using `v3.37.0` as the diff base:** it is a remembered release baseline, not the current verified merge-base. [VERIFIED: git merge-base; git ls-remote upstream]
- **Treating parser-facing or warning-reduction edits as cosmetic:** the local Xilinx patch changes simulator flags, array kinds, argument directions, and fatal macros. [VERIFIED: local git diff for 8e7d8d3]
- **Parsing `range-diff` output mechanically:** Git explicitly says that output is not intended to be machine-readable. [CITED: https://git-scm.com/docs/git-range-diff]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Official upstream ref verification | Ad hoc notes from a web UI or memory | `git ls-remote --tags` and `git ls-remote --branches https://github.com/svunit/svunit.git` | It returns authoritative remote refs and commit IDs. [CITED: https://git-scm.com/docs/git-ls-remote] |
| Divergence-point inference | Date- or subject-based guessing | `git merge-base fork_ref target_commit` | Merge-base is the Git-defined best common ancestor for the two histories. [CITED: https://git-scm.com/docs/git-merge-base] |
| Patch-series correspondence | Manual subject matching | `git range-diff base..fork base..target` plus per-path logs | `range-diff` compares commit ranges by patch similarity, not just by subject. [CITED: https://git-scm.com/docs/git-range-diff] |
| Fork-only commit extraction | Hand-maintained commit lists | `git rev-list --reverse ${merge_base}..${fork_ref}` | This is replayable and survives later re-runs. [VERIFIED: local git usage] |
| Path-overlap detection | Manual diff eyeballing | `comm -12 <(git diff --name-only ...) <(git diff --name-only ...)` | Current fork delta touches 22 files, 8 of which also change upstream; the overlap should be computed, not guessed. [VERIFIED: local git diff + comm] |

**Key insight:** Phase 1 should be evidence-first and hash-first; the phase is small enough to inspect manually once the right Git primitives produce a stable baseline. [VERIFIED: local git evidence]

## Common Pitfalls

### Pitfall 1: Confusing Remembered Baseline With True Fork Point
**What goes wrong:** The planner anchors Phase 1 on `v3.37.0` instead of the verified merge-base. [VERIFIED: Phase 1 context + local git evidence]
**Why it happens:** `v3.37.0` is a real upstream tag, but the fork kept taking upstream commits after that release before diverging. [VERIFIED: git ls-remote upstream; git log 355c141..84b8803]
**How to avoid:** Record both the remembered tag and the true merge-base in the baseline manifest, and mark the mismatch `human-review`. [VERIFIED: D-05, D-07, local git evidence]
**Warning signs:** The remembered tag peels to `355c141...`, but `git merge-base fork_ref target_commit` returns `84b8803...`. [VERIFIED: git ls-remote upstream; git merge-base]

### Pitfall 2: Treating the Marker Commit as Unambiguous
**What goes wrong:** The planner assumes `dc7ed0a...` is the only correct "first upstream commit after the fork". [VERIFIED: local git evidence]
**Why it happens:** In full ancestry order the first descendant is `dc7ed0a...`, but in first-parent order the first mainline commit is `6e179ca...`. [VERIFIED: git rev-list --reverse; git rev-list --first-parent --reverse]
**How to avoid:** Store both interpretations and force `human-review` unless Phase 1 explicitly defines which marker semantics the project wants. [VERIFIED: D-06, D-07, D-18]
**Warning signs:** `git rev-list --reverse ${merge_base}..${target_commit} | head -1` and `git rev-list --first-parent --reverse ${merge_base}..${target_commit} | head -1` disagree. [VERIFIED: local git evidence]

### Pitfall 3: Dropping Small SV Changes as Cosmetic
**What goes wrong:** Small-looking edits in Xilinx-affected areas get classified as `superseded` or ignored without semantic review. [VERIFIED: Phase 1 context + local git diff]
**Why it happens:** Several local changes are superficially tidy but alter parser- or warning-sensitive constructs: `--relax`, `--debug all`, dynamic arrays `[$]`, `input` qualifiers, and `__svunit_fatal` substitutions. [VERIFIED: local git diff for 8e7d8d3]
**How to avoid:** Default parser-facing, static-casting, formal-semantics, and warning-reduction edits in Xilinx-touched areas to material, and escalate unclear cases to `human-review`. [VERIFIED: D-10, D-20, D-21]
**Warning signs:** The diff touches `bin/runSVUnit`, `svunit_base/`, or `src/experimental/sv/` but has no accompanying explanation row in the matrix. [VERIFIED: local git diff + .planning/codebase/CONCERNS.md]

### Pitfall 4: Assuming Tiny Fork Size Means Low Merge Risk
**What goes wrong:** The planner under-scopes Phase 1 because there are only two fork-only commits. [VERIFIED: git rev-list 84b8803..c2cb871]
**Why it happens:** One of the two commits spans 22 files and 8 of those files also changed upstream by `v3.38.1`. [VERIFIED: local git diff + comm]
**How to avoid:** Classify by logical change unit and overlap evidence, not by commit count alone. [VERIFIED: BASE-02, BASE-03]
**Warning signs:** A single local commit touches `bin/`, `svunit_base/`, experimental code, and tests in one sweep. [VERIFIED: local git show --stat 8e7d8d3]

### Pitfall 5: Treating `range-diff` as an Automation API
**What goes wrong:** Downstream scripts depend on the exact textual shape of `range-diff` output. [CITED: https://git-scm.com/docs/git-range-diff]
**Why it happens:** `range-diff` is highly informative, but Git documents it as porcelain output with unstable text formatting. [CITED: https://git-scm.com/docs/git-range-diff]
**How to avoid:** Save `range-diff` output as human evidence and store explicit matched commit IDs or notes in the matrix. [CITED: https://git-scm.com/docs/git-range-diff]
**Warning signs:** The plan says "parse the `!` and `=` lines" instead of "record the matched commit IDs manually". [CITED: https://git-scm.com/docs/git-range-diff]

## Code Examples

Verified patterns from official and repo sources:

### Resolve Target, Remembered Baseline, and True Merge-Base
```bash
UPSTREAM=https://github.com/svunit/svunit.git
FORK_REF=c2cb87111cf93cbf0f3f485730d314dbad3cb858

git ls-remote --tags "$UPSTREAM" 'v3.38.1*' 'v3.37.0*'
git merge-base "$FORK_REF" 8e70653e2cbfe3ebe154a863a46bf482ded4bc19
git merge-base --is-ancestor 355c1411baf4d0233cb7862e53873ae90ec807e5 84b88033590a1469a238be84d8526b25a9f29d10
```
Source: official upstream ref query plus local git history. [VERIFIED: git ls-remote upstream; git merge-base]

### Derive Marker Semantics Explicitly
```bash
MERGE_BASE=84b88033590a1469a238be84d8526b25a9f29d10
TARGET_COMMIT=8e70653e2cbfe3ebe154a863a46bf482ded4bc19

git rev-list --reverse "${MERGE_BASE}..${TARGET_COMMIT}" | head -n 1
git rev-list --first-parent --reverse "${MERGE_BASE}..${TARGET_COMMIT}" | head -n 1
```
Source: local git history. [VERIFIED: local git rev-list]

### Produce Reusable Delta Evidence
```bash
BASE=84b88033590a1469a238be84d8526b25a9f29d10
FORK=c2cb87111cf93cbf0f3f485730d314dbad3cb858
TARGET=8e70653e2cbfe3ebe154a863a46bf482ded4bc19

git rev-list --reverse "${BASE}..${FORK}"
git range-diff "${BASE}..${FORK}" "${BASE}..${TARGET}"
comm -12 \
  <(git diff --name-only "${BASE}..${FORK}" | sort) \
  <(git diff --name-only "${BASE}..${TARGET}" | sort)
```
Source: local git history and official `range-diff` semantics. [VERIFIED: local git commands; CITED: https://git-scm.com/docs/git-range-diff]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trust local tags or `origin` for upstream identity | Query `https://github.com/svunit/svunit.git` directly and record exact hashes | Required now because `origin` is the fork mirror and local upstream tags are absent. [VERIFIED: git remote -v; git tag --list] | Prevents stale or fork-local refs from contaminating Phase 1. [VERIFIED: local repo state] |
| Treat "first upstream commit after fork" as a single notion | Record both earliest full-ancestry descendant and earliest first-parent descendant | Required now because `dc7ed0a...` and `6e179ca...` differ. [VERIFIED: local git rev-list] | Makes marker semantics explicit instead of implicit. [VERIFIED: local git evidence] |
| Use `git ls-remote --heads` in examples | Prefer `git ls-remote --branches` in new commands | Git docs currently mark `--heads` as a deprecated synonym. [CITED: https://git-scm.com/docs/git-ls-remote] | Keeps the Phase 1 playbook current on modern Git. [CITED: https://git-scm.com/docs/git-ls-remote] |

**Deprecated/outdated:**
- `git range-diff` as machine-readable output: Git documents it as unstable porcelain, not a stable API. [CITED: https://git-scm.com/docs/git-range-diff]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All claims in this research were verified locally, against the official upstream repo, or against official Git docs. [VERIFIED: local git evidence; CITED: https://git-scm.com/docs/git-merge-base, https://git-scm.com/docs/git-ls-remote, https://git-scm.com/docs/git-range-diff] | N/A | N/A |

## Open Questions (RESOLVED)

1. **Baseline semantics resolved:** Phase 1 must record both the remembered release anchor and the true operational fork point, but they are not interchangeable. `remembered_baseline_tag` and `remembered_baseline_commit` preserve the user-directed `v3.37.0` reference from D-05, while `derived_merge_base` is the only commit that later diff, `range-diff`, and fork-only inventory work should use as the comparison base. This resolves the ambiguity by making the artifact carry both concepts explicitly instead of overloading one `baseline` field. [VERIFIED: git ls-remote upstream; git merge-base; D-04; D-05; D-07]

2. **Candidate-marker semantics resolved:** Phase 1 should not use a single overloaded "first upstream commit after the fork" field. Record the user-supplied `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` as the verified `candidate_marker`, record `candidate_marker_full_ancestry_first_descendant=dc7ed0a5a8b88533b52d884e2c473beb9d4ce273`, and record `candidate_marker_first_parent_first_descendant=6e179cadaa036554452f8e82e9ca9e94bf307c40` as the alternate mainline interpretation. The disagreement is no longer an open semantic question once the fields are explicit; it remains a deliberate `human-review` condition per D-07 whenever later work depends on which interpretation to privilege. [VERIFIED: local git rev-list; D-06; D-07]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Git | All Phase 1 ancestry and comparison commands | ✓ [VERIFIED: local env] | 2.51.2 [VERIFIED: local env] | — |
| GitHub upstream reachability | Official ref resolution against `https://github.com/svunit/svunit.git` | ✓ [VERIFIED: `git ls-remote --branches https://github.com/svunit/svunit.git master`] | master=`1faed0b32452e396d32a42009ae6818a1631e152` on 2026-04-11 [VERIFIED: upstream `git ls-remote`] | None; if unreachable, stop Phase 1 and flag `human-review`. [VERIFIED: D-08] |
| `jq` | Recommended JSON baseline manifest generation | ✓ [VERIFIED: local env] | 1.8.1 [VERIFIED: local env] | Use Markdown or plain text tables. [VERIFIED: local env] |
| `rg` | Recommended fast artifact validation | ✓ [VERIFIED: local env] | 15.1.0 [VERIFIED: local env] | `grep` 3.12 [VERIFIED: local env] |
| Python 3 | Not required for this phase | ✗ [VERIFIED: `command -v python3`] | — | Use shell-only workflow. [VERIFIED: local env] |

**Missing dependencies with no fallback:**
- None for the research and design path, but live access to the official upstream repo is mandatory when the baseline is captured. [VERIFIED: D-01, D-02, D-08]

**Missing dependencies with fallback:**
- Python 3 is absent here, but the recommended Phase 1 workflow does not need it. [VERIFIED: local env]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Replayable shell and git command checks created in-plan are sufficient for this documentation-heavy phase. [VERIFIED: Phase 1 scope + local env; 01-01-PLAN.md; 01-02-PLAN.md] |
| Config file | none — `01-01-01` creates `tests/test-phase1-baseline.sh` and `01-02-01` creates `tests/test-phase1-matrix.sh`. [VERIFIED: 01-01-PLAN.md; 01-02-PLAN.md] |
| Quick run command | `bash tests/test-phase1-baseline.sh refs && bash tests/test-phase1-baseline.sh graph` once `01-01-01` has landed. [VERIFIED: 01-01-PLAN.md] |
| Full suite command | `bash tests/test-phase1-baseline.sh refs && bash tests/test-phase1-baseline.sh graph && bash tests/test-phase1-matrix.sh files && bash tests/test-phase1-matrix.sh classifications && bash tests/test-phase1-matrix.sh xilinx-trace && bash tests/test-phase1-matrix.sh intent` once `01-02-01` has landed. [VERIFIED: 01-01-PLAN.md; 01-02-PLAN.md] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BASE-01 | Official target ref, remembered baseline, and resolved hashes are recorded | shell | `tests/test-phase1-baseline.sh refs` | created in `01-01-01` |
| BASE-02 | Fork-vs-upstream comparison is file-backed | shell | `tests/test-phase1-matrix.sh files` | created in `01-02-01` |
| BASE-03 | Each logical unit carries a classification | shell | `tests/test-phase1-matrix.sh classifications` | created in `01-02-01` |
| XILX-01 | Material Xilinx/Vivado changes map to commits and files | shell | `tests/test-phase1-matrix.sh xilinx-trace` | created in `01-02-01` |
| XILX-02 | Each material Xilinx/Vivado change keeps row-level intent and merge-handling notes in the matrix | shell | `tests/test-phase1-matrix.sh intent` | created in `01-02-01` |

### Sampling Rate
- **Per task commit:** rerun the quick ref-resolution and merge-base commands. [VERIFIED: local git evidence]
- **Per wave merge:** rerun `range-diff`, path-overlap, and artifact-content checks. [VERIFIED: local git evidence]
- **Phase gate:** Re-resolve upstream refs and confirm the artifact still matches before `/gsd-verify-work`. [VERIFIED: D-02, D-03, D-04]

### In-Plan Test Scaffolding
- [x] `tests/test-phase1-baseline.sh` is created by `01-01-01` before the `refs` and `graph` checks consume it. [VERIFIED: 01-01-PLAN.md]
- [x] `tests/test-phase1-matrix.sh` is created by `01-02-01` before the `files`, `classifications`, `xilinx-trace`, and `intent` checks consume it. [VERIFIED: 01-02-PLAN.md]
- [x] Artifact conventions are already fixed by the current plans: `01-upstream-baseline.json`, `01-fork-delta-matrix.md`, `01-executive-summary.md`, `01-human-review.md`, and `evidence/`. [VERIFIED: 01-01-PLAN.md; 01-02-PLAN.md; 01-03-PLAN.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | — |
| V5 Input Validation | yes [VERIFIED: command-driven phase] | Validate upstream URL, ref names, and full commit hashes before using them in commands or artifacts. [VERIFIED: D-01, D-02, D-03] |
| V6 Cryptography | no [VERIFIED: phase scope] | Do not add custom crypto; Git object hashes are used as identifiers, not as a security feature designed in this phase. [VERIFIED: phase scope] |

### Known Threat Patterns for Git-Driven Baseline Capture

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Using the wrong remote because `origin` is the fork mirror | Spoofing/Tampering | Pin `https://github.com/svunit/svunit.git` in every Phase 1 command and artifact. [VERIFIED: git remote -v; D-01] |
| Shell injection through interpolated refs or paths | Tampering/Elevation of Privilege | Quote arguments, avoid `eval`, and keep refs as literal hashes once resolved. [VERIFIED: .planning/codebase/CONCERNS.md] |
| Silent fallback to stale local refs when remote resolution fails | Tampering | Fail closed to `human-review`; do not substitute local tags or memory. [VERIFIED: D-07, D-08] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/01-fork-delta-baseline-intent-record/01-CONTEXT.md` - locked decisions, artifact expectations, and `human-review` thresholds. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - Phase 1 requirement IDs and descriptions. [VERIFIED: local file]
- `.planning/ROADMAP.md` - Phase 1 goal and success criteria. [VERIFIED: local file]
- `.planning/codebase/CONCERNS.md` - fragile simulator surfaces and shell-command risks relevant to materiality and review. [VERIFIED: local file]
- Local git history in this repo - `git remote -v`, `git tag --list`, `git merge-base`, `git rev-list`, `git show`, `git diff`, `git range-diff`, `git log`, `comm`. [VERIFIED: local git]
- Official upstream refs from `https://github.com/svunit/svunit.git` via `git ls-remote`. [VERIFIED: upstream git]

### Secondary (MEDIUM confidence)
- Git official docs: `git-merge-base`, `git-ls-remote`, `git-range-diff`. [CITED: https://git-scm.com/docs/git-merge-base, https://git-scm.com/docs/git-ls-remote, https://git-scm.com/docs/git-range-diff]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - local tool availability and official Git command semantics were verified directly. [VERIFIED: local env; CITED: git docs]
- Architecture: HIGH - recommended workflow is grounded in repo-specific ancestry, overlap, and `range-diff` evidence. [VERIFIED: local git evidence]
- Pitfalls: HIGH - each pitfall maps to a concrete discrepancy or fragile area found in current history. [VERIFIED: local git evidence + .planning/codebase/CONCERNS.md]

**Research date:** 2026-04-11
**Valid until:** 2026-04-18
