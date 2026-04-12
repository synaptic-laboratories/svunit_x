# Phase 02 Integration Summary

This is the short maintainer-facing account of the upstream sync result. The full per-row rationale lives in `02-decision-ledger.md`.

## LCU-01

Final disposition: `rewritten on top of upstream`

Code surfaces:
- `bin/runSVUnit`
- `bin/cleanSVUnit`

Outcome: kept the upstream CLI and simulator-discovery behavior, then retained the local xsim-specific `xvlog --relax` and `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps` runtime details plus the Vivado cleanup set. This row still needs maintainer review because the retained xsim flags are not yet revalidated in a Xilinx-specific environment.

## LCU-02

Final disposition: `superseded by upstream`

Code surfaces:
- `bin/runSVUnit`

Outcome: the local xsim help-text follow-on was not replayed. The integrated tree uses the upstream `-e|--e_arg` and `--list-tests` help/usage surface instead.

## LCU-03

Final disposition: `rewritten on top of upstream`

Code surfaces:
- `svunit_base/svunit_pkg.sv`
- `svunit_base/svunit_testcase.sv`
- `svunit_base/svunit_testsuite.sv`
- `svunit_base/svunit_testrunner.sv`
- `svunit_base/svunit_test.svh`
- `svunit_base/svunit_globals.svh`

Outcome: upstream `v3.38.1` runtime structure was kept, including the new `svunit_test` model and list-tests flow. The fork-specific parser-safe intent was reapplied through `__svunit_fatal`, explicit `input` signatures, and queue-style typing where the modern code still needed it.

## LCU-04

Final disposition: `rewritten on top of upstream`

Code surfaces:
- `src/experimental/sv/svunit.sv`
- `src/experimental/sv/svunit/test.svh`
- `src/experimental/sv/svunit/testcase.svh`
- `src/experimental/sv/svunit/testsuite.svh`
- `src/experimental/sv/svunit/test_registry.svh`
- `src/testExperimental/sv/test_registry_unit_test.sv`

Outcome: the upstream moved layout under `src/experimental/sv/svunit/` was kept. The obsolete old-path `src/experimental/sv/testcase.svh` was dropped, and the local parser-safe queue typing was carried into the new layout and its regression surface.

## LCU-05

Final disposition: `kept with upstream overlap absorbed`

Code surfaces:
- `svunit_base/junit-xml/XmlElement.svh`
- helper-library parser-safe declarations already merged into the tree

Outcome: the local Xilinx string-copy workaround was preserved while upstream XML escaping via `xml_encode()` was also kept. No extra helper-library rewrite was needed beyond the merged parser-safe declarations.

## LCU-06

Final disposition: `justified replacement`

Code surfaces:
- `test/utils.py`

Outcome: the invalid `simulators = [$]` hunk was not preserved. It was replaced with `simulators = []`, while the explicit `shutil.which('xsim')` append path was retained and documented as a replacement.

## Requirement Coverage

- `XILX-03`: satisfied by preserving the narrow local Xilinx/Vivado behavior that still had documented intent, especially the xsim runtime/cleanup path and parser-safe queue typing. The remaining unverified xsim/parser-sensitive rows are carried into `02-human-review.md` instead of being silently declared proven.
- `SYNC-01`: satisfied by merging upstream `v3.38.1` into the forked tree and keeping the required fork-specific residual behavior on top of the upstream structure.
- `SYNC-02`: satisfied by resolving every material overlap through `02-decision-ledger.md`, which ties the merge outcomes back to `LCU-01` through `LCU-06` and the Phase 1 intent record rather than to unexplained text picks.
- `SYNC-03`: satisfied by packaging the unresolved or risky outcomes into `02-human-review.md` before Phase 3 sign-off starts.
