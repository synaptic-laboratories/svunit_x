# Phase 03 Xilinx-Thematics Audit

**Purpose:** Audit the Phase 2 upstream-import surface against the fork's four documented Xilinx themes. Surface findings only — apply fixes out of scope per D-06.
**Retroactive supplement (2026-04-20):** Theme T5 (centralized `__svunit_fatal` wrapper) appended below to close the Phase 1 three-category coverage (parser-facing / warning-reduction / fatal-handling, per `01-executive-summary.md` Theme 2) that was not ring-fenced as a separate T-theme in the original plan. No source changes — inventory only. Driven by pending todo `2026-04-12-audit-imported-changes-for-xilinx-thematics`.
**Scope commit anchor:** Derived merge-base `84b88033590a1469a238be84d8526b25a9f29d10` → HEAD (Phase 2 merge `27232c2`).
**Out of scope:** Applying fixes, editing SV/Perl/Python source, touching golden files, pytest Python regressions (`test/test_*.py`), host-side helpers with no net diff vs merge-base (`test/utils.py`), or CI/docs/infra files. `svunit_base/uvm-mock/svunit_uvm_test.sv` is referenced as a T3 anchor only (pre-existing file, not a Phase 2 import).

## Scope

Scope anchor: `git diff --name-only 84b88033590a1469a238be84d8526b25a9f29d10..HEAD -- bin/ svunit_base/ src/experimental/ src/testExperimental/ src/test/sv/ test/utils.py`

**Authoritative allowlist — 32 files** (31 live + 1 deleted). This is the literal bash `AUDIT_FILES` array used by every grep below; no directory globs. The deleted entry (`src/experimental/sv/testcase.svh`) appears in the diff as status `D` against the merge-base and is absent from `HEAD`; LCU-04 intent is preserved.

| Category | File |
|---|---|
| CLI / runtime | bin/runSVUnit |
| CLI / runtime | bin/cleanSVUnit |
| CLI / runtime | bin/create_testrunner.pl |
| CLI / runtime | bin/create_testsuite.pl |
| CLI / runtime | bin/create_unit_test.pl |
| Experimental | src/experimental/sv/svunit.sv |
| Experimental | src/experimental/sv/svunit/full_name_extraction.svh |
| Experimental | src/experimental/sv/svunit/global_test_registry.svh |
| Experimental | src/experimental/sv/svunit/test.svh |
| Experimental | src/experimental/sv/svunit/test_registry.svh |
| Experimental | src/experimental/sv/svunit/testcase.svh |
| Experimental | src/experimental/sv/svunit/testsuite.svh |
| Experimental (DELETED) | src/experimental/sv/testcase.svh |
| Test (experimental) | src/test/sv/string_utils_unit_test.sv |
| Test (experimental) | src/testExperimental/sv/test_registry_unit_test.sv |
| Stable runtime — junit-xml | svunit_base/junit-xml/TestCase.svh |
| Stable runtime — junit-xml | svunit_base/junit-xml/TestSuite.svh |
| Stable runtime — junit-xml | svunit_base/junit-xml/XmlElement.svh |
| Stable runtime — junit-xml | svunit_base/junit-xml/junit_xml.sv |
| Stable runtime — core | svunit_base/svunit_base.sv |
| Stable runtime — core | svunit_base/svunit_defines.svh |
| Stable runtime — core | svunit_base/svunit_filter.svh |
| Stable runtime — core | svunit_base/svunit_filter_for_single_pattern.svh |
| Stable runtime — core | svunit_base/svunit_globals.svh |
| Stable runtime — core | svunit_base/svunit_internal_defines.svh |
| Stable runtime — core | svunit_base/svunit_pkg.sv |
| Stable runtime — core | svunit_base/svunit_string_utils.svh |
| Stable runtime — core | svunit_base/svunit_test.svh |
| Stable runtime — core | svunit_base/svunit_testcase.sv |
| Stable runtime — core | svunit_base/svunit_testrunner.sv |
| Stable runtime — core | svunit_base/svunit_testsuite.sv |
| Stable runtime — core | svunit_base/svunit_version_defines.svh |

Out-of-scope files (for audit hygiene):
- test/*.gold, test/templates/*.gold, test/junit-xml/**/dummy_unit_test.sv
- test/test_*.py
- test/utils.py (no net diff vs merge-base)
- .github/**, docs/**, CHANGELOG.md, test/README, test/requirements.txt, test/.envrc, .gitignore, .vscode/settings.json
- svunit_base/uvm-mock/svunit_uvm_test.sv (T3 ANCHOR — not a Phase 2 import)

## Classification Scheme

Every finding is tagged with one of three classes — class A, class B, or class C — per the following table:

| Class | Meaning | Sign-off-doc consumption |
|---|---|---|
| class A | Clear fix needed — region matches theme's anti-pattern and is in-scope fork territory | Feeds gap matrix row "Intent carry-forwards" as `deferred fix: <ref>` |
| class B | Ambiguous — region looks suspect but intent unclear without maintainer | Feeds gap matrix row "Intent carry-forwards" as `needs-maintainer-check: <ref>` |
| class C | Consistent — region already follows theme or theme doesn't apply | No sign-off-doc action |

## Theme T1: Parser-safe queue typing

**Anti-pattern avoided:** Fixed-length array declarations (`name[]` or `name[N]`) where the fork requires a queue (`name[$]`) for Xilinx `xvlog` parser compatibility. Anchored by the marker comment `// This needs to be declared as a dynamic array[$] ...`.

### Prior-art anchors (POSITIVE grep — `needs to be declared as a dynamic array[$]`)

10 marker comments preserved through the merge, all in-scope:

```
src/experimental/sv/svunit.sv:18
src/experimental/sv/svunit/test_registry.svh:14
src/experimental/sv/svunit/testsuite.svh:18
src/test/sv/string_utils_unit_test.sv:31
svunit_base/junit-xml/junit_xml.sv:25
svunit_base/svunit_filter.svh:25
svunit_base/svunit_filter.svh:68
svunit_base/svunit_filter.svh:89
svunit_base/svunit_string_utils.svh:6
svunit_base/svunit_testcase.sv:93
```

### Candidate anti-patterns in Phase 2 imports (DIFF-AGAINST-BASELINE)

Diff command:
```
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" \
  | grep -E '^\+' | grep -E 'typedef\s+\S+\s+\S+\[' \
  | grep -v '\[\$\]' | grep -v '^\+\+\+'
```

Result: `(no anti-pattern hits — theme preserved through merge)`.

### Structural inventory (reference)

`[$]` occurrences across the 31 live scope files: **58 sites**. Fork's parser-safe queue typing is applied broadly and consistently.

### Findings — Theme T1

| File:Line | Evidence | Class | Rationale |
|---|---|---|---|
| src/experimental/sv/svunit.sv:18 | prior-art marker | C | Fork's own fix comment preserved through merge |
| src/experimental/sv/svunit/test_registry.svh:14 | prior-art marker | C | Fork's own fix comment preserved through merge |
| src/experimental/sv/svunit/testsuite.svh:18 | prior-art marker | C | Fork's own fix comment preserved through merge |
| src/test/sv/string_utils_unit_test.sv:31 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/junit-xml/junit_xml.sv:25 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/svunit_filter.svh:25 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/svunit_filter.svh:68 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/svunit_filter.svh:89 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/svunit_string_utils.svh:6 | prior-art marker | C | Fork's own fix comment preserved through merge |
| svunit_base/svunit_testcase.sv:93 | prior-art marker | C | Fork's own fix comment preserved through merge |

**Theme outcome:** 0 class-A, 0 class-B, 10 class-C findings (total 10).

## Theme T2: Explicit input-keyword signatures

**Anti-pattern avoided:** Function or task signatures with parameters lacking the `input` keyword, which Xilinx Vivado-era `xsim` warns or fails on even though `input` is the SV default direction. Anchored by the `<<SLL-FIX>>` marker that keeps the original upstream signature commented above the revised one.

### Prior-art anchors (POSITIVE grep — `<<SLL-FIX>>`)

16 markers across 8 files, all in-scope:

```
src/experimental/sv/svunit/full_name_extraction.svh:8
src/experimental/sv/svunit/full_name_extraction.svh:19
src/experimental/sv/svunit/full_name_extraction.svh:35
src/experimental/sv/svunit/full_name_extraction.svh:47
src/experimental/sv/svunit/test.svh:13
src/experimental/sv/svunit/test.svh:75
src/experimental/sv/svunit/test_registry.svh:9
src/experimental/sv/svunit/test_registry.svh:31
src/experimental/sv/svunit/testcase.svh:10
src/experimental/sv/svunit/testcase.svh:17
src/experimental/sv/svunit/testsuite.svh:6
src/experimental/sv/svunit/testsuite.svh:13
src/experimental/sv/svunit/testsuite.svh:33
svunit_base/junit-xml/XmlElement.svh:73
svunit_base/svunit_test.svh:24
svunit_base/svunit_testcase.sv:140
```

Per-file counts (matches Focus Area 1 research):

| File | `<<SLL-FIX>>` markers |
|---|---|
| src/experimental/sv/svunit/full_name_extraction.svh | 4 |
| src/experimental/sv/svunit/test.svh | 2 |
| src/experimental/sv/svunit/test_registry.svh | 2 |
| src/experimental/sv/svunit/testcase.svh | 2 |
| src/experimental/sv/svunit/testsuite.svh | 3 |
| svunit_base/junit-xml/XmlElement.svh | 1 |
| svunit_base/svunit_test.svh | 1 |
| svunit_base/svunit_testcase.sv | 1 |
| **Total** | **16** |

### Candidate anti-patterns in Phase 2 imports (DIFF-AGAINST-BASELINE — single-line function sigs)

Diff command (restricted to signatures with non-empty parameter lists):
```
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" \
  | grep -E '^\+' | grep -E 'function[[:space:]]+.*\([^)]+[^)[:space:]]' \
  | grep -vE 'input[[:space:]]' | grep -v '<<SLL-FIX>>' \
  | grep -vE '^\+\+\+' | grep -v '^\+//' | grep -v '^\+[[:space:]]*//'
```

Result: `(no args-bearing anti-pattern hits — all new function signatures with arguments carry input or are covered by <<SLL-FIX>>)`.

Note: the generic single-line grep without the non-empty-arglist restriction returns zero-argument function declarations (e.g. `static function test_registry get();`). Those are not anti-patterns — functions with empty parameter lists have nothing to mark `input` on. Those have been filtered out.

### Candidate anti-patterns — multi-line scan

For the 26 changed `.sv`/`.svh` files in scope, an awk-based function-block scan extracted each `function ... endfunction` block, filtered to non-empty argument lists, and flagged any block where no parameter contains the `input` keyword and no `<<SLL-FIX>>` marker is present:

Result: `(no multi-line function-block hits — every multi-line signature with arguments either carries input or has a <<SLL-FIX>> marker)`.

### Candidate anti-patterns — task scan

Diff command (parallel to function scan):
```
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" \
  | grep -E '^\+' | grep -E 'task[[:space:]]+[^[:space:]]+[[:space:]]*\(' \
  | grep -vE 'input[[:space:]]' | grep -v '<<SLL-FIX>>' \
  | grep -vE '^\+\+\+' | grep -v '^\+//' | grep -v '^\+[[:space:]]*//'
```

Raw single-line hits (all have empty `()` argument lists — not anti-patterns, surfaced here for transparency):
```
+  task run();
+  protected virtual task set_up();
+  pure virtual protected task test_body();
+  protected virtual task tear_down();
+    virtual task unit_test_setup();
+    virtual task run();
+    virtual task unit_test_teardown();
+    virtual task run(); \
+    virtual task unit_test_setup(); \
+    virtual task unit_test_teardown(); \
+  pure virtual task unit_test_setup();
+  pure virtual task run();
+  pure virtual task unit_test_teardown();
+  local task run_tests();
```

All 14 task declarations above have empty `()` parameter lists, so the `input` keyword does not apply. No args-bearing task anti-patterns exist in the merge.

### Findings — Theme T2

| File:Line | Evidence | Class | Rationale |
|---|---|---|---|
| src/experimental/sv/svunit/full_name_extraction.svh:8 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied; upstream signature commented above revised form |
| src/experimental/sv/svunit/full_name_extraction.svh:19 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/full_name_extraction.svh:35 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/full_name_extraction.svh:47 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/test.svh:13 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/test.svh:75 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/test_registry.svh:9 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/test_registry.svh:31 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/testcase.svh:10 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/testcase.svh:17 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/testsuite.svh:6 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/testsuite.svh:13 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| src/experimental/sv/svunit/testsuite.svh:33 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| svunit_base/junit-xml/XmlElement.svh:73 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| svunit_base/svunit_test.svh:24 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |
| svunit_base/svunit_testcase.sv:140 | `<<SLL-FIX>>` marker | C | Prior-art fix pattern applied |

**Theme outcome:** 0 class-A, 0 class-B, 16 class-C findings (total 16).

## Theme T3: XILINX_SIMULATOR ifdef guards

**Anti-pattern avoided:** Removing or silently letting upstream collapse fork-specific conditional compilation paths (`` `ifdef XILINX_SIMULATOR `` / `` `ifndef XILINX_SIMULATOR ``) that gate Vivado `xsim`-only behavior.

### Prior-art anchors (POSITIVE grep — `XILINX_SIMULATOR` in scope)

2 guards in scope files, both preserved through the merge:

```
svunit_base/junit-xml/XmlElement.svh:62  `ifdef XILINX_SIMULATOR
svunit_base/svunit_internal_defines.svh:23  `ifndef XILINX_SIMULATOR \
```

### T3 Anchor (reference only — NOT in audit scope)

`svunit_base/uvm-mock/svunit_uvm_test.sv` is a pre-existing file (not a Phase 2 import) that carries three additional guards. Surfaced here only as evidence that pre-existing guards continue to be present after the merge:

```
svunit_base/uvm-mock/svunit_uvm_test.sv:44   `ifdef XILINX_SIMULATOR
svunit_base/uvm-mock/svunit_uvm_test.sv:73   `ifndef XILINX_SIMULATOR
svunit_base/uvm-mock/svunit_uvm_test.sv:91   `ifdef XILINX_SIMULATOR
```

These three lines are NOT in the findings table — they fall outside the 32-file allowlist.

### Candidate regressions (DIFF-AGAINST-BASELINE — any guard removed by the merge)

Diff command:
```
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" \
  | grep -E '^-' | grep 'XILINX_SIMULATOR' | grep -v '^---'
```

Result: `(none — all XILINX_SIMULATOR guards preserved through the merge)`.

### Findings — Theme T3

| File:Line | Evidence | Class | Rationale |
|---|---|---|---|
| svunit_base/junit-xml/XmlElement.svh:62 | `` `ifdef XILINX_SIMULATOR `` | C | Vivado `tag`-overwrite workaround preserved through merge |
| svunit_base/svunit_internal_defines.svh:23 | `` `ifndef XILINX_SIMULATOR `` | C | `__svunit_fatal_d` dual-form guard preserved through merge |

**Theme outcome:** 0 class-A, 0 class-B, 2 class-C findings (total 2).

## Theme T4: xsim runtime flags / cleanup

**Anti-pattern avoided:** Losing the LCU-01 xsim-specific compile/elab/cleanup flags retained on top of upstream. Evidence must show `xvlog --relax` in `bin/runSVUnit`, `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps` in `bin/runSVUnit`, and the `xsim.dir` / `xsim*.*` / `xelab*.*` / `xvlog.pb` cleanup set in `bin/cleanSVUnit`.

### Grep output

```
$ git show HEAD:bin/runSVUnit | grep -nE 'xvlog|xelab|xsim\.dir|xsim\*\.\*|xvlog\.pb'
203:  $cmd .= "xvlog --relax --sv --log $vlogfile ";
252:  $cmd .= qq! @compileargs && xelab --debug all --relax --override_timeunit --timescale 1ns/1ps testrunner @elabargs && xsim @simargs --R --log $logfile testrunner!;

$ git show HEAD:bin/cleanSVUnit | grep -nE 'xvlog|xelab|xsim\.dir|xsim\*\.\*|xvlog\.pb'
47:system("rm -rf xsim.dir");
48:system("rm xsim*.*");
49:system("rm xelab*.*");
50:unlink "xvlog.pb";
```

Required must-includes (all present — no class-A regression):

- `bin/runSVUnit:203` line contains both `xvlog` and `--relax` — **OK**.
- `bin/runSVUnit:252` line contains `xelab`, `--override_timeunit`, and `--timescale 1ns/1ps` — **OK**.
- `bin/cleanSVUnit` lines contain `xsim.dir`, `xsim*.*`, `xelab*.*`, and `xvlog.pb` — **OK** (lines 47, 48, 49, 50 respectively).

### Findings — Theme T4

| File:Line | Evidence | Class | Rationale |
|---|---|---|---|
| bin/runSVUnit:203 | `xvlog --relax --sv --log $vlogfile` | C | LCU-01 xvlog `--relax` retained through merge |
| bin/runSVUnit:252 | `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps` | C | LCU-01 xelab flag set retained through merge |
| bin/cleanSVUnit:47 | `rm -rf xsim.dir` | C | LCU-01 xsim.dir cleanup retained through merge |
| bin/cleanSVUnit:48 | `rm xsim*.*` | C | LCU-01 xsim artefact cleanup retained through merge |
| bin/cleanSVUnit:49 | `rm xelab*.*` | C | LCU-01 xelab artefact cleanup retained through merge |
| bin/cleanSVUnit:50 | `unlink "xvlog.pb"` | C | LCU-01 xvlog.pb cleanup retained through merge |

**Theme outcome:** 0 class-A, 0 class-B, 6 class-C findings (total 6).

## Theme T5: Centralized fatal-handling (`__svunit_fatal` wrapper)

**Supplement added 2026-04-20.** Phase 1 `01-executive-summary.md` Theme 2 names "parser-facing, warning-reduction, and fatal-handling" as the three material Xilinx categories. T1–T4 already cover parser-facing and warning-reduction surfaces; T5 ring-fences fatal-handling so the audit matches the Phase 1 coverage statement.

**Anti-pattern avoided:** Direct `$fatal` calls in stable-runtime and helper-library paths where the fork routes fatal handling through the `__svunit_fatal` / `__svunit_fatal_d` wrapper so simulator-specific fatal behavior can be controlled in one place. Scoped to LCU-03 (stable runtime) and LCU-05 (helper libraries) per `01-fork-delta-matrix.md`. LCU-04 (experimental tree) intent is parser-compat only and does NOT include fatal centralization — experimental-tree raw `$fatal` calls are out of wrapper scope.

### Prior-art anchors (POSITIVE grep — wrapper definitions and call sites in scope)

Wrapper definition forms preserved through the merge:

```
svunit_base/svunit_internal_defines.svh:22  `define __svunit_fatal_d(s) \
svunit_base/svunit_pkg.sv:28                 function void __svunit_fatal(input string str);
svunit_base/svunit_pkg.sv:29                 `__svunit_fatal_d(str)
```

Wrapper call sites preserved through the merge (LCU-03/LCU-05 scope):

```
svunit_base/svunit_filter.svh:77
svunit_base/svunit_filter_for_single_pattern.svh:50
svunit_base/svunit_filter_for_single_pattern.svh:57
svunit_base/svunit_filter_for_single_pattern.svh:64
svunit_base/svunit_filter_for_single_pattern.svh:70
svunit_base/svunit_string_utils.svh:18
```

### Candidate regressions (DIFF-AGAINST-BASELINE)

Diff commands:
```
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" | grep '^-' | grep -F '__svunit_fatal' | grep -v '^---'
git diff "$MERGE_BASE"..HEAD -- "${AUDIT_FILES[@]}" | grep '^+' | grep -F '$fatal'          | grep -v '^+++'
```

- **Live wrapper-use removals: 0.** The only `__svunit_fatal` removal is the original `` `define __svunit_fatal(s) \ `` macro, which was renamed to `__svunit_fatal_d` and paired with a new `function void __svunit_fatal(input string str)` in `svunit_base/svunit_pkg.sv`. The public wrapper API is preserved.
- **Raw `$fatal` reintroductions inside LCU-03/LCU-05 wrapper-scoped files: 0.** The two removed `$fatal` lines in `svunit_filter.svh` and `svunit_string_utils.svh` are correctly replaced by `__svunit_fatal(...)` calls and retained as commented-out prior-art markers (`//$fatal(...)`) one line above each wrapper call.

### Experimental-tree raw `$fatal` inventory (OUT OF WRAPPER SCOPE per LCU-04)

Four raw `$fatal(0, ...)` calls arrived from the upstream import into the experimental tree:

```
src/experimental/sv/svunit/test_registry.svh:20  $fatal(0, "This level of nesting is not yet supported");
src/experimental/sv/svunit/testsuite.svh:21      $fatal(0, "Internal error");
src/experimental/sv/svunit/testsuite.svh:40      $fatal(0, "Internal error");
src/experimental/sv/svunit/testsuite.svh:53      $fatal(0, "Internal error");
```

Per LCU-04 the experimental-tree intent is parser-compat only (dynamic-array `[$]` + parser-safe local decls). Fatal-handling centralization is an LCU-03/LCU-05 intent. These sites pass both Phase 3 (Quartus/Verilator) and Phase 4 (Vivado xsim two-mode six-target) sign-offs, so they are not behaviorally implicated.

### Findings — Theme T5

| File:Line | Evidence | Class | Rationale |
|---|---|---|---|
| svunit_base/svunit_internal_defines.svh:22 | `` `define __svunit_fatal_d(s) `` with `XILINX_SIMULATOR` dual-form | C | Wrapper macro preserved via `_d` rename paired with new function form |
| svunit_base/svunit_pkg.sv:28 | `function void __svunit_fatal(input string str)` | C | Wrapper function form present in stable runtime |
| svunit_base/svunit_filter.svh:76-77 | commented-out `//$fatal(...)` preserved above `__svunit_fatal(...)` call | C | Fork replacement pattern preserved; raw `$fatal` removed from live path |
| svunit_base/svunit_filter_for_single_pattern.svh:50 | `__svunit_fatal(error_msg)` | C | Fork wrapper call preserved |
| svunit_base/svunit_filter_for_single_pattern.svh:57 | `__svunit_fatal(error_msg)` | C | Fork wrapper call preserved |
| svunit_base/svunit_filter_for_single_pattern.svh:64 | `__svunit_fatal($sformatf(...))` | C | Fork wrapper call preserved |
| svunit_base/svunit_filter_for_single_pattern.svh:70 | `__svunit_fatal("Expected a single character")` | C | Fork wrapper call preserved |
| svunit_base/svunit_string_utils.svh:17-18 | commented-out `//$fatal(...)` preserved above `__svunit_fatal(...)` call | C | Fork replacement pattern preserved; raw `$fatal` removed from live path |
| src/experimental/sv/svunit/test_registry.svh:20 | raw `$fatal(0, "This level of nesting is not yet supported")` | C | Experimental tree — LCU-04 intent is parser-compat only; wrapper is out of LCU-04 scope |
| src/experimental/sv/svunit/testsuite.svh:21 | raw `$fatal(0, "Internal error")` | C | Same — out of LCU-04 wrapper scope |
| src/experimental/sv/svunit/testsuite.svh:40 | raw `$fatal(0, "Internal error")` | C | Same — out of LCU-04 wrapper scope |
| src/experimental/sv/svunit/testsuite.svh:53 | raw `$fatal(0, "Internal error")` | C | Same — out of LCU-04 wrapper scope |

**Theme outcome:** 0 class-A, 0 class-B, 12 class-C findings (total 12).

**Maintainer note:** If a future milestone extends `__svunit_fatal` coverage into the experimental tree, the four class-C sites above become the concrete rewrite list. No action is required under the current Phase 1 intent scoping.

## LCU-04 Sanity (legacy experimental path)

Command:
```
git ls-tree HEAD src/experimental/sv/testcase.svh
```
Result: **absent from HEAD** (exits without match). The legacy pre-rename `testcase.svh` is removed as LCU-04 intended; the canonical path is now `src/experimental/sv/svunit/testcase.svh`. No class-A regression.

(Note: during this audit session, an untracked copy of the legacy path was observed in the working tree as a residual from an unrelated pre-reset worktree state. Git HEAD does NOT track it; LCU-04 intent is preserved in committed history.)

## Summary

- Theme T1 (parser-safe queue typing): 0 class-A, 0 class-B, 10 class-C findings.
- Theme T2 (explicit input signatures): 0 class-A, 0 class-B, 16 class-C findings.
- Theme T3 (XILINX_SIMULATOR ifdef guards): 0 class-A, 0 class-B, 2 class-C findings.
- Theme T4 (xsim runtime flags / cleanup): 0 class-A, 0 class-B, 6 class-C findings.
- Theme T5 (centralized `__svunit_fatal` wrapper) — supplement added 2026-04-20: 0 class-A, 0 class-B, 12 class-C findings.

Total findings: 46. Total class-A: 0. Total class-B: 0.

These class-A and class-B findings feed `03-sign-off.md` §Gap Matrix row "Intent carry-forwards" as the Plan-1 cross-reference (D-05, D-06). With zero class-A and zero class-B findings across all five themes, Plan 2's gap-matrix row "Intent carry-forwards" records that the Phase 2 upstream-import surface preserves the fork's Xilinx themes cleanly and contributes no new deferred-fix or needs-maintainer-check items beyond those already carried from Phase 2's `02-decision-ledger.md` (LCU-01, LCU-03, LCU-04, HR-03, HR-04).

The T5 supplement is evidence-only and does not alter the Phase 3 sign-off verdict: the four class-C experimental-tree `$fatal` sites fall outside LCU-04 wrapper scope, and both Phase 3 (Quartus/Verilator) and Phase 4 (Vivado xsim) sign-offs pass with those sites as-is.

Applying fixes for class-A/B findings is out of scope per D-06. Surfaces as follow-up phases or maintainer-review items.
