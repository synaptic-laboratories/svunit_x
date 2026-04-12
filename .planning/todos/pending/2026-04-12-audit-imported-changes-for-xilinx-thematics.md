---
created: 2026-04-12T10:16:27.692Z
title: Audit imported changes for Xilinx thematics
area: general
files:
  - bin/runSVUnit:185
  - bin/cleanSVUnit:47
  - svunit_base/svunit_pkg.sv:25
  - svunit_base/svunit_testcase.sv:75
  - src/experimental/sv/svunit/testcase.svh:1
  - src/experimental/sv/svunit/testsuite.svh:1
  - src/experimental/sv/svunit/test_registry.svh:1
  - src/testExperimental/sv/test_registry_unit_test.sv:32
---

## Problem

Phase 2 merged upstream SVUnit v3.38.1 into this fork and preserved the explicitly identified Xilinx/Vivado residuals, but there is not yet a systematic audit of newly imported upstream changes against the broader Xilinx fix themes already present in the fork. The user wants a follow-up pass that starts from known Xilinx-oriented themes such as parser-safe queue typing (`[$]` instead of fixed arrays where needed), explicit declarations/signatures, and similar warning-reduction or parser-compatibility patterns, then checks each imported upstream change against those themes.

This work needs to distinguish between:
- clear cases that should be fixed now
- uncertain cases that should at least get an inline comment or review note
- changes that are already consistent with the existing Xilinx themes

The user explicitly wants a report before code changes are applied broadly.

## Solution

1. Derive a concrete checklist of Xilinx fix themes from the fork history and Phase 1/2 artifacts.
2. Audit each materially imported upstream change against that checklist, especially in the CLI/runtime, stable runtime, and experimental areas touched during Phase 2.
3. Identify:
   - changes that likely need fixing
   - ambiguous cases that need comments or deferred review markers
   - changes that appear safe as imported
4. Report the proposed fix set back to the user for approval.
5. After approval, apply the approved code changes and any narrow inline comments needed to preserve future review context.
