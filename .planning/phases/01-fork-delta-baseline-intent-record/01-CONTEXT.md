# Phase 1: Fork Delta Baseline & Intent Record - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Confirm the upstream sync target and produce a classified, file-backed record of fork-specific divergences before any upstream merge work begins. This phase establishes the verified upstream reference, the derived fork baseline, and the reviewable intent record for local Xilinx/Vivado and related fork-only changes; it does not perform the upstream integration itself.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact artifact filenames for the Phase 1 matrix and executive summary.
- The heuristic for grouping commits into logical change units, as long as the grouping remains reviewable and traceable.
- The concrete git commands and comparison workflow used to derive the merge-base and classify fork-only changes.

</decisions>

<specifics>
## Specific Ideas

- The user believes the fork baseline is likely upstream `v3.37.0` and wants that verified against fetched upstream history.
- The user supplied `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` as a candidate marker for the first upstream commit after the fork; Phase 1 should verify it rather than assume it.
- The user explicitly called out that apparently tidy changes to static type casting or formal semantics may exist because they reduce Xilinx parser warnings; these should not be dismissed as cosmetic.
- The intent record should help later conflict resolution even for non-Xilinx-specific fork changes by preserving an interpretation of why each change was originally made.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project framing
- `.planning/PROJECT.md` — project purpose, preserved local behavior, Quartus sign-off boundary, and the requirement to stop for human review on ambiguous conflicts
- `.planning/REQUIREMENTS.md` — Phase 1 requirements `BASE-01`, `BASE-02`, `BASE-03`, `XILX-01`, and `XILX-02`
- `.planning/ROADMAP.md` — Phase 1 boundary, goal, and success criteria

### Existing codebase understanding
- `.planning/codebase/STACK.md` — simulator/tooling surface and repo execution environment
- `.planning/codebase/ARCHITECTURE.md` — where simulator behavior lives in the codebase and how the runtime is organized
- `.planning/codebase/CONCERNS.md` — known fragile areas around simulator-specific behavior, command construction, and parser-sensitive code paths

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/runSVUnit`: central simulator orchestration surface where backend-specific behavior, flags, and command construction live
- `bin/buildSVUnit`: generated harness and compile-manifest path where parser-facing or simulator-specific syntax adjustments may appear
- `test/test_sim.py`, `test/test_run_script.py`, `test/test_util.py`, `test/test_example.py`: regression surfaces that reveal simulator-specific behavior and compatibility changes
- `README.md`, `CHANGELOG.md`, and `docs/source/`: supporting documentation that may help interpret the intent and public framing of simulator support changes

### Established Patterns
- Simulator support changes are concentrated in the Perl command layer under `bin/`, with regressions and expectations reflected in `test/`.
- Small parser-facing or CLI-surface edits can be semantically significant because simulator support is sensitive to syntax, warnings, and backend argument handling.
- Behavior changes often span code, tests, and docs together, so the logical change-unit grouping should not rely on file diffs alone.

### Integration Points
- Phase 1 inventory work should focus first on history touching `bin/`, `test/`, `README.md`, `CHANGELOG.md`, `.github/workflows/ci.yml`, and any generated-code or simulator-facing templates implicated by those commits.
- The Phase 1 matrix should be designed to feed Phase 2 conflict handling directly, so each logical change unit should point clearly to the files and commit ranges that will matter during merge work.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---
*Phase: 01-fork-delta-baseline-intent-record*
*Context gathered: 2026-04-11*
