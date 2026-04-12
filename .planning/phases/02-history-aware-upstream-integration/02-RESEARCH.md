# Phase 2: History-Aware Upstream Integration - Research

**Researched:** 2026-04-12
**Domain:** Upstream merge strategy and preservation of fork-specific Xilinx/Vivado behavior
**Confidence:** MEDIUM

<phase_inputs>
## Phase Inputs

The planning inputs for this phase are already frozen by Phase 1:

- Upstream target: `v3.38.1` -> `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`
- Operational comparison base: merge-base `84b88033590a1469a238be84d8526b25a9f29d10`
- Remembered release anchor: `v3.37.0` -> `355c1411baf4d0233cb7862e53873ae90ec807e5`
- Fork code delta before planning/docs commits: `8e7d8d35e68a2deb0923871de998b13782f5f5ec`, `c2cb87111cf93cbf0f3f485730d314dbad3cb858`
- Required human-review carryovers: `HR-01` through `HR-04` from `01-human-review.md`

The current branch now contains many planning and workflow commits after `c2cb87111cf93cbf0f3f485730d314dbad3cb858`. Those commits should remain in the branch, but they are not part of the fork-code delta that Phase 2 is reconciling against upstream.
</phase_inputs>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| XILX-03 | Upstream integration preserves required Xilinx/Vivado-specific behavior or records an explicit justified replacement for it. | Resolve each logical change unit against upstream by intent, not by patch text, and record any replacement behavior explicitly. |
| SYNC-01 | Maintainer can integrate changes from the confirmed upstream target into this fork without dropping required fork-specific behavior. | Use the pinned target commit and merge-base, then integrate path groups in a controlled sequence. |
| SYNC-02 | Conflicts between upstream and fork changes are resolved using git history and documented intent rather than text-only merge choices. | Drive every non-trivial resolution from `01-fork-delta-matrix.md`, `01-executive-summary.md`, and path-specific upstream history. |
| SYNC-03 | Any unresolved or risky conflict outcomes are recorded in a human-review artifact before sign-off. | Keep a dedicated Phase 2 decision ledger and carry forward unresolved Xilinx or ancestry questions instead of silently resolving them. |
</phase_requirements>

## Summary

Phase 2 is small in commit count but not small in merge risk. The fork-only code delta is still just two commits from the verified merge-base to the last code-only fork head `c2cb87111cf93cbf0f3f485730d314dbad3cb858`, but those two commits touch `22` files across `bin/`, `svunit_base/`, `src/experimental/sv/`, and `test/`. Upstream `v3.38.1` touches the same high-risk surfaces: `bin/runSVUnit`, multiple stable-runtime files under `svunit_base/`, experimental files under `src/experimental/sv/`, and `svunit_base/junit-xml/XmlElement.svh`.

The most important upstream overlap points are:

- `bin/runSVUnit`: upstream added xsim help text in `93d3e7e`, added `xelab` elaboration arguments in `abc1b17`, and later adjusted simulator error handling in `a6df32a`.
- Stable runtime under `svunit_base/`: upstream refactored test execution, `--list-tests`, testcase/task structure, and output/reporting across many commits between `1a9cfeb` and `58291aa`.
- Experimental flow under `src/experimental/sv/`: upstream reorganized files, introduced `src/experimental/sv/svunit/`, and adapted the experimental runner around `d829e89`, `808f057`, `5a98f68`, and `e1617d5`.
- JUnit XML helper surface: upstream fixed escaping in `ee8dc24`, overlapping with local helper-library parser adjustments.

Phase 1's logical-change guidance still holds:

- `LCU-02` is effectively upstream-superseded and should resolve to upstream help text, not the local text.
- `LCU-03` and `LCU-04` are rewrite candidates, because upstream changed the same runtime and experimental files structurally.
- `LCU-05` remains a keep-or-justify-replacement unit unless execution proves upstream already satisfies the parser-compatibility intent.
- `LCU-01` and `LCU-06` remain human-review-sensitive and need explicit handling, not blind replay.

One additional concrete finding matters for planning: the current checked-in [`test/utils.py`](../../../test/utils.py) still contains `simulators = [$]`. That means the `LCU-06` concern is not theoretical; the fork currently carries an invalid Python line in host-side simulator discovery. The base shell here also does not have `python3` on `PATH`, so Phase 2 should not depend on Python-based regression as its primary gate. It should instead use file/evidence checks plus Perl syntax checks, and treat any `test/utils.py` repair as an explicit justified replacement that must be recorded for later Quartus sign-off.

## Recommended Integration Strategy

### Strategy Choice

Use a history-aware merge on the current branch, but resolve by logical change unit and path group.

Recommended execution shape:

1. Create replayable pre-merge evidence and a recoverable anchor pointing at the current branch state.
2. Start from a real merge against upstream target `8e70653e2cbfe3ebe154a863a46bf482ded4bc19` rather than hand-copying arbitrary file text.
3. Resolve each overlapping path with the Phase 1 matrix and upstream commit history open beside it.
4. Record every non-trivial keep, rewrite, or replacement in a Phase 2 decision artifact as the code is integrated.

This keeps the operation grounded in actual git ancestry while still letting the executor re-implement local Xilinx behavior where upstream refactors made verbatim replay unsafe.

### Why Not Rebase or Cherry-Pick Everything

- A plain rebase would force the large `8e7d8d3` patch through files that upstream materially restructured.
- Blind cherry-picking would hide whether a resolution came from upstream, the local fork, or a new justified replacement.
- A file-by-file transplant from upstream without a merge anchor would weaken the traceability required by `SYNC-02`.

### Recommended Plan Slices

The phase naturally decomposes into three plans:

1. **Integration prep and decision scaffolding**
   Create a Phase 2 validator and evidence/decision files, capture the pre-merge anchor, and freeze the exact path groups and human-review defaults that execution must honor.

2. **Code integration by subsystem**
   Perform the upstream merge and resolve the overlapping code in grouped subsystems:
   - CLI and cleanup
   - Stable runtime
   - Experimental flow
   - Helper-library/parser-sensitive support code
   - Host-side regression surface

3. **Human-review and handoff packaging**
   Summarize what was kept, rewritten, replaced, or deferred; preserve unresolved risk items; and leave a clean Phase 3 handoff for Quartus sign-off.

## Path-by-Path Resolution Guidance

### 1. `bin/runSVUnit` and `bin/cleanSVUnit`

Use upstream `v3.38.1` behavior as the baseline for:

- xsim help text (`LCU-02` -> upstream `93d3e7e`)
- elaboration-argument plumbing (`abc1b17`)
- updated simulator error handling (`a6df32a`)

Then re-apply only the still-required local xsim behavior from `LCU-01`:

- xsim-specific compile/elaboration flags that are still needed after upstream `xelab` option support exists
- cleanup of Vivado-generated artifacts in `bin/cleanSVUnit`

Do not preserve the local text of the help message. Preserve only behavior that still has a justified Xilinx runtime need.

### 2. Stable runtime under `svunit_base/`

Take upstream refactored files as the baseline, then manually re-port the local intent from `LCU-03`:

- parser-safe declaration forms
- explicit `input` directions where still needed
- dynamic-array substitutions where Xilinx parsing still requires them
- centralized fatal handling through `__svunit_fatal` where direct `$fatal` behavior remains simulator-sensitive

This area should be handled as a rewrite, not a patch replay. Upstream's list-tests and testcase refactors are too structural for a textual merge to be trustworthy by itself.

### 3. Experimental flow under `src/experimental/sv/`

Start from upstream's reorganized experimental layout, including the `svunit/` subdirectory structure and adapter layer introduced after the merge-base. Then port the parser-compatibility intent from `LCU-04` onto the new shapes.

The local changes here are still material, but upstream moved the design underneath them. The safe approach is:

- adopt upstream file layout and newer control flow first
- then reintroduce only the parser-safe declarations and return-shape changes that are still needed
- keep experimental regression fixtures aligned with the modern upstream API surface

### 4. Helper-library support and JUnit XML

`LCU-05` is the main keep candidate. Upstream only clearly overlaps the XML escaping fix, not the full parser-compatibility intent. The expected resolution pattern is:

- retain upstream XML escaping fix
- retain or re-port local parser-sensitive declaration fixes unless upstream code already makes them unnecessary
- record any replacement as a justified replacement, not a silent simplification

### 5. `test/utils.py`

This file needs special treatment.

Current finding:

- the checked-in code contains `simulators = [$]`
- the file also appends `'xsim'` when `shutil.which('xsim')` succeeds
- tests such as [`test/test_util.py`](../../../test/test_util.py) import `utils`, so the broken line blocks any host-side pytest flow once Python is available

Recommended handling:

- do not preserve the broken text
- replace it explicitly with valid Python list initialization
- preserve xsim discovery only if the final behavior is recorded as an explicit replacement of the invalid hunk
- add a Phase 2 artifact or check that calls out this repair as an intentional justified replacement tied to `LCU-06`

The safest likely replacement is `simulators = []`, but execution should still record that choice as a reviewed replacement, not claim it preserved the original line.

## Validation Architecture

Phase 2 should use a non-Quartus validation contract. Quartus sign-off belongs to Phase 3.

### Primary Validation Pattern

Install a Phase 2 shell validator, for example `tests/test-phase2-integration.sh`, with subcommands that verify:

- required integration artifacts exist
- every Phase 2 plan requirement is mapped to an artifact or changed subsystem
- the Phase 2 human-review ledger contains every unresolved/risky outcome
- the integrated tree contains the expected upstream-visible surfaces that Phase 2 is supposed to adopt

### Recommended Fast Checks

Use environment-agnostic commands that work in the current shell:

- `perl -c bin/runSVUnit`
- `perl -c bin/cleanSVUnit`
- `rg` checks against the Phase 2 decision artifact, review artifact, and any path-specific evidence files
- shell validator subcommands for file presence, requirement coverage, and review completeness

### Recommended Full Phase-2 Gate

Treat the following as the full Phase 2 validation gate before Phase 3:

1. Phase 2 shell validator passes all subcommands.
2. `perl -c` passes on the touched Perl entry points.
3. The Phase 2 review artifact lists every unresolved or risky Xilinx/Vivado outcome.
4. The integration summary explains each `keep`, `rewrite`, `superseded`, or justified replacement outcome against the Phase 1 matrix.

Do not make Quartus or Python-based pytest the blocking Phase 2 gate. Those belong in Phase 3 or require a different shell environment than the current one.

## Planning Implications

### Suggested Plan 01 Scope

- Create the Phase 2 directory structure and validator.
- Capture a pre-merge anchor and replayable evidence for the exact upstream target and current branch state.
- Create the initial Phase 2 decision ledger seeded from `01-human-review.md`.

### Suggested Plan 02 Scope

- Perform the actual upstream merge or equivalent merge-staging step against `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`.
- Resolve `bin/runSVUnit`/`bin/cleanSVUnit`.
- Resolve stable runtime and experimental code rewrites.
- Resolve helper-library overlaps.
- Repair `test/utils.py` as an explicit justified replacement if it remains invalid during integration.

### Suggested Plan 03 Scope

- Write the Phase 2 integration summary.
- Write/update the Phase 2 human-review artifact.
- Verify requirement coverage for `XILX-03`, `SYNC-01`, `SYNC-02`, and `SYNC-03`.
- Package the exact handoff that Phase 3 will use for Quartus sign-off.

## Open Questions That Must Stay Explicit

1. **Ancestry wording:** `HR-01` and `HR-02` remain documentation and review concerns even if operational merge reasoning continues to use the pinned target plus merge-base.
2. **Vivado CLI preservation:** `HR-03` remains open until execution proves which xsim flags and cleanup steps are still needed after upstream elaboration-argument support.
3. **Host-side simulator discovery:** `HR-04` should be converted from a vague concern into a concrete Phase 2 replacement decision for `test/utils.py`.
4. **Phase 2 boundary:** Quartus execution is not required here; Phase 2 should stop at an integrated tree plus a reviewable risk ledger.

## Assumptions Log

- The operational upstream target remains `v3.38.1` / `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`.
- The current branch can safely carry planning/docs commits while Phase 2 integrates code, because upstream does not touch those planning paths.
- `perl -c` is available and suitable as a Phase 2 syntax gate for touched Perl entry points.
- Python-based regression is not the right primary gate for this phase in the current shell environment, both because `python3` is absent on `PATH` here and because Quartus sign-off is intentionally deferred to Phase 3.
