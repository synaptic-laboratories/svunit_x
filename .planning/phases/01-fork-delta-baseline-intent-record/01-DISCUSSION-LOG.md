# Phase 1: Fork Delta Baseline & Intent Record - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 1-Fork Delta Baseline & Intent Record
**Areas discussed:** Upstream reference, Delta scope, Intent record format, Human-review thresholds

---

## Upstream Reference

### Q1: Authoritative upstream sync reference

| Option | Description | Selected |
|--------|-------------|----------|
| Exact upstream tag plus resolved commit hash, recorded in the repo | Use a fully resolved upstream target, not just a human shorthand release name | ✓ |
| Release name `3.38.1` only, and let Phase 2 resolve the exact commit later | Leave exact resolution for the integration phase | |
| A specific upstream branch head around that release, even if the tag naming is unclear | Use a moving or branch-based target if the release naming is messy | |
| Something else | Freeform answer | |

**User's choice:** Use the exact upstream target ref plus resolved commit hash.
**Notes:** The user also directed Phase 1 to inspect the GitHub-hosted `synaptic-laboratories/svunit_x` repo for fork clues.

### Q2: What should be written into the artifact?

| Option | Description | Selected |
|--------|-------------|----------|
| Parent repo URL, release/tag name, and exact commit hash | Record the full upstream target identity | ✓ |
| Parent repo URL and release/tag name only | Omit the exact commit hash | |
| Parent repo URL and a compare range from current fork base to upstream target | Emphasize compare range rather than resolved target identity | |
| Something else | Freeform answer | |

**User's choice:** Record parent repo URL, release/tag name, and exact commit hash.
**Notes:** The upstream source was explicitly named as `https://github.com/svunit/svunit`.

### Q3: Record derived divergence point?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, include target ref and derived merge-base/fork baseline | Record both the sync target and the discovered fork baseline | ✓ |
| No, record only the target upstream ref | Omit the derived baseline | |
| Record the target ref now, and only derive merge-base if Phase 2 needs it | Delay baseline discovery | |
| Something else | Freeform answer | |

**User's choice:** Include the derived fork baseline or merge-base.
**Notes:** This was accepted as part of the same authoritative-reference record.

### Q4: What if `3.38.1` cannot be resolved cleanly?

| Option | Description | Selected |
|--------|-------------|----------|
| Stop and require explicit human confirmation before proceeding | Do not guess the target | ✓ |
| Automatically pick the nearest upstream release/commit and record the fallback | Continue with an inferred target | |
| Use release notes plus commit history to infer the intended target and proceed | Compute a best-effort fallback | |
| Something else | Freeform answer | |

**User's choice:** Stop and require human confirmation.
**Notes:** The user prefers explicit review over inferred fallback targets.

### Q5: What if the user-supplied marker and computed graph disagree?

| Option | Description | Selected |
|--------|-------------|----------|
| User marker takes priority, mismatch documented | Trust the remembered marker | |
| Derived merge-base takes priority, marker is only a hint | Trust graph computation | |
| Stop for human review and record both | Do not choose automatically when they disagree | ✓ |
| Something else | Freeform answer | |

**User's choice:** Stop for human review and record both.
**Notes:** The user later said the likely remembered fork baseline is upstream `v3.37.0`.

### Q6: How should Phase 1 treat remembered fork-baseline evidence?

| Option | Description | Selected |
|--------|-------------|----------|
| Stop and mark for human review if fetched upstream history disagrees with the remembered baseline or marker | Review over automatic trust | ✓ |
| Trust the computed graph and move on | Prefer graph computation by default | |

**User's choice:** Stop and mark for human review.
**Notes:** The user supplied `https://github.com/svunit/svunit/tree/v3.37.0` as the likely fork baseline and `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` as a candidate marker for the first upstream commit after forking.

## Delta Scope

### Q1: What belongs in the fork-delta inventory?

| Option | Description | Selected |
|--------|-------------|----------|
| Only commits explicitly about Xilinx/Vivado support | Narrow inventory to explicit topic commits | |
| Xilinx/Vivado commits plus any later commits that touched the same files or behaviors | Track the explicit support work and follow-on behavior changes | ✓ |
| Every fork-only commit after the fork point, regardless of topic | Inventory all divergence indiscriminately | |
| Something else | Freeform answer | |

**User's choice:** Inventory explicit Xilinx/Vivado commits plus later commits touching the same files or behaviors.
**Notes:** The user wants the inventory to preserve context for later conflict handling, not just a narrow list of obvious Vivado commits.

### Q2: How should apparently tidy parser-facing changes be treated?

| Option | Description | Selected |
|--------|-------------|----------|
| Include it in the inventory, but mark it as likely non-semantic unless evidence shows otherwise | Default to cosmetic unless proven otherwise | |
| Exclude it unless the commit message explicitly mentions Xilinx/Vivado | Depend on commit-message labeling | |
| Include all such commits as fully material until proven otherwise | Treat affected tidy changes as material by default | ✓ |
| Something else | Freeform answer | |

**User's choice:** Treat static type-casting, formal-semantics, and warning-reduction edits in Xilinx-affected areas as material by default.
**Notes:** The user explained that many such changes were made because they are tidier and produce fewer warnings in Xilinx parsing.

### Q3: How far should behavior-thread tracing go?

| Option | Description | Selected |
|--------|-------------|----------|
| Only direct file overlap with the original Xilinx commits | Narrow to direct overlap | |
| File overlap plus later commits that change the same command-line behavior, generated code, parser-facing syntax, or simulator warnings | Follow the same behavior across related files and effects | ✓ |
| Any later commit that plausibly affects any supported simulator | Widen to all simulator-affecting changes | |
| Something else | Freeform answer | |

**User's choice:** Follow behavior threads across file overlap plus command-line behavior, generated code, parser-facing syntax, and simulator warnings.
**Notes:** This keeps the inventory focused without being textually naive.

### Q4: Should later non-Xilinx-specific changes still be included?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, if it affects the same parser-facing or simulator-facing behavior | Include and interpret related fork changes even without explicit Xilinx intent | ✓ |
| No, keep the record strictly to changes made with Xilinx intent | Exclude related but differently motivated changes | |
| Include it only if the commit message or notes mention simulator behavior | Depend on explicit textual evidence | |
| Something else | Freeform answer | |

**User's choice:** Yes, include later related changes and record an interpretation of what they were about.
**Notes:** The user explicitly wants any other change always listed with an interpretation so later release conflicts can be understood in context.

## Intent Record Format

### Q1: Primary artifact format

| Option | Description | Selected |
|--------|-------------|----------|
| One master table/matrix with one row per relevant local change, including interpretation and classification | Central reviewable artifact | ✓ |
| Per-commit narrative notes only | Narrative without master matrix | |
| Per-file notes only | File-centric notes without master matrix | |
| Something else | Freeform answer | |

**User's choice:** One master matrix.
**Notes:** The matrix should drive later merge reasoning directly.

### Q2: What should each row represent?

| Option | Description | Selected |
|--------|-------------|----------|
| A commit | One row per raw commit | |
| A file-level change | One row per file touched | |
| A logical change unit, which may map to one commit or several closely related edits | Group by meaning, not raw git shape | ✓ |
| Something else | Freeform answer | |

**User's choice:** One row per logical change unit.
**Notes:** This allows closely related small edits to be considered together.

### Q3: Baseline row fields

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, use the baseline row shape | Use logical change id, files, commits, interpretation, Xilinx relevance, classification, and merge-handling notes | ✓ |
| Add more fields before we proceed | Expand the baseline before locking it | |
| Use a smaller row shape | Reduce the baseline fields | |
| Something else | Freeform answer | |

**User's choice:** Use the proposed baseline row shape.
**Notes:** This is the minimum Phase 2 should need during history-aware conflict work.

### Q4: Supporting artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| Matrix only | No additional summary or appendices | |
| Matrix plus a short executive summary of the main change themes | Summary plus matrix | ✓ |
| Matrix plus appendices with raw per-commit or per-file notes | Add detailed appendices | |
| Matrix, short summary, and appendices for anything classified `human-review` | Add appendices only for escalated items | |

**User's choice:** Matrix plus a short executive summary.
**Notes:** No mandatory appendices were requested at this stage.

## Human-Review Thresholds

### Q1: Which cases should auto-escalate?

| Option | Description | Selected |
|--------|-------------|----------|
| Any case where history and current diff do not clearly explain the change intent | Escalate whenever intent is ambiguous | ✓ |
| Only direct semantic conflicts in Xilinx/Vivado-related code | Narrow escalation to explicit Xilinx conflicts | |
| Only changes that affect multiple simulators at once | Escalate only broad multi-simulator cases | |
| Something else | Freeform answer | |

**User's choice:** Escalate any case where history and current diff do not clearly explain the original intent.

### Q2: What if upstream may subsume a local fix?

| Option | Description | Selected |
|--------|-------------|----------|
| `superseded` | Assume upstream replaces the local change | |
| `rewrite` | Force a rewrite classification | |
| `human-review` | Escalate when subsumption is unclear | ✓ |
| Something else | Freeform answer | |

**User's choice:** Classify unclear subsumption as `human-review`.

### Q3: What about small but parser- or simulator-sensitive changes?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-classify unless tests fail | Leave to later test evidence | |
| `human-review` when intent or effect is not clearly proven | Escalate unclear sensitive changes | ✓ |
| Always `human-review`, no exceptions | Escalate every such change | |
| Something else | Freeform answer | |

**User's choice:** Escalate when intent or effect is not clearly proven.

### Q4: What if a logical change unit spans several commits and interpretation is uncertain?

| Option | Description | Selected |
|--------|-------------|----------|
| Pick the most likely interpretation and continue | Continue with best effort | |
| Split it into smaller units automatically | Force decomposition to avoid uncertainty | |
| Mark it `human-review` and explain the uncertainty | Escalate and preserve the ambiguity explicitly | ✓ |
| Something else | Freeform answer | |

**User's choice:** Mark it `human-review` and explain the uncertainty.

## the agent's Discretion

- Exact naming of the Phase 1 master matrix file and executive summary file
- Exact grouping heuristic used to form logical change units from commit history
- Exact git-graph derivation commands used to confirm the fork baseline and merge-base

## Deferred Ideas

None.
