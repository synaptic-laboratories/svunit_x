# Phase 02 Human Review Handoff

This file is the blocking-input list for Phase 3. It carries forward the remaining ancestry wording questions plus the unverified xsim and parser-sensitive residuals from the Phase 2 merge.

## Item 1

- `source_artifact`: `01-human-review.md`, `02-decision-ledger.md`
- `row_id_or_hash`: `HR-01`, `v3.37.0`, `355c1411baf4d0233cb7862e53873ae90ec807e5`, `84b88033590a1469a238be84d8526b25a9f29d10`
- `why_human_review`: Phase 2 used the pinned target plus derived merge-base operationally, but the remembered `v3.37.0` anchor still does not equal the computed merge-base.
- `decision_needed_before_phase_3`: Confirm that Quartus sign-off and follow-on documentation should continue to describe `v3.37.0` as historical context only, while using the derived merge-base for operational ancestry reasoning.
- `safe_default_until_quartus_signoff`: Keep `v3.37.0` in maintainer notes as context only and keep `84b88033590a1469a238be84d8526b25a9f29d10` as the operational comparison base.

## Item 2

- `source_artifact`: `01-human-review.md`, `02-decision-ledger.md`
- `row_id_or_hash`: `HR-02`, `dc7ed0a5a8b88533b52d884e2c473beb9d4ce273`, `6e179cadaa036554452f8e82e9ca9e94bf307c40`
- `why_human_review`: The full-ancestry and first-parent answers for “first upstream commit after the fork” still disagree, and Phase 2 intentionally preserved both instead of choosing one story.
- `decision_needed_before_phase_3`: Decide whether Phase 3 documentation should keep both ancestry markers or privilege one explicitly named ancestry rule.
- `safe_default_until_quartus_signoff`: Preserve both hashes in maintainer-facing notes and do not collapse them into one unlabeled claim.

## Item 3

- `source_artifact`: `02-decision-ledger.md`
- `row_id_or_hash`: `LCU-01`, `HR-03`, `27232c2`
- `why_human_review`: The integrated tree keeps the local xsim-specific `xvlog`/`xelab` flags and cleanup set, but that retained behavior has not been revalidated in a Xilinx-specific environment during this phase.
- `decision_needed_before_phase_3`: Confirm whether Quartus sign-off should simply document these retained xsim residuals as unverified future Xilinx work, or whether any of them should be narrowed before later Vivado validation.
- `safe_default_until_quartus_signoff`: Keep the retained xsim flags and cleanup set exactly as merged, and explicitly document them as carried-forward Xilinx behavior rather than Quartus-verified behavior.

## Item 4

- `source_artifact`: `02-decision-ledger.md`
- `row_id_or_hash`: `LCU-03`, `LCU-04`
- `why_human_review`: The stable-runtime and experimental parser-safe queue/signature changes were preserved on top of upstream structure, but they were not revalidated in a Xilinx parser during this phase.
- `decision_needed_before_phase_3`: Decide how strongly Phase 3 should word these residual parser-safe changes: preserved for Xilinx compatibility intent, but not re-proven by the Quartus-only sign-off environment.
- `safe_default_until_quartus_signoff`: Keep the parser-safe residuals in place and label them as preserved Xilinx-intent carry-forwards pending future Xilinx-specific verification.

## Item 5

- `source_artifact`: `02-decision-ledger.md`, `test/utils.py`
- `row_id_or_hash`: `LCU-06`, `HR-04`, `test/utils.py`
- `why_human_review`: The original fork hunk for host-side simulator discovery was invalid Python, so Phase 2 replaced it with `simulators = []` plus the explicit `xsim` append path. That replacement is clear, but it was not regression-tested in a Python test environment here.
- `decision_needed_before_phase_3`: Confirm that the explicit replacement is the intended long-term behavior and that Phase 3 documentation should describe it as a justified replacement rather than preserved text.
- `safe_default_until_quartus_signoff`: Keep the `simulators = []` replacement and the `xsim` append path as-is, and do not claim the original broken hunk was preserved.
