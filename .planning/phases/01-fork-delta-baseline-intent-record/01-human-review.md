# Phase 01 Human Review Handoff

This file is the blocking-input list for Phase 2. Every item below must stay explicit; none of them may be silently auto-resolved during upstream integration.

## Item HR-01

- `source_artifact`: `01-upstream-baseline.json`, `01-baseline-review.md`
- `row_id_or_hash`: `v3.37.0`, `355c1411baf4d0233cb7862e53873ae90ec807e5`, `84b88033590a1469a238be84d8526b25a9f29d10`
- `why_human_review`: The remembered baseline tag and commit are a useful release anchor, but they do not match the derived merge-base that actually bounds the fork-only range used in Phase 1.
- `decision_needed_before_phase_2`: Confirm whether Phase 2 conflict discussions should talk about `v3.37.0` as historical context only, while continuing to use `84b88033590a1469a238be84d8526b25a9f29d10` as the operational comparison base.
- `safe_default_until_decided`: Keep using `8e70653e2cbfe3ebe154a863a46bf482ded4bc19` plus derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10` for all diff, range-diff, and merge reasoning; do not rewrite artifacts to pretend `v3.37.0` was the exact fork point.

## Item HR-02

- `source_artifact`: `01-upstream-baseline.json`, `01-baseline-review.md`
- `row_id_or_hash`: `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273`, `6e179cadaa036554452f8e82e9ca9e94bf307c40`
- `why_human_review`: The user-supplied candidate marker matches the full-ancestry first descendant, but the first-parent walk produces a different "first upstream commit after the fork" answer.
- `decision_needed_before_phase_2`: Decide whether maintainer-facing merge notes should prefer the full-ancestry marker, the first-parent marker, or both when describing what changed upstream immediately after the fork.
- `safe_default_until_decided`: Preserve both hashes in Phase 2 notes and forbid any single "first upstream commit after the fork" claim unless it names the ancestry rule used.

## Item HR-03

- `source_artifact`: `01-fork-delta-matrix.md`, `evidence/fork-only.log`, `evidence/path-overlap.txt`, `evidence/range-diff.txt`
- `row_id_or_hash`: `LCU-01`, `8e7d8d35e68a2deb0923871de998b13782f5f5ec`
- `why_human_review`: The xsim CLI and cleanup changes are clearly local and clearly material, but the current evidence cannot prove which exact local flags and cleanup steps are still necessary after rebasing onto upstream `v3.38.1`.
- `decision_needed_before_phase_2`: Decide which parts of the local xsim launch behavior must be preserved verbatim, and which can be rewritten against the newer upstream CLI/elaboration surface before Quartus sign-off work begins.
- `safe_default_until_decided`: Do not cherry-pick `LCU-01` text blindly. Re-implement only against current upstream code, and keep any unresolved Vivado-specific flag or cleanup requirement classified `human-review`.

## Item HR-04

- `source_artifact`: `01-fork-delta-matrix.md`, `evidence/fork-only.log`
- `row_id_or_hash`: `LCU-06`, `test/utils.py`, `8e7d8d35e68a2deb0923871de998b13782f5f5ec`
- `why_human_review`: The recorded host-side simulator edit is not trustworthy enough to interpret as a safe Python change. It may reflect a broken line capture rather than a valid implementation of xsim host detection.
- `decision_needed_before_phase_2`: Decide whether the intended outcome was to add xsim to host-side regression discovery, and if yes, specify the valid Python behavior that should replace the suspect line.
- `safe_default_until_decided`: Do not replay the recorded `test/utils.py` hunk. Leave host-side simulator discovery unchanged until the intended behavior is restated and implemented as valid Python with an explicit regression check.
