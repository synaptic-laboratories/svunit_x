# Phase 01 Baseline Review

## Resolution Summary

| Check | Evidence | Disposition | Notes |
|-------|----------|-------------|-------|
| Upstream target `v3.38.1` | Tag object `e8adb554f99b579db6199b3aab547b4e68a16501`, peeled commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19` | resolved | `git ls-remote --tags https://github.com/svunit/svunit.git 'v3.38.1*'` resolved a single clean `refs/tags/v3.38.1^{}` target, so D-08 is not blocking for this run. |
| Remembered baseline `v3.37.0` | Remembered baseline commit `355c1411baf4d0233cb7862e53873ae90ec807e5`, derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10` | human-review | The remembered release tag is an ancestor of the computed fork point, but it is not the fork point itself. Later phases may continue only because the target and merge-base are pinned; they must not perform silent auto-resolution of this mismatch. |
| Candidate marker full-ancestry interpretation | Candidate marker `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273`, full-ancestry first descendant `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` | resolved | The user-supplied candidate marker matches the first descendant when ancestry is traversed without first-parent restriction. |
| Candidate marker first-parent interpretation | Candidate marker `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273`, first-parent first descendant `6e179cadaa036554452f8e82e9ca9e94bf307c40` | human-review | The first-parent walk yields a different "first upstream commit after the fork" answer. Later phases must not perform silent auto-resolution of this semantic disagreement. |

## Why `baseline_disposition` Is `human-review`

The baseline manifest records `baseline_disposition: human-review` because the remembered baseline `v3.37.0` and the computed merge-base disagree, and because the candidate marker only resolves cleanly under one ancestry interpretation. Those disagreements do not block Phase 1 from recording a reliable target and merge-base, but they do block later phases from assuming a single canonical "fork started here" story without an explicit maintainer judgment.

## Guardrail For Later Phases

Phase 2 and later work may use:

- Upstream target `v3.38.1`
- Target commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`
- Derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`

Phase 2 and later work must not silently auto-resolve:

- Remembered baseline `v3.37.0` / `355c1411baf4d0233cb7862e53873ae90ec807e5` versus derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`
- Candidate marker `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273` versus first-parent first descendant `6e179cadaa036554452f8e82e9ca9e94bf307c40`

Any later attempt to collapse those differences into a single baseline narrative requires explicit maintainer review.
