---
phase: 01
slug: fork-delta-baseline-intent-record
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | other — replayable shell and git command checks |
| **Config file** | none — Wave 0 installs test scripts if automation is added |
| **Quick run command** | `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*' 'v3.37.0*' && git merge-base c2cb87111cf93cbf0f3f485730d314dbad3cb858 8e70653e2cbfe3ebe154a863a46bf482ded4bc19 && git rev-list --reverse 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858` |
| **Full suite command** | `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*' 'v3.37.0*' && git merge-base c2cb87111cf93cbf0f3f485730d314dbad3cb858 8e70653e2cbfe3ebe154a863a46bf482ded4bc19 && git rev-list --reverse 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 && git range-diff 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 84b88033590a1469a238be84d8526b25a9f29d10..8e70653e2cbfe3ebe154a863a46bf482ded4bc19` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*' 'v3.37.0*' && git merge-base c2cb87111cf93cbf0f3f485730d314dbad3cb858 8e70653e2cbfe3ebe154a863a46bf482ded4bc19 && git rev-list --reverse 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858`
- **After every plan wave:** Run `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*' 'v3.37.0*' && git merge-base c2cb87111cf93cbf0f3f485730d314dbad3cb858 8e70653e2cbfe3ebe154a863a46bf482ded4bc19 && git rev-list --reverse 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 && git range-diff 84b88033590a1469a238be84d8526b25a9f29d10..c2cb87111cf93cbf0f3f485730d314dbad3cb858 84b88033590a1469a238be84d8526b25a9f29d10..8e70653e2cbfe3ebe154a863a46bf482ded4bc19`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | BASE-01 | T-01-01 | Upstream target, remembered baseline, and derived merge-base are pinned from authoritative refs rather than memory | shell | `tests/test-phase1-baseline.sh refs` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | BASE-02 | T-01-02 | Fork-vs-upstream comparison artifacts are written to repo files and remain reproducible | shell | `tests/test-phase1-matrix.sh files` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | BASE-03 | T-01-03 | Every logical change unit includes a valid classification and supporting evidence | shell | `tests/test-phase1-matrix.sh classifications` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | XILX-01 | T-01-04 | Material Xilinx/Vivado-related behavior maps to commits and touched files | shell | `tests/test-phase1-matrix.sh xilinx-trace` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | XILX-02 | T-01-05 | Each material Xilinx/Vivado-related logical unit has intent and merge-handling notes | shell | `tests/test-phase1-matrix.sh intent` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test-phase1-baseline.sh` — verify pinned upstream URL, target tag, peeled commit, remembered tag, merge-base, and marker semantics
- [ ] `tests/test-phase1-matrix.sh` — verify every logical-unit row includes files, commit(s), purpose, Xilinx relevance, classification, and merge notes
- [ ] Artifact naming conventions — choose the final filenames for the baseline manifest, matrix, and evidence directory before automation is added

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Marker disagreement review | BASE-01 | Whether the remembered baseline, candidate marker, and computed graph tell a coherent story can require maintainer judgment | Compare the baseline manifest, merge-base evidence, and marker evidence; if they disagree, confirm the issue is classified `human-review` with a written explanation |
| Logical-unit interpretation sanity check | XILX-02 | Some multi-commit logical units may have plausible but uncertain intent that cannot be proven automatically | Review any `human-review` rows in the matrix and confirm the uncertainty explanation is specific enough for later merge work |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
