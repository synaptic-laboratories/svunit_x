---
phase: 01
slug: fork-delta-baseline-intent-record
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-11
---

# Phase 01 — Validation Strategy

> Per-phase validation contract aligned to the current three-plan execution sequence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | other — replayable shell and git command checks created in-plan |
| **Config file** | none — `01-01-01` creates `tests/test-phase1-baseline.sh` and `01-02-01` creates `tests/test-phase1-matrix.sh` |
| **Quick run command** | `bash tests/test-phase1-baseline.sh refs && bash tests/test-phase1-baseline.sh graph` |
| **Full suite command** | `bash tests/test-phase1-baseline.sh refs && bash tests/test-phase1-baseline.sh graph && bash tests/test-phase1-matrix.sh files && bash tests/test-phase1-matrix.sh classifications && bash tests/test-phase1-matrix.sh xilinx-trace && bash tests/test-phase1-matrix.sh intent && rg -n "decision_needed_before_phase_2|safe_default_until_decided" .planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` |
| **Estimated runtime** | ~30 seconds once the in-plan validators and artifacts exist |

---

## Sampling Rate

- **After `01-01-01`:** Run `bash -n tests/test-phase1-baseline.sh`.
- **After `01-01-02` and `01-01-03`:** Run the matching baseline subcommand (`refs` or `graph`) before committing.
- **After `01-02-01`:** Run `bash -n tests/test-phase1-matrix.sh`.
- **After `01-02-02` and `01-02-03`:** Run the relevant matrix subcommands (`files`, `classifications`, `xilinx-trace`, `intent`) before committing.
- **After `01-03-01` and `01-03-02`:** Run the task-local `rg` or combined `intent` + `rg` command from the plan before committing.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | BASE-01 | T-01-02 | The baseline verifier exists before any pinned-ref artifact checks depend on it | shell | `bash -n tests/test-phase1-baseline.sh` | created by task | ✅ ready |
| 01-01-02 | 01 | 1 | BASE-01 | T-01-01 | Upstream target, remembered baseline, and resolved hashes are pinned from authoritative refs rather than memory | shell | `bash tests/test-phase1-baseline.sh refs` | after `01-01-01` | ✅ ready |
| 01-01-03 | 01 | 1 | BASE-01 | T-01-03, T-01-04 | Baseline and marker mismatches are captured as explicit reviewable graph findings instead of being silently resolved | shell | `bash tests/test-phase1-baseline.sh graph` | after `01-01-01` | ✅ ready |
| 01-02-01 | 02 | 2 | BASE-02 | T-01-05 | The matrix verifier exists before any fork-delta artifact checks depend on it | shell | `bash -n tests/test-phase1-matrix.sh` | created by task | ✅ ready |
| 01-02-02 | 02 | 2 | BASE-02 | T-01-05 | Fork-vs-upstream comparison artifacts are written to repo files and remain reproducible | shell | `bash tests/test-phase1-matrix.sh files` | after `01-02-01` | ✅ ready |
| 01-02-03 | 02 | 2 | BASE-03, XILX-01, XILX-02 | T-01-06, T-01-07, T-01-08 | Every logical change unit keeps a valid classification, Xilinx traceability, and row-level intent plus merge-handling notes in the matrix itself | shell | `bash tests/test-phase1-matrix.sh classifications && bash tests/test-phase1-matrix.sh xilinx-trace && bash tests/test-phase1-matrix.sh intent` | after `01-02-01` | ✅ ready |
| 01-03-01 | 03 | 3 | XILX-02 | T-01-10 | The executive summary cross-links exact matrix rows and hashes instead of drifting into vague narrative | shell | `rg -n "LCU-|8e7d8d35e68a2deb0923871de998b13782f5f5ec|c2cb87111cf93cbf0f3f485730d314dbad3cb858|84b88033590a1469a238be84d8526b25a9f29d10|human-review" .planning/phases/01-fork-delta-baseline-intent-record/01-executive-summary.md` | created by task | ✅ ready |
| 01-03-02 | 03 | 3 | XILX-02 | T-01-09 | The matrix stays intent-complete while the human-review handoff captures concrete decisions and safe defaults | shell | `bash tests/test-phase1-matrix.sh intent && rg -n "v3\\.37\\.0|84b88033590a1469a238be84d8526b25a9f29d10|dc7ed0a5a8b88533b52d884e2c473beb9d4ce273|6e179cadaa036554452f8e82e9ca9e94bf307c40|decision_needed_before_phase_2|safe_default_until_decided" .planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` | after `01-02-01` and created by task | ✅ ready |
| 01-03-03 | 03 | 3 | XILX-02 | T-01-11, T-01-12 | The blocking checkpoint retains a machine-checkable gate before human approval | checkpoint + shell | `rg -n "human-review|decision_needed_before_phase_2|safe_default_until_decided" .planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` | after `01-03-02` | ✅ ready |

*Status: ✅ ready · ❌ red · ⚠️ flaky*

---

## Wave 0 Resolution

- [x] No standalone Wave 0 plan is required; `01-01-01` and `01-02-01` create the reusable validators before dependent checks run.
- [x] `tests/test-phase1-baseline.sh` is introduced in `01-01-01` and consumed by `01-01-02` and `01-01-03`.
- [x] `tests/test-phase1-matrix.sh` is introduced in `01-02-01` and consumed by `01-02-02`, `01-02-03`, and `01-03-02`.
- [x] Artifact names are already fixed by the current plan set: `01-upstream-baseline.json`, `01-fork-delta-matrix.md`, `01-executive-summary.md`, `01-human-review.md`, and `evidence/`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Marker disagreement review | BASE-01 | Whether the remembered baseline, candidate marker, and computed graph tell a coherent story can require maintainer judgment | Compare the baseline manifest, merge-base evidence, and marker evidence; if they disagree, confirm the issue is classified `human-review` with a written explanation |
| Logical-unit interpretation sanity check | XILX-02 | Some multi-commit logical units may have plausible but uncertain intent that cannot be proven automatically | Review any `human-review` rows in the matrix and confirm `likely_purpose_or_interpretation` plus `merge_handling_notes` explain the uncertainty specifically enough for later merge work |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit in-plan prerequisite coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No standalone Wave 0 gaps remain
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
