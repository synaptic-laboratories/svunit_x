# Phase 01 Executive Summary

This summary is the short companion to `01-upstream-baseline.json`, `01-baseline-review.md`, `01-fork-delta-matrix.md`, and `01-human-review.md`. Use it to enter Phase 2 without reconstructing the git history from scratch.

## Theme 1: Authoritative baseline for this sync round

- `01-upstream-baseline.json` pins upstream `v3.38.1` to tag object `e8adb554f99b579db6199b3aab547b4e68a16501`, target commit `8e70653e2cbfe3ebe154a863a46bf482ded4bc19`, and derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10`.
- `01-baseline-review.md` keeps the remembered `v3.37.0` anchor and the candidate-marker disagreement as `human-review`, so Phase 2 should use the pinned target commit and derived merge-base for diffing while refusing to silently collapse the baseline story.

## Theme 2: The large Xilinx/Vivado support unit is still material

- The local Xilinx/Vivado support work around commit `8e7d8d35e68a2deb0923871de998b13782f5f5ec` was split into `LCU-01`, `LCU-03`, `LCU-04`, `LCU-05`, and `LCU-06` in `01-fork-delta-matrix.md`.
- Those rows capture three different preservation modes. `LCU-03` and `LCU-04` are `rewrite` because upstream reshaped the same stable-runtime and experimental parser-facing files, so the Xilinx intent must be re-applied against current upstream code rather than cherry-picked. `LCU-05` stays `keep` because the helper-library parser fixes still look fork-specific. `LCU-06` stays `human-review` because the `test/utils.py` change is not trustworthy enough to replay blindly.
- Phase 2 should keep treating parser-facing, warning-reduction, and fatal-handling edits as material Xilinx behavior even when they look tidy or small in text.

## Theme 3: The narrow follow-on help-text change is already superseded

- `LCU-02` isolates commit `c2cb87111cf93cbf0f3f485730d314dbad3cb858` from the broader Xilinx patch stack.
- The matrix classifies it as `superseded` because `evidence/range-diff.txt` identifies upstream counterpart `93d3e7e`, so Phase 2 should prefer the upstream help-surface wording instead of replaying the local commit.
- `LCU-01` remains separate and `human-review` because the actual xsim execution flags and cleanup behavior are still local and need explicit maintainer scrutiny, which is why `01-human-review.md` must stay in the loop for Phase 2 conflict handling.
