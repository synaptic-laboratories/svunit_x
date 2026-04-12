---
phase: 02
slug: history-aware-upstream-integration
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-12
---

# Phase 02 — Validation Strategy

> Per-phase validation contract aligned to the expected three-plan upstream-integration sequence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | other — shell validator plus Perl syntax checks |
| **Config file** | none — `02-01-01` should create `tests/test-phase2-integration.sh` |
| **Quick run command** | `bash tests/test-phase2-integration.sh files && bash tests/test-phase2-integration.sh review` |
| **Full suite command** | `bash tests/test-phase2-integration.sh files && bash tests/test-phase2-integration.sh requirements && bash tests/test-phase2-integration.sh review && perl -c bin/runSVUnit && perl -c bin/cleanSVUnit` |
| **Estimated runtime** | ~20 seconds once the in-plan validator exists |

---

## Sampling Rate

- **After `02-01-01`:** Run `bash -n tests/test-phase2-integration.sh`.
- **After `02-01-02`:** Run `bash tests/test-phase2-integration.sh files`.
- **After `02-02-01`:** Run `perl -c bin/runSVUnit && perl -c bin/cleanSVUnit`.
- **After `02-02-02`:** Run `bash tests/test-phase2-integration.sh requirements && bash tests/test-phase2-integration.sh review`.
- **After `02-03-01` and `02-03-02`:** Re-run the full suite command before committing.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SYNC-02 | T-02-01 | A replayable Phase 2 validator exists before later tasks depend on integration artifacts | shell | `bash -n tests/test-phase2-integration.sh` | created by task | ✅ ready |
| 02-01-02 | 01 | 1 | SYNC-02, SYNC-03 | T-02-02 | The merge anchor, evidence set, and seeded review ledger exist before the upstream merge starts | shell | `bash tests/test-phase2-integration.sh files` | after `02-01-01` | ✅ ready |
| 02-02-01 | 02 | 2 | XILX-03, SYNC-01, SYNC-02 | T-02-03, T-02-04 | The integrated Perl entry points remain syntactically valid after upstream reconciliation | syntax | `perl -c bin/runSVUnit && perl -c bin/cleanSVUnit` | existing files | ✅ ready |
| 02-02-02 | 02 | 2 | XILX-03, SYNC-01, SYNC-03 | T-02-04, T-02-05 | Every keep/rewrite/replacement outcome is reflected in Phase 2 artifacts and unresolved items remain explicit | shell | `bash tests/test-phase2-integration.sh requirements && bash tests/test-phase2-integration.sh review` | after `02-01-01` | ✅ ready |
| 02-03-01 | 03 | 3 | SYNC-02, SYNC-03 | T-02-05 | The integration summary and review handoff stay aligned to the actual merged code and Phase 1 matrix | shell | `bash tests/test-phase2-integration.sh review` | after `02-02-02` | ✅ ready |
| 02-03-02 | 03 | 3 | XILX-03, SYNC-01, SYNC-02, SYNC-03 | T-02-02, T-02-05 | Final Phase 2 artifacts prove requirement coverage and preserve unresolved risk for Phase 3 | shell + syntax | `bash tests/test-phase2-integration.sh files && bash tests/test-phase2-integration.sh requirements && bash tests/test-phase2-integration.sh review && perl -c bin/runSVUnit && perl -c bin/cleanSVUnit` | after prior tasks | ✅ ready |

*Status: ✅ ready · ❌ red · ⚠️ flaky*

---

## Wave 0 Resolution

- [x] No standalone Wave 0 plan is required if `02-01-01` creates `tests/test-phase2-integration.sh` before dependent checks run.
- [x] Existing local tooling already supports the non-Quartus syntax gates: `perl -c bin/runSVUnit` and `perl -c bin/cleanSVUnit`.
- [x] Phase 2 intentionally stops short of Quartus sign-off; Quartus execution remains a Phase 3 responsibility.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final xsim CLI preservation choice | XILX-03 | Only maintainer judgment can confirm whether the retained or replaced xsim flags/cleanup behavior matches the fork's real Vivado intent | Compare the final `bin/runSVUnit` and `bin/cleanSVUnit` outcome against `LCU-01`, the Phase 2 decision ledger, and any unresolved review note; reject silent loss of a justified local behavior |
| `test/utils.py` justified replacement | SYNC-02, SYNC-03 | The current file contains a broken line and Phase 2 may need an explicit replacement rather than preservation | Confirm the final artifact names the replacement, states why the original hunk was not replayed, and ties the result back to `LCU-06` / `HR-04` |

---

## Validation Sign-Off

- [x] All expected task groups have an automated verify command or an explicit prerequisite gate
- [x] Sampling continuity: no 3 consecutive task groups without automated verify
- [x] No standalone Wave 0 gaps remain
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for planning
