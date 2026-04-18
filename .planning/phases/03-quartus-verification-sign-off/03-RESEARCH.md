# Phase 3: Quartus Verification & Sign-Off — Research

**Researched:** 2026-04-18
**Domain:** Verification sign-off orchestration + maintainer-facing artefact authoring (meta-tooling, not HDL)
**Confidence:** HIGH — every finding is grounded in files/artefacts/commits in this repo, not on external docs.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Target coverage):** Sign-off is green only when `svunit-certify-all` reports PASS for all 5 registered targets: `quartus-23-4-qrun`, `quartus-23-4-modelsim`, `quartus-25-1-sim-only-qrun`, `quartus-25-1-sim-only-modelsim`, `verilator-5-044`.
- **D-02 (Pass criteria):** Per-target PASS = `failures=0`, `errors=0`, `passed>0` (already settled in `scripts/certify.sh`). Pytest filter `"<tool> and not uvm_simple_model"` stays in place for Quartus targets. Skipped/excluded tests go into the gap matrix, not the pass gate.
- **D-03 (Residuals):** The five `needs-maintainer-check` items from `02-decision-ledger.md` (LCU-01, LCU-03, LCU-04, HR-03, HR-04) plus Phase 1 HR-01 and HR-02 are documented in the sign-off doc as carried-forward review items with ledger pointers. They do not block sign-off.
- **D-04 (Artefact layout):** Consolidated sign-off doc lives at `.planning/phases/03-quartus-verification-sign-off/03-sign-off.md` (exact filename at planner discretion). Per-target artefacts stay at their existing qualification-artefacts path. The phase-dir sign-off doc CITES run-ids — it does not copy artefact contents. No reliance on `latest`.
- **D-05 (Gap matrix columns):** `Dimension | Covered | Not covered | Why deferred | Owner / next phase`. In-scope rows: xsim/Vivado deferral (XFLK-01), Agilex/Stratix/Arria synth gaps, UVM excluded tests, Phase 1+2 intent carry-forwards, native-vs-container execution divergence for Verilator.
- **D-06 (Plan decomposition):** Exactly two plans. Plan 1 = Xilinx-thematics audit folding the pending todo (scope: steps 1-3 of the todo — derive checklist, audit imports, classify findings). Plan 2 = `svunit-certify-all` run + consolidated sign-off doc. Applying fixes is out of scope.

### Claude's Discretion

- Exact filename for Plan 1's audit-report deliverable.
- Exact filename for Plan 2's sign-off doc (the locked default is `03-sign-off.md`, but another phase-dir filename is allowed).
- Grouping heuristic for the Xilinx-thematics audit checklist (by file or by theme).
- Whether the gap matrix is inlined in the sign-off doc or split into a companion file.
- Whether Plan 2 wraps `svunit-certify-all` in a reproducibility script.

### Deferred Ideas (OUT OF SCOPE)

- Xilinx/xsim sign-off (v2 requirement XFLK-01). FHS adapter in `scripts/certify.sh` is an intentional stub.
- Applying fixes for Xilinx-thematics audit findings (todo steps 4-5).
- Baseline-compared regression / stored baseline diffing.
- Scheduled/CI-driven sign-off.
- Reproducibility script (optional under D-06).
- Machine-readable sign-off manifest for future diffing.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VERI-01 | Maintainer can run the required regression flow on this machine through the certified Quartus flake for this stage | Focus area 2 documents the exact `nix run .#svunit-certify-all` invocation, the 5 registered targets, pre-flight checks in `scripts/certify.sh` (license files, image existence), and the per-target artefact directory layout — enough for Plan 2 to capture a single reproducible command plus known-before-you-start environment requirements. |
| VERI-02 | Quartus-based sign-off demonstrates that the synchronized fork passes the required regression suite for this stage | Focus area 2 documents exactly which fields in `build-info.json`, `qualification-results.md`, and `tests.xml` confirm PASS (grep-verifiable). Plan 2's sign-off doc consumes those fields to prove per-target PASS with per-target run-ids cited. |
| VERI-03 | Verification output records what was run, under which simulator/tooling path, and any remaining coverage gaps | Focus area 3 (sign-off doc conventions) and focus area 4 (residuals catalog) give Plan 2 the literal inputs for the "what was run" section (run-ids, pytest filters, commit hash, tool versions) and the gap matrix (5 dimensions spelled out per D-05). Focus area 1 (Xilinx-thematics audit) feeds the "intent carry-forwards" row of the gap matrix. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` exists in the repo root — `Read /srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/CLAUDE.md` returned file-not-found. No `.claude/skills/` or `.agents/skills/` directory either. No CLAUDE-sourced directives to honour.

## Summary

Phase 3 is a **meta-tooling / maintainer-authoring** phase, not an HDL phase. The regression tooling was already built in a pre-Phase-3 refactor — `svunit-certify-all` (via `flake.nix` + `nix/registry.nix` + `nix/mk-certify.nix` + `scripts/certify.sh`) produces a fully structured artefact set per target. Plan 2's job is to **execute the existing tool, harvest the run-ids it writes, and author a maintainer-facing sign-off document**. Plan 1's job is a **grep-driven audit** of the Phase 2 upstream-import surface against a concrete Xilinx-thematic checklist that already has prior art in the tree.

**Primary recommendation for the planner:**
- Plan 1: Lock the audit scope to the exact 50 files in the Phase 2 merge commit (`27232c2`) that overlap fork territory; group findings by the four themes documented below; use the `<<SLL-FIX>>` marker convention that already exists in the tree as the fix-annotation pattern.
- Plan 2: Run `nix run .#svunit-certify-all` from the repo root, harvest the 5 run-id directory names written into the artefacts root, cite them verbatim in the sign-off doc, grep-verify `"qualification_status": "PASS"` in each `build-info.json` for the pass matrix, and inline both the pass matrix and the D-05 gap matrix.

**Biggest risk surfaced by research:** `qh_build_run_id` uses minute granularity (`date -u +"%Y%m%d-%H%M"`). If two of the five targets in `svunit-certify-all` happen to start in the same UTC minute, they share a run-id directory and the second overwrites the first. Plan 2 must either (a) verify five distinct run-id directories were written, or (b) accept that targets starting the same minute will share a dir and plan artefact citation accordingly. Detail in focus area 2.

## Overview: Two-Plan Decomposition

### Plan 1 — Xilinx-thematics audit
**Consumes from research:**
- Focus area 1 — derived Xilinx-thematic checklist + grep heuristics
- Focus area 5 — Phase 2 import surface (exact files to audit)
- `<<SLL-FIX>>` marker convention as the fix-annotation pattern

**Deliverable:** Audit report classifying each material Phase-2-imported file region as (a) clear fix needed, (b) ambiguous — needs comment/deferred marker, (c) already consistent with themes. Findings feed Plan 2's gap matrix under the "intent carry-forwards" row.

**Does not:** apply fixes (that is out of Phase 3 scope per D-06).

### Plan 2 — Sign-off run + consolidated sign-off doc
**Consumes from research:**
- Focus area 2 — exact invocation, artefact layout, PASS/FAIL evidence fields
- Focus area 3 — sign-off doc structural conventions (inherited from Phase 2 ledger/summary)
- Focus area 4 — residuals catalog (7 items with verbatim ledger pointers)
- Plan 1's audit report (as an input, not a blocker — ledger rows citable independently)

**Deliverable:** `.planning/phases/03-quartus-verification-sign-off/03-sign-off.md` containing pass matrix (5 targets × PASS/FAIL + run-id), gap matrix (per D-05), carried-forward residuals section (per focus area 4).

---

## Focus Area 1: Xilinx-thematics Audit Checklist

### Derivation of the four Xilinx themes

The todo names three themes; the tree evidence supports a fourth. All four have concrete grep/scan heuristics.

| Theme | What it is | Primary evidence in the tree |
|-------|------------|-----------------------------|
| **T1: Parser-safe queue typing** | Use `typedef T name[$]` (dynamic queue) rather than fixed arrays or raw `[$]` in decls Xilinx `xvlog` refuses to parse | 9 occurrences of the marker comment `// This needs to be declared as a dynamic array[$] ...` across `svunit_base/`, `src/experimental/`, `src/test/`. 21 total `typedef ...[$]` sites. |
| **T2: Explicit `input`-keyword signatures** | Xilinx Vivado-era xsim warns/fails without explicit `input` direction on function args even when it's the default. | 16 `<<SLL-FIX>>` markers across 8 files (commit `475a9d9` "fix: apply review-marked Xilinx signature sweep"). Every marker pairs the original upstream signature (commented out, retained for review) with a revised one adding `input`. |
| **T3: `XILINX_SIMULATOR` ifdef workarounds** | Fork-specific conditional compilation paths for Xilinx-only behaviour | 4 explicit conditional blocks in: `svunit_base/svunit_internal_defines.svh:23` (`__svunit_fatal_d` dual-form), `svunit_base/junit-xml/XmlElement.svh:62` (Vivado `tag`-overwrite workaround), `svunit_base/uvm-mock/svunit_uvm_test.sv:44,73,91` (3 UVM-mock branches). |
| **T4: xsim runtime-flag / cleanup set** | Retained-on-top-of-upstream xsim-specific compile/elab/cleanup flags | `bin/runSVUnit:203` (`xvlog --relax`), `bin/runSVUnit:252` (`xelab --debug all --relax --override_timeunit --timescale 1ns/1ps`), `bin/cleanSVUnit:47-50` (`xsim.dir`, `xsim*.*`, `xelab*.*`, `xvlog.pb`). |

### Audit grep heuristics (paste-ready for a task's `<action>`)

Each theme has a grep that reliably surfaces occurrences. Audit procedure: run the grep, filter to Phase 2 imports (files listed in focus area 5), classify each hit.

```bash
# T1: Parser-safe queue typing — find NEW upstream code that declares arrays
# but doesn't use the queue-safe form. A review target is any file in the
# Phase 2 import surface that declares a typedef/array but has no [$].
grep -rn 'typedef .*\[' svunit_base/ src/experimental/ src/test/ src/testExperimental/ \
  | grep -v '\[\$\]' \
  | grep -v '^Binary'

# T1 (positive): existing marker comments — these are the fork's own
# declared Xilinx parser-safe fixes. Any Phase 2 import adjacent to one
# of these markers is a review candidate.
grep -rn 'needs to be declared as a dynamic array\[\$\]' svunit_base/ src/experimental/ src/test/ src/testExperimental/

# T2: Explicit input-keyword signatures — find NEW upstream function
# signatures that lack `input` on their parameters. The pattern
# "function <ret_type> <name>(<type> <arg>" (no input keyword) is the
# classic Xilinx-unsafe signature.
grep -rnE 'function .*\b(string|int|bit|logic|builder|test|testcase|testsuite)\s+[a-zA-Z_][a-zA-Z_0-9]*\s*[,)]' \
  svunit_base/ src/experimental/ \
  | grep -v 'input ' | grep -v '//' | grep -v '<<SLL-FIX>>'

# T2 (positive): existing fix markers — every one is a prior-art example
# of the fix pattern. Phase 2 imports in these files are high-risk areas.
grep -rn '<<SLL-FIX>>' svunit_base/ src/experimental/

# T3: XILINX_SIMULATOR ifdef — any Phase 2 import that touches a file
# containing these guards needs to preserve them exactly.
grep -rn 'XILINX_SIMULATOR' svunit_base/ src/experimental/

# T4: xsim runtime-flag set — confirm retention of the LCU-01 merged flags.
grep -nE 'xvlog|xelab|xsim\.dir' bin/runSVUnit bin/cleanSVUnit
```

**Grouping recommendation for the planner (D-06 discretion item):** Group the audit by **theme** (T1-T4), not by file. Each theme has a small, well-bounded scan heuristic. A by-theme report lets the planner answer "does theme T2 cover every new function upstream added?" in one pass, which is the real question the todo asks.

### Classification scheme (per the todo "Solution" step 3)

Every file-region hit falls into one of three classes:

| Class | Meaning | Sign-off-doc impact |
|-------|---------|---------------------|
| **A (clear fix needed)** | Region matches theme's anti-pattern and is in-scope fork territory | Add to gap matrix row "intent carry-forwards" as "deferred fix: <ref>" |
| **B (ambiguous)** | Region looks suspect but intent unclear without maintainer | Add to gap matrix row "intent carry-forwards" as "needs-maintainer-check: <ref>" |
| **C (consistent)** | Region already follows theme or doesn't trigger it | No sign-off-doc action |

### Prior-art fix-annotation pattern

Phase 2 + the `475a9d9` signature sweep already established a convention the audit should reuse:

```systemverilog
// <<SLL-FIX>> original upstream signature kept for review
// function string get_full_name(string dollar_typename);
function string get_full_name(input string dollar_typename);
```

The comment preserving the upstream form enables range-diff-friendly maintenance of the fork and gives future reviewers the "what was it before" signal. [VERIFIED: `git show 475a9d9` — 16 sites use this exact three-line pattern across 8 files.]

---

## Focus Area 2: `svunit-certify-all` Invocation + Output Shape

### Exact command

```bash
# From the repo root (where Setup.bsh lives):
nix run .#svunit-certify-all

# Also available as a flake package:
nix build .#svunit-certify-all --no-link --print-out-paths

# Per-target apps exist if single-target runs are needed:
nix run .#svunit-certify-quartus-23-4-qrun
nix run .#svunit-certify-quartus-23-4-modelsim
nix run .#svunit-certify-quartus-25-1-sim-only-qrun
nix run .#svunit-certify-quartus-25-1-sim-only-modelsim
nix run .#svunit-certify-verilator-5-044
```

[VERIFIED: `flake.nix:181-210` defines `svunitCertifyAll` as a `writeShellApplication`; `flake.nix:241-243` exports it as `packages.${system}.svunit-certify-all` and `default`; `flake.nix:251` exports it as an app with name `svunit-certify-all`.]

`svunit-certify-all` semantics: runs every target **sequentially** (not in parallel), collects failure names, **prints the timing report regardless**, exits 1 if any target failed. [VERIFIED: `flake.nix:184-209`.]

### Environment variables exported per target

`nix/mk-certify.nix:45-79` defines the env-var surface that each `svunit-certify-<target>` wrapper exports before exec-ing `scripts/certify.sh`:

**Common to every target:**
- `TARGET_NAME`, `TARGET_ADAPTER` (`container`|`native`|`fhs`), `TARGET_TOOL` (`qrun`|`modelsim`|`verilator`|`xsim`), `TARGET_DISPLAY_NAME`, `TARGET_PYTEST_FILTER`
- `TOOL_GROUP="g_svunit_x"`, `TOOL_VERSION="r_v3_38_1_x0_2_0"`, `QUALIFIED_VERSION="3.38.1-x0.2.0"` [VERIFIED: `nix/mk-certify.nix:21-23`]
- `ARTEFACTS_ROOT=/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts` [VERIFIED: `flake.nix:55` via `svunitArtefactsRoot`]
- `CERT_TOOLS_DIR=/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_sll_tools_qualified/r_cert_tools` [VERIFIED: `flake.nix:56`]
- `TIMING_SUMMARY_SCRIPT` (nix store path to `timing-summary.py`)

**Container-adapter extras** (Quartus targets only):
- `TARGET_IMAGE` (e.g. `localhost/quartus-pro-linux:23.4.0.79`)
- `TARGET_INSTALL_ROOT` (e.g. `/eda/intelFPGA_pro/23.4`)
- `TARGET_CONTAINER_PATH` (`:`-separated PATH used inside the container)
- `TARGET_EXPECTED_QUARTUS` (empty string for 25.1 sim-only images)
- `TARGET_EXPECTED_QUESTA` (e.g. `2023.3`, `2025.1`)
- `TARGET_HAS_QUARTUS_SH` (`0`|`1`)
- `LICENSE_DIR=/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch` (default; overridable via env) [VERIFIED: `flake.nix:57`]
- `CONTAINER_RUNTIME=podman` (default)

**Native-adapter extras** (Verilator):
- `TARGET_EXPECTED_VERILATOR=5.044`
- `TARGET_VERILATOR_STORE_PATH` (nix store path)

### Pre-flight checks run by `scripts/certify.sh`

Before any artefacts are written, `certify.sh:74-113` pre-validates:

- **Container adapter:** requires `quartus_license.dat` AND `questa_license.dat` in `$LICENSE_DIR`; requires `$TARGET_IMAGE` to exist in the container runtime (`podman image exists`).
- **Native adapter:** requires `verilator` on PATH with matching `$TARGET_EXPECTED_VERILATOR` version string; requires `gcc` and `make` on PATH.
- **FHS adapter:** exits 2 with message "FHS adapter (Vivado/xsim) is not yet implemented" — Vivado xsim is the planned XFLK-01 surface but registry has no `fhs` targets today. [VERIFIED: `scripts/certify.sh:105-108`; `registry.nix` has no fhs entries.]

All pre-flight failures exit before `mkdir -p "${OUTPUT_DIR}"` runs, so no partial artefacts pollute the root.

### Artefact directory layout per run

For each target, `certify.sh` writes to `${ARTEFACTS_ROOT}/${QH_RUN_ID}/`. The run-id is built by `qh_build_run_id --no-gpu-suffix` in `qualification-helpers.sh` as:

```
YYYYMMDD-HHMM--nixos-<os_ver>--nix-<nix_ver>--kernel-<kernel_ver>
```

Example (seen in the live artefacts root): `20260417-1616--nixos-25.11--nix-2.31.2--kernel-6.12.70`. [VERIFIED: `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_sll_tools_qualified/r_cert_tools/scripts/qualification-helpers.sh:141-179`.]

**⚠️ Run-id collision risk (HIGH):** The timestamp is minute-granular. `svunit-certify-all` runs 5 targets sequentially. If two targets start in the same UTC minute, they **share the same run-id directory** and the second silently overwrites the first's `build-info.json`, `tests.xml`, `qualification-results.md`, `timing-summary.json`, and `test-log.txt`. Container-adapter targets also write `image-inspect.json`. [VERIFIED: `scripts/certify.sh:118-131` calls `qh_build_run_id` per-target with no uniqueness guard; live artefacts root has three separate run-ids at minutes 1607, 1608, 1616 — so if a target pair completes in under a minute, one overwrites the other.] Plan 2 must account for this.

**Files produced per target run:**

| File | Source | What it proves |
|------|--------|----------------|
| `build-info.json` | `certify.sh:281-347` via `qh_build_info_json` + `jq` | Machine-readable target metadata + status. `"qualification_status": "PASS"` is the grep-verifiable pass signal. |
| `qualification-results.md` | `certify.sh:351-457` | Maintainer-readable summary. `**Overall:** PASS (...)` line is the human pass signal. |
| `tests.xml` | pytest `--junitxml` | JUnit XML. Root-tag attrs `tests="N" failures="0" errors="0" skipped="K"` are the raw gate. |
| `timing-summary.json` | `scripts/timing-summary.py` | Per-test durations. `tests_total` field. |
| `test-log.txt` | captured stdout+stderr of the inner pytest run | Full debug log. |
| `image-inspect.json` | (container only) `podman inspect ${TARGET_IMAGE}` | Container-image digest + labels. |

### PASS/FAIL evidence fields (grep-verifiable)

For the sign-off doc to cite "this target passed" with evidence, these are the canonical grep targets:

| File | Grep pattern for PASS | Notes |
|------|----------------------|-------|
| `build-info.json` | `"qualification_status": "PASS"` | Primary field. Also `"tests_failed": 0`, `"tests_errors": 0`, `"tests_passed": N` with N≥1. [VERIFIED: `scripts/certify.sh:262-266,315-323`] |
| `qualification-results.md` | `**Overall:** PASS (` | Line 5 of the file. [VERIFIED: template in `scripts/certify.sh:363`] |
| `tests.xml` | `failures="0"` AND `errors="0"` in the `<testsuite>` root | The script itself derives STATUS from these. [VERIFIED: `scripts/certify.sh:253-259`] |
| per-run stdout | `=== Qualification Complete ===` followed by `Status:   PASS` | End-of-run summary. [VERIFIED: `scripts/certify.sh:465-468`] |
| `svunit-certify-all` stdout | `All targets passed.` | Final line when all targets pass. [VERIFIED: `flake.nix:208`] |

### STATUS determination logic

```bash
# scripts/certify.sh:262-266 — exact logic
if [ "${FAILURES}" -eq 0 ] && [ "${ERRORS}" -eq 0 ] && [ "${PASSED}" -gt 0 ]; then
  STATUS="PASS"
else
  STATUS="FAIL"
fi
```

`PASSED=$((TOTAL - FAILURES - ERRORS - SKIPPED))` from `tests.xml` root attrs. If `tests.xml` doesn't exist (pytest never started), all five values are 0 and STATUS=FAIL. [VERIFIED: `scripts/certify.sh:252-266`.]

### Qualification artefacts root — canonical path

**Single source of truth:** `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/`

[VERIFIED: `flake.nix:55` sets `svunitArtefactsRoot`; passed to `nix/mk-certify.nix` as `artefactsRoot`; exported to `scripts/certify.sh` as `$ARTEFACTS_ROOT`. Directory exists on disk with 3 run-id subdirs + `latest` symlink at the time of research.]

### `latest` symlink behaviour

`scripts/certify.sh:462` calls `qh_update_latest_symlink "${ARTEFACTS_ROOT}" "${QH_RUN_ID}"` at the end of each target run. That function (`qualification-helpers.sh:258-270`):

1. Removes any existing `${artefacts_dir}/latest` symlink (if it is one).
2. Creates a new relative symlink `latest -> <run_id>`.

**Implication for `svunit-certify-all`:** `latest` is overwritten after every target. When `svunit-certify-all` completes 5 targets, `latest` points at whichever target ran LAST — `verilator-5-044` in the current registry order (`flake.nix` emits apps in Nix attrName order, which alphabetically puts verilator last). [VERIFIED: live artefacts root — `latest -> 20260417-1616-...` which was the most recent verilator run.] **Plan 2 cannot rely on `latest` at all** — D-04 correctly specifies this. Citation must use explicit run-id strings.

### How Plan 2 obtains the exact run-ids after a fresh run

Three options, ranked by robustness:

1. **(Recommended)** Read `run_id` directly from each target's `build-info.json`. The task's `build-info.json` writer records its own run-id at `jq '.run_id'`. Scan all five targets like:
   ```bash
   for ri in $(ls "$ARTEFACTS_ROOT" | grep -v '^latest$' | sort); do
     jq -r '[.target, .run_id, .qualification_status] | @tsv' "$ARTEFACTS_ROOT/$ri/build-info.json"
   done
   ```
2. Read from the script's stdout: `scripts/certify.sh:469` prints `Run ID:   ${QH_RUN_ID}` near the end of each target. The `svunit-certify-all` aggregator preserves stdout.
3. Parse `qualification-results.md` line `**Run ID:** ...`.

Option 1 is the most self-describing because `build-info.json.target` disambiguates which run-id belongs to which target if minute-collisions happen.

---

## Focus Area 3: Sign-Off Doc Structural Conventions

### Prior-art files to mirror

| File | What to borrow |
|------|----------------|
| `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` | Single-markdown-table format with explicit columns. First row is always the column-header line; second row is separators; subsequent rows are content. Use `<br>` for multi-line cell content — no soft-wrap. |
| `.planning/phases/02-history-aware-upstream-integration/02-integration-summary.md` | `## <row-id>` section-per-item narrative style with `Final disposition:`, `Code surfaces:`, `Outcome:` bold-labelled key-value pairs. Closes with a `## Requirement Coverage` section that names each requirement and explains how it is satisfied. |
| `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` | HR-item numbered sections with pinned-field layout: `source_artifact`, `row_id_or_hash`, `why_human_review`, `decision_needed_before_<next_phase>`, `safe_default_until_<next_phase>`. **Inherit this exact field schema if the sign-off doc carries forward HR items into Phase 4.** |

### Heading structure recommendation (for planner)

Based on the prior art:

```markdown
# Phase 03 Sign-Off Record

## Pass Matrix
<single table: target | run_id | status | passed | skipped | pytest_filter | evidence_link>

## Environment
<OS, nix, kernel, hostname, svunit commit, artefacts root path>

## Command Executed
<exact reproducible invocation + date/time>

## Gap Matrix
<single table per D-05: Dimension | Covered | Not covered | Why deferred | Owner / next phase>

## Carried-Forward Residuals
<HR-01, HR-02, LCU-01, LCU-03, LCU-04, HR-03, HR-04 each with ledger pointer>

## Xilinx-Thematics Audit Cross-Reference
<pointer to Plan 1 deliverable; if findings exist, they feed the "intent carry-forwards" gap row>

## Requirement Coverage
<VERI-01, VERI-02, VERI-03 each explained>
```

### Citation style conventions (from the existing ledgers)

- Ledger pointers use the form `02-decision-ledger.md#LCU-01` or `01-human-review.md#item-hr-01` — fragment anchors that render if the maintainer opens in a markdown viewer. The 02 ledger uses this style verbatim in its `source_ref` column.
- Commit pointers use **short SHAs** (7 chars): `27232c2`, `475a9d9`, `8e7d8d3`. Phase 2 docs use short SHAs throughout.
- Run-id citations should use the **full run-id string** (no truncation) — shortening loses the ecosystem metadata (nix version, kernel version) that is the run-id's whole point.
- Artefact paths in the sign-off doc should be **relative from the repo root or phase dir** where possible (e.g. `${ARTEFACTS_ROOT}/<run-id>/build-info.json`), or the literal absolute path from `flake.nix:55` when the maintainer needs to navigate outside the repo.

### Table-style consistency

Every Phase 2 artefact uses **a single table per distinct concern**. Phase 3 should follow this — don't split the pass matrix across multiple tables; don't split the gap matrix. The D-05 gap-matrix column list (`Dimension | Covered | Not covered | Why deferred | Owner / next phase`) is the literal column header.

---

## Focus Area 4: Carry-Forward Residuals Catalog

These 7 items are the verbatim inputs for the sign-off doc's "Carried-Forward Residuals" section. Each entry is copy-pastable.

| # | ID | Ledger pointer | One-sentence summary |
|---|-----|---------------|----------------------|
| 1 | HR-01 | `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md#item-hr-01` (also `02-decision-ledger.md` row HR-01) | Remembered baseline `v3.37.0` / `355c1411` does not equal the derived merge-base `84b8803`; Phase 3 sign-off notes should continue to treat `v3.37.0` as historical context only and use the merge-base operationally. |
| 2 | HR-02 | `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md#item-hr-02` (also `02-decision-ledger.md` row HR-02) | Full-ancestry (`dc7ed0a`) vs first-parent (`6e179ca`) disagree on "first upstream commit after the fork"; Phase 3 docs must preserve both hashes and name the ancestry rule when making any claim. |
| 3 | LCU-01 | `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` row LCU-01; files `bin/runSVUnit`, `bin/cleanSVUnit`; commit `27232c2` | Local xsim runtime flags (`xvlog --relax`, `xelab --debug all --relax --override_timeunit --timescale 1ns/1ps`) and Vivado cleanup set (`xsim.dir`, `xsim*.*`, `xelab*.*`, `xvlog.pb`) were kept on top of upstream CLI but are not revalidated in Phase 3 because Quartus sign-off does not exercise xsim. |
| 4 | LCU-03 | `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` row LCU-03; files `svunit_base/svunit_pkg.sv`, `svunit_base/svunit_testcase.sv`, `svunit_base/svunit_testsuite.sv`, `svunit_base/svunit_testrunner.sv`, `svunit_base/svunit_test.svh`, `svunit_base/svunit_globals.svh` | Parser-safe queue typing (`[$]`), explicit `input` signatures, and `__svunit_fatal` were re-applied on top of the upstream v3.38.1 runtime structure but are not revalidated by a Xilinx parser during Phase 3. |
| 5 | LCU-04 | `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` row LCU-04; files under `src/experimental/sv/svunit/` + `src/testExperimental/sv/test_registry_unit_test.sv` | Experimental tree's parser-safe queue typing was carried into the new upstream-moved layout; the old path `src/experimental/sv/testcase.svh` was dropped; not revalidated by a Xilinx parser in Phase 3. |
| 6 | HR-03 | `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md#item-hr-03` (also `02-human-review.md` Item 3) | xsim CLI and cleanup changes LCU-01 are material and local but not proven necessary after rebasing onto upstream v3.38.1; retained behavior remains `needs-maintainer-check`. |
| 7 | HR-04 | `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md#item-hr-04` (also `02-human-review.md` Item 5) | `test/utils.py` host-side simulator discovery hunk was replaced with `simulators = []` + explicit `shutil.which('xsim')` append path (justified replacement, not literal preservation); regression test in a Python env still pending. |

**Planner instruction:** The sign-off doc can either (a) inline these 7 rows as a single table with columns `ID | Ledger pointer | Summary`, or (b) use the HR-style numbered-section format (Item 1 through Item 7) from `01-human-review.md`. Option (a) matches the Phase 2 decision-ledger convention more closely and fits on one page.

---

## Focus Area 5: Phase 2 Import Surface (Plan 1 audit scope)

The upstream merge is commit `27232c2` "feat(02-02): integrate upstream v3.38.1" (merge commit; parents = `765fb34` local + `8e70653` upstream). That merge touched **51 files, 935 insertions, 167 deletions**. [VERIFIED: `git show --stat 27232c2`.]

### In-scope files for the Xilinx-thematics audit

Filtering to SV/Perl fork territory (excluding docs, CI config, planning artefacts, and test goldens that only exist to verify pytest mechanics):

**CLI / runtime (T2 + T4):**
- `bin/runSVUnit` (59 lines changed vs merge-base — adds `-e`/`--e_arg`, `--list-tests`, Verilator parallelism, xsim flag retention)
- `bin/cleanSVUnit` (6 lines — xsim cleanup additions)
- `bin/create_testrunner.pl` (4 lines — upstream)
- `bin/create_testsuite.pl` (1 line — upstream)
- `bin/create_unit_test.pl` (1 line — upstream)

**Stable runtime (T1 + T2 + T3):**
- `svunit_base/svunit_pkg.sv`
- `svunit_base/svunit_testcase.sv` (112 lines — 7 explicit `input` sites per `grep 'input '`)
- `svunit_base/svunit_testsuite.sv`
- `svunit_base/svunit_testrunner.sv` (4 explicit `input` sites)
- `svunit_base/svunit_test.svh` (new file — `<<SLL-FIX>>` marker at line 24)
- `svunit_base/svunit_globals.svh` (new file)
- `svunit_base/svunit_defines.svh` (88 lines — macro restructuring)
- `svunit_base/svunit_internal_defines.svh` (has `XILINX_SIMULATOR` ifdef at line 23)
- `svunit_base/svunit_base.sv`
- `svunit_base/svunit_filter.svh` (4 `[$]` sites, parser-safe comments)
- `svunit_base/svunit_filter_for_single_pattern.svh` (8 explicit `input` sites)
- `svunit_base/svunit_string_utils.svh` (1 `[$]` site)
- `svunit_base/svunit_version_defines.svh` (version bump only)
- `svunit_base/junit-xml/TestCase.svh`
- `svunit_base/junit-xml/TestSuite.svh`
- `svunit_base/junit-xml/XmlElement.svh` (`<<SLL-FIX>>` marker + `XILINX_SIMULATOR` ifdef at line 62)
- `svunit_base/junit-xml/junit_xml.sv` (parser-safe comment at line 25)

**Experimental tree (T1 + T2):**
- `src/experimental/sv/svunit.sv` (moved-structure + 1 parser-safe comment)
- `src/experimental/sv/svunit/full_name_extraction.svh` (4 `<<SLL-FIX>>` markers)
- `src/experimental/sv/svunit/global_test_registry.svh` (rename only)
- `src/experimental/sv/svunit/test.svh` (new path — 2 `<<SLL-FIX>>` markers, 3 `[$]` sites)
- `src/experimental/sv/svunit/test_registry.svh` (2 `<<SLL-FIX>>` markers)
- `src/experimental/sv/svunit/testcase.svh` (new path — 2 `<<SLL-FIX>>` markers)
- `src/experimental/sv/svunit/testsuite.svh` (3 `<<SLL-FIX>>` markers)
- `src/experimental/sv/testcase.svh` (DELETED — audit confirm)
- `src/test/sv/string_utils_unit_test.sv`
- `src/testExperimental/sv/test_registry_unit_test.sv`

**Host-side helpers (focused):**
- `test/utils.py` (justified replacement — LCU-06/HR-04)

**Explicitly NOT in audit scope** (noise for a Xilinx-thematics audit):
- `test/frmwrk_3/testsuite.gold`, `test/templates/*.gold` — golden-file updates that mirror generator changes
- `test/test_frmwrk.py`, `test/test_junit_xml.py`, `test/test_list_tests.py`, `test/test_run_script.py`, `test/test_sim.py` — Python pytest regressions; not SV parser territory
- `.github/`, `docs/`, `CHANGELOG.md`, `test/README`, `test/requirements.txt`, `test/.envrc`, `.gitignore`, `.vscode/settings.json` — infrastructure; no Xilinx themes apply
- `test/junit-xml/no-test-suite/dummy_unit_test.sv`, `test/junit-xml/single-test-suite/dummy_unit_test.sv` — JUnit-XML fixtures, tiny, not representative of fork themes

**Recommended Plan 1 scope statement:** 31 files in 4 directories (`bin/`, `svunit_base/`, `src/experimental/`, `src/testExperimental/sv/test_registry_unit_test.sv`, `src/test/sv/string_utils_unit_test.sv`, `test/utils.py`). The planner should cap the audit scope with this explicit list rather than a directory glob — it prevents scope drift into goldens and pytest infrastructure.

### Commit-anchor for the audit

The Phase 2 import surface is **exactly** `git diff 84b88033590a1469a238be84d8526b25a9f29d10..HEAD -- bin/ svunit_base/ src/experimental/ src/testExperimental/ src/test/ test/utils.py` where `84b8803` is the derived merge-base (from `01-upstream-baseline.json`). This command gives Plan 1 an authoritative diff to audit, independently of the 50-file-stat-list above. [VERIFIED: `01-upstream-baseline.json.derived_merge_base = "84b88033590a1469a238be84d8526b25a9f29d10"`; `git diff --stat 84b88033590a1469a238be84d8526b25a9f29d10..HEAD` returns the 51-file list.]

---

## Standard Stack

Phase 3 uses pre-existing tooling — no new libraries. The operative stack:

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| `nix` | 2.31.2 (live machine) | Runs `svunit-certify-all` via flake | `flake.nix`; requires the 4 flake inputs resolve: `quartus-podman-23-4`, `quartus-podman-25-1`, `verilator-certified`, `nixpkgs` |
| `podman` | whatever the dev shell provides | Container runtime for the 4 Quartus targets | `flake.nix:262`; CONTAINER_RUNTIME env overrides |
| `pytest` | `>=7,<9` (pinned inside container), `pytest-datafiles==2.0` | Test driver inside both container and native adapters | `scripts/certify.sh:160`; `flake.nix:64-73` for native |
| `jq` | from nixpkgs | Assembles `build-info.json` | `nix/mk-certify.nix:32` |
| `grep` / `awk` | coreutils/gnugrep/gawk | Parses `tests.xml` root attrs for pass counts | `scripts/certify.sh:253-256` |

**Installation** (maintainer viewpoint): everything is pulled by `nix run .#svunit-certify-all`. No `npm install` equivalent. The only pre-requisites outside Nix are:
1. `podman` on the host (for container targets).
2. Quartus container images pre-built via `svunit-quartus-tools-<target>` (each target's `image exists` check fails otherwise).
3. License files at `$LICENSE_DIR` (`quartus_license.dat` + `questa_license.dat`).

**Version verification (post-flake):** `nix flake show` lists all 5 certify apps + 2 `quartus-tools` wrappers + 2 `quartus-shell` wrappers + the aggregate. [VERIFIED against `flake.nix:236-254`.]

## Architecture Patterns

### Recommended deliverable structure (phase dir)

```
.planning/phases/03-quartus-verification-sign-off/
├── 03-CONTEXT.md                (existing — locked)
├── 03-RESEARCH.md               (this file)
├── 03-01-PLAN.md                (Plan 1 — Xilinx audit)
├── 03-02-PLAN.md                (Plan 2 — sign-off)
├── 03-xilinx-thematics-audit.md (Plan 1 deliverable — filename at planner discretion)
└── 03-sign-off.md               (Plan 2 deliverable — filename at planner discretion)
```

### Pattern: artefact-by-reference, not artefact-by-copy

**What:** Phase-dir docs cite absolute paths and run-ids from the qualification artefacts root. They never embed tests.xml or re-print the full qualification-results.md contents.
**When to use:** Always. Re-printing artefact content makes the phase dir repo balloon, and creates doc-drift risk when the artefacts root rotates.
**Example (from D-04 design intent):**
```markdown
| Target | Run ID | Status | Evidence |
|--------|--------|--------|----------|
| quartus-23-4-qrun | 20260418-HHMM--nixos-25.11--nix-2.31.2--kernel-6.12.70 | PASS | `/srv/share/repo/sll/.../r_v3_38_1_x0_2_0_artefacts/20260418-HHMM--.../build-info.json` |
```

### Pattern: grep-verifiable citations

**What:** Every "PASSED" claim the sign-off doc makes is backed by a machine-checkable grep against `build-info.json` or `tests.xml`.
**When to use:** Every row in the pass matrix.
**Example:**
```bash
# Reviewer can verify each row:
jq -r '.qualification_status' "$ARTEFACTS_ROOT/<run-id>/build-info.json" # => "PASS"
```

### Anti-patterns to avoid

- **Copying `qualification-results.md` contents into the sign-off doc** — duplicates ~500-line artefacts 5 times. Cite by path instead.
- **Using `latest` in citations** — `latest` is overwritten by every target. By the time a maintainer opens the sign-off doc a week later, `latest` points somewhere else. D-04 explicitly prohibits this.
- **Running `svunit-certify-all` from outside the repo root** — `scripts/certify.sh:66-69` exits with "ERROR: Setup.bsh not found" if `$REPO_ROOT/Setup.bsh` does not exist, and `REPO_ROOT` defaults to `pwd`.
- **Building the audit scope from a directory glob** — pulls in pytest goldens and Python regressions that are not Xilinx-themed.
- **Treating `verilator-5-044` as a Quartus target** — the pytest filter for verilator is `"verilator"` (no `"not uvm_simple_model"` suffix — the registry configures that suffix only on the 4 Quartus targets per `nix/registry.nix:112,117,124,129`). Sign-off doc should mention this filter-per-target distinction.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parse `tests.xml` for pass/fail counts | Custom XML parser | `grep -oP` on root `<testsuite>` attrs (already in `scripts/certify.sh:253-256`) | Existing logic is correct for the pytest-generated shape; derives FAILURES, ERRORS, SKIPPED, TOTAL and computes PASSED. Don't re-implement. |
| Compute pass/fail status | Custom logic | Read `"qualification_status"` from `build-info.json` | Already computed once, canonicalized, and written. One jq command. |
| Run 5 targets sequentially + collect failures | A bash loop | `nix run .#svunit-certify-all` | Aggregator already does this with FAILED[] collection + timing report. |
| Pin run-ids for archival | Stamping files | Read `run_id` field from each `build-info.json` | Each target's build-info records its own run-id. Self-describing. |
| Discover the 5 registered targets | Hard-code list | `builtins.attrNames` from `nix/registry.nix` (or `$SVUNIT_TARGETS` env var exported by the dev shell) | Registry is the single source of truth. `flake.nix:272` exports `SVUNIT_TARGETS` to the dev shell. |
| Document gap matrix dimensions | Brainstorm | Use D-05's 5 rows verbatim | Dimensions were locked during context gathering. |
| Fix-annotation marker | New convention | Re-use `<<SLL-FIX>>` | 16 existing occurrences across 8 files establish precedent. Tooling (grep) already works. |

**Key insight:** Phase 3 is artefact orchestration and maintainer-authoring. The heavy lifting lives in the flake + certify.sh + qualification-helpers.sh stack that was built in the pre-Phase-3 tooling refactor (commits `4d2fe25`, `e260506`, `5599d08`, `ed0389f`, `8657fde`, `eca4a17`). Plan 2 consumes; it does not reimplement.

## Runtime State Inventory

Phase 3 is not a rename/refactor/migration phase. No runtime state needs to migrate. **SKIPPED.**

Caveat: the qualification artefacts root **accumulates** — each run writes a new run-id dir. The directory grows monotonically until a maintainer prunes it. Plan 2 should cite run-ids by full path so that even if `latest` rotates or old run-ids are archived, the sign-off record points to the archival location maintainer can restore.

## Common Pitfalls

### Pitfall 1: Running from outside the repo root
**What goes wrong:** `scripts/certify.sh` exits with `ERROR: Setup.bsh not found. Run from the SVUnit repo root or set REPO_ROOT.` and no artefacts are written.
**Why it happens:** `REPO_ROOT` defaults to `pwd` (`certify.sh:38`) and the script checks `$REPO_ROOT/Setup.bsh` exists.
**How to avoid:** Plan 2 must `cd "$REPO_ROOT"` explicitly (the dev shell shellHook sources Setup.bsh if it's in CWD but doesn't change directory).
**Warning signs:** "ERROR: Setup.bsh not found" at script start; zero artefacts produced.

### Pitfall 2: Run-id minute collision
**What goes wrong:** Two targets starting within the same UTC minute share a run-id directory; second target's artefacts overwrite the first's. Pass matrix ends up with the same run-id for two different targets, and one target's evidence is lost.
**Why it happens:** `qh_build_run_id` uses `date -u +"%Y%m%d-%H%M"` — minute-granular, no uniqueness guard, no target name in run-id.
**How to avoid (Plan 2 validation task):** After `svunit-certify-all` completes, verify that exactly 5 distinct run-id directories are younger than the start of the sign-off run. If fewer than 5, at least one collision happened — re-run the affected targets singly via `nix run .#svunit-certify-<target>` until each has a unique run-id dir. Alternatively, sleep 60s between targets (but that defeats the aggregator).
**Warning signs:** `ls $ARTEFACTS_ROOT | tail -5` shows fewer than 5 new dirs after a certify-all run.

### Pitfall 3: Citing `latest` in the sign-off doc
**What goes wrong:** Doc claims "target X passed per `$ARTEFACTS_ROOT/latest/...`" but `latest` already moved to another target's run. Grep-verification fails.
**Why it happens:** Every target's final step is `qh_update_latest_symlink` (`certify.sh:462`). `latest` always points at the most-recently-completed target across all time, not per-target.
**How to avoid:** Use full run-id strings in citations. D-04 already prohibits `latest`; the planner should call this out in Plan 2 task descriptions.
**Warning signs:** A citation reads `.../latest/build-info.json`. Flag in code review.

### Pitfall 4: Missing pre-flight dependencies
**What goes wrong:** `svunit-certify-all` exits 2 on the first container target because `quartus_license.dat` is missing or the container image isn't built. Subsequent targets also fail because the aggregator continues past failed targets.
**Why it happens:** `scripts/certify.sh:76-86` checks for `$LICENSE_DIR/quartus_license.dat`, `$LICENSE_DIR/questa_license.dat`, and `podman image exists $TARGET_IMAGE`.
**How to avoid:** Plan 2's first task should run a pre-flight check — verify all 5 image tags exist (`podman image exists <tag>` for each) and both license files exist. Offer to `nix run .#svunit-quartus-tools-<base>` per Quartus base if an image is missing.
**Warning signs:** "ERROR: Missing ${LICENSE_DIR}/quartus_license.dat"; "ERROR: Container image ... not found."

### Pitfall 5: Verilator filter differs from Quartus filter
**What goes wrong:** Sign-off doc claims "pytest filter `<tool> and not uvm_simple_model`" for all 5 targets, but `verilator-5-044` uses filter `"verilator"` without the UVM exclusion.
**Why it happens:** `nix/registry.nix:96-104` defines the verilator target with `pytestFilter = "verilator"` (no `extraFilter`). Only the 4 Quartus targets take the `"not uvm_simple_model"` suffix.
**How to avoid:** Pass matrix row for verilator records its filter as `"verilator"`, not `"verilator and not uvm_simple_model"`. The per-target `build-info.json.pytest_filter` field already captures this; Plan 2 should read it rather than hard-coding.
**Warning signs:** Audit of `build-info.json.pytest_filter` across 5 targets reveals 4 different strings (one per tool) not a uniform template.

### Pitfall 6: FHS adapter stub is not a silent skip
**What goes wrong:** If a future registry change adds an `fhs` target before XFLK-01 is implemented, `svunit-certify-all` will hit an `exit 2` on that target and fail the aggregate run.
**Why it happens:** `scripts/certify.sh:105-108` treats FHS as a hard error, not a skip.
**How to avoid (Plan 2 preflight):** Verify `$SVUNIT_TARGETS` contains only `container` and `native` adapters before running. The current registry has only 5 targets, all container or native — but the planner should note this as a forward-compat check.

## Code Examples

### Deriving the pass matrix from per-target build-info.json

```bash
# Source: scripts/certify.sh output + qualification-helpers convention
ARTEFACTS_ROOT="/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts"

# After svunit-certify-all completes, list the 5 most recent build-info.json
# files (one per target). The target + run_id + status are self-describing.
ls -1 "$ARTEFACTS_ROOT" | grep -v '^latest$' | sort -r | head -5 | while read ri; do
  if [[ -f "$ARTEFACTS_ROOT/$ri/build-info.json" ]]; then
    jq -r '[.target, .run_id, .qualification_status, .tests_passed, .tests_failed, .tests_skipped, .pytest_filter] | @tsv' \
      "$ARTEFACTS_ROOT/$ri/build-info.json"
  fi
done
```

Output is a tab-separated row per target, directly convertible to a markdown pass-matrix table.

### Grep-verifying "all 5 targets PASS" for a sign-off gate check

```bash
# Source: scripts/certify.sh:262-266 pass-criteria definition
# Expects 5 build-info.json files, one per target, all with qualification_status="PASS".
ARTEFACTS_ROOT="..."
TARGETS=("quartus-23-4-qrun" "quartus-23-4-modelsim" "quartus-25-1-sim-only-qrun" "quartus-25-1-sim-only-modelsim" "verilator-5-044")

declare -A seen
for bi in "$ARTEFACTS_ROOT"/*/build-info.json; do
  target=$(jq -r '.target' "$bi")
  status=$(jq -r '.qualification_status' "$bi")
  seen[$target]="$status"
done

all_pass=1
for t in "${TARGETS[@]}"; do
  if [[ "${seen[$t]:-MISSING}" != "PASS" ]]; then
    echo "FAIL: target=$t status=${seen[$t]:-MISSING}" >&2
    all_pass=0
  fi
done
[[ "$all_pass" = "1" ]] && echo "All 5 targets PASS."
```

### Xilinx-thematic audit run (Plan 1 task action)

```bash
# Source: themes T1-T4 derived from existing tree conventions
cd "$REPO_ROOT"

# T1 audit — parser-safe queue typing
echo "=== T1: typedef ... [$] and comment markers ==="
grep -rn 'needs to be declared as a dynamic array\[\$\]' \
  svunit_base/ src/experimental/ src/test/ src/testExperimental/
echo ""
echo "=== T1 NEG: typedef ... [] without [\$] in Phase 2 imports ==="
grep -rnE 'typedef\s+\w+\s+\w+\[' svunit_base/ src/experimental/ \
  | grep -v '\[\$\]'

# T2 audit — explicit input keyword (look at Phase 2 diff specifically)
echo "=== T2: <<SLL-FIX>> markers (existing) ==="
grep -rn '<<SLL-FIX>>' svunit_base/ src/experimental/
echo ""
echo "=== T2 NEG: function signatures in Phase 2 imports lacking input ==="
git diff 84b88033590a1469a238be84d8526b25a9f29d10..HEAD -- \
  svunit_base/ src/experimental/ \
  | grep -E '^\+.*\bfunction\b' | grep -v 'input '

# T3 audit — XILINX_SIMULATOR ifdefs preserved through merge
echo "=== T3: XILINX_SIMULATOR guards ==="
grep -rn 'XILINX_SIMULATOR' svunit_base/ src/experimental/

# T4 audit — xsim runtime flags preserved per LCU-01
echo "=== T4: xsim flags in bin/ ==="
grep -nE 'xvlog|xelab|xsim\.dir|xsim\*\.\*' bin/runSVUnit bin/cleanSVUnit
```

### Locked run command (Plan 2 task action)

```bash
# Source: flake.nix:181-210 (svunitCertifyAll)
cd "$REPO_ROOT"
nix run .#svunit-certify-all 2>&1 | tee /tmp/svunit-certify-all.$(date -u +%Y%m%d-%H%M%S).log
# Exit code 0 = all 5 PASS; 1 = at least one target failed.
```

### Citing ledger rows in the sign-off doc

```markdown
### Carried-Forward Residuals

| # | ID | Ledger pointer | Summary |
|---|-----|---------------|---------|
| 1 | HR-01 | [01-human-review.md#item-hr-01](../01-fork-delta-baseline-intent-record/01-human-review.md) | Remembered baseline v3.37.0 ≠ derived merge-base 84b8803 — maintained for historical context only. |
```

## State of the Art

Not applicable — this phase does not introduce new libraries or practices. The operative tech (Nix flakes + pytest + JUnit XML + podman) was chosen pre-Phase-3 and Phase 3 consumes what already exists.

Aside: `pytest-datafiles` is pinned to `==2.0` because the SVUnit suite uses the `.as_cwd()` API removed in 3.x. [VERIFIED: `flake.nix:62-63`.] This matters for reproducibility — don't "upgrade" pytest-datafiles in the middle of a sign-off run.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Running `svunit-certify-all` on the current machine will cleanly produce 5 PASS artefact dirs given licenses/images/net are available | Focus area 2, Pitfall 4 | Sign-off is blocked on environmental prep — Plan 2 must add a preflight task. Mitigation: Plan 2 `<action>` for preflight described in Pitfall 4. |
| A2 | Two of the 5 targets will not start within the same UTC minute in practice, because Quartus container boot + version checks take 30-60s minimum | Pitfall 2 | If collision happens, one target's evidence is silently overwritten. Mitigation: Plan 2 includes a "5 distinct run-ids" check as a verification step. |
| A3 | The 31-file audit scope in focus area 5 covers every Phase-2 import that could carry a Xilinx theme | Focus area 5 | Plan 1 might miss a hit outside the scope list. Mitigation: the scope is derivable from `git diff 84b8803..HEAD` and the planner can validate by re-running that diff. |
| A4 | `<<SLL-FIX>>` is the authoritative fix-annotation convention | Focus area 1 prior-art | Plan 1 might invent a new marker. Mitigation: research calls this out; planner should lock it in Plan 1 task description. |

All four are low-to-medium risk and can be verified by the planner at task-description time without needing user confirmation.

## Open Questions

1. **Should Plan 2 preflight-build missing Quartus images, or fail if they're missing?**
   - What we know: `svunit-quartus-tools-<base>` wrappers exist (`flake.nix:149-164`) and can build images. But they require `LOCAL_INSTALLER_DIR` set to an installer tree at `$installerRoot` (which is `null` for 25.1 sim-only — it "builds via S3", per `nix/registry.nix:67`).
   - What's unclear: Whether the sign-off run should halt and ask the maintainer to build images, or attempt the build itself.
   - Recommendation: Plan 2's first task FAILS with a clear error listing missing images; does not attempt to build. Building images is a separate maintainer ritual.

2. **Is the cross-target timing report part of the sign-off doc, or a separate deliverable?**
   - What we know: `svunit-certify-all` ends with a `svunit-timing-report` pass (`flake.nix:202-203`). Output is a markdown table per hostname plus per-test comparison tables.
   - What's unclear: Whether the maintainer wants timing data inlined in `03-sign-off.md`, linked from it, or left as a Plan 2 side-artefact.
   - Recommendation: Reference only. Timing data goes into a separate `03-timing-report.md` saved at the phase dir or linked from the sign-off's "evidence" pointer list. Keeps the sign-off doc focused on pass/gap/residuals.

3. **Should the sign-off doc call out the `svunit_commit` explicitly?**
   - What we know: Each `build-info.json` records the exact `svunit_commit` the test ran against (via `git -C $REPO_ROOT rev-parse HEAD` in `scripts/certify.sh:124`). All 5 targets in a single `svunit-certify-all` run should share this hash.
   - What's unclear: Whether the sign-off doc should include it as a single top-line "Commit under test: <sha>" or as a per-target column in the pass matrix.
   - Recommendation: Both. Top-line for immediate maintainer read; per-target column as evidence-that-all-5-ran-against-the-same-commit (which is the whole point — proving a synchronised fork passes).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `nix` | Plan 2 (run `nix run .#svunit-certify-all`) | ✓ | 2.31.2 (observed in live `build-info.json`) | — |
| `podman` | Plan 2 (4 Quartus targets) | Likely ✓ (dev shell declares it; not directly probed) | — | CONTAINER_RUNTIME env var allows docker substitution, but adapter logic is podman-specific in a few places. |
| `git` | Plans 1 & 2 (diff, rev-parse) | ✓ | In repo | — |
| `jq` | Plan 2 (pass-matrix extraction) | ✓ (nixpkgs, declared in mk-certify commonRuntimeInputs) | — | — |
| Quartus 23.4 container image `localhost/quartus-pro-linux:23.4.0.79` | Plan 2 (targets 1+2) | Unknown — must preflight | Expected per `registry.nix:49` | Build via `nix run .#svunit-quartus-tools-quartus-23-4` with LOCAL_INSTALLER_DIR set |
| Quartus 25.1 sim-only image `localhost/quartus-pro-linux:25.1.1.125-sim-only` | Plan 2 (targets 3+4) | Unknown — must preflight | Expected per `registry.nix:63` | Build via `nix run .#svunit-quartus-tools-quartus-25-1-sim-only` (pulls from S3) |
| Verilator 5.044 (nix store) | Plan 2 (target 5) | ✓ (pinned in `verilator-certified` flake input) | 5.044 | — |
| `quartus_license.dat` + `questa_license.dat` at `/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch/` | Plan 2 (4 Quartus targets) | Unknown — must preflight | — | None — container pre-flight exits 2 if either missing |
| Internet / network | Container targets bootstrap pip | ✓ assumed | — | Container pytest bootstrap fetches `get-pip.py` from bootstrap.pypa.io per `scripts/certify.sh:155-159`. If the dev machine is fully offline, Quartus targets fail. Verilator target is offline-safe. |

**Missing dependencies with no fallback:**
- License files (must be pre-placed by maintainer)

**Missing dependencies with fallback:**
- Quartus container images (buildable via `svunit-quartus-tools-<base>` wrappers)

**Planner instruction:** Plan 2's first task should `podman image exists` for each of the 4 Quartus image tags AND verify the 2 license files exist. If any check fails, emit a clear error listing what's missing and how to resolve it.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | shell + grep (Plan 1 audit); `nix run` + jq + grep (Plan 2 sign-off) — neither plan needs a Python test framework of its own |
| Config file | none — Plan 1 uses grep scripts inline in task actions; Plan 2 uses the existing flake + certify.sh |
| Quick run command | Plan 1: `grep -rn '<<SLL-FIX>>\|XILINX_SIMULATOR\|needs to be declared as a dynamic array\[\$\]' svunit_base/ src/experimental/` (< 1s). Plan 2: `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json | sort -u` (< 1s once artefacts exist) |
| Full suite command | Plan 2: `nix run .#svunit-certify-all` (20-60 min estimated — 5 sequential targets; no prior run on this machine to benchmark) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VERI-01 | Maintainer can run the required regression flow via the certified Quartus flake | smoke | `nix flake show 2>&1 \| grep -c 'svunit-certify'` ≥ 6 (5 per-target + 1 aggregate) | existing — `flake.nix` |
| VERI-01 | Preflight: licenses + images present before the aggregate run starts | smoke | `test -f $LICENSE_DIR/quartus_license.dat && test -f $LICENSE_DIR/questa_license.dat && podman image exists <each-tag>` | existing files |
| VERI-02 | Synchronised fork passes the regression suite | integration | `nix run .#svunit-certify-all` returns exit code 0 AND `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json \| sort -u` is exactly `PASS` (single value) with 5 occurrences (one per target) | created by certify-all |
| VERI-02 | Each target recorded with pytest filter, commit, and status | content | `jq 'has("target") and has("pytest_filter") and has("svunit_commit") and has("qualification_status")' "$ARTEFACTS_ROOT/<each-run>/build-info.json"` ≡ true | created by certify-all |
| VERI-03 | Sign-off doc records tooling paths, commands, and gaps | doc-structure | `grep -c '^## ' "03-sign-off.md"` returns count matching expected heading set; `grep -q 'VERI-01' "03-sign-off.md" && grep -q 'VERI-02' "03-sign-off.md" && grep -q 'VERI-03' "03-sign-off.md"` | created by Plan 2 task 2 |
| VERI-03 | Gap matrix has D-05's 5 columns | doc-structure | `grep -A 1 'Dimension \| Covered \| Not covered \| Why deferred \| Owner / next phase' "03-sign-off.md"` returns the header + separator line | created by Plan 2 task 2 |
| VERI-03 | Carried-forward residuals reference 7 explicit ledger IDs | doc-structure | `grep -qE 'HR-01\|HR-02\|LCU-01\|LCU-03\|LCU-04\|HR-03\|HR-04' "03-sign-off.md"` returns match for each | created by Plan 2 task 2 |
| Plan 1 | Xilinx audit report covers all 4 themes | doc-structure | `grep -qE 'T1\|T2\|T3\|T4' "03-xilinx-thematics-audit.md"` (or the section headings `Parser-safe queue typing`, `Explicit.*input.*signature`, `XILINX_SIMULATOR`, `xsim.*runtime`) | created by Plan 1 task |
| Plan 1 | Audit classifies each finding as A/B/C | doc-structure | `grep -cE '\b(class A\|class B\|class C\|clear fix needed\|ambiguous\|consistent)\b' "03-xilinx-thematics-audit.md"` ≥ N (where N is number of findings) | created by Plan 1 task |

### Sampling Rate

- **Per task commit:** Plan 1 — run the 4-theme grep; Plan 2 — if the task touches `03-sign-off.md`, grep the doc for the required headings and gap-matrix columns.
- **Per wave merge:** Plan 2 — `nix run .#svunit-certify-all` once per wave that writes or updates the sign-off doc (expensive — 20-60 min; probably one per plan, not per task).
- **Phase gate:** `jq -r '.qualification_status' "$ARTEFACTS_ROOT"/*/build-info.json | sort -u` == `PASS` (single line), AND `03-sign-off.md` doc-structure greps all pass, before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] No test file creation needed — Plan 1 and Plan 2 both use inline shell + grep + jq as their validation. No pytest suites to add.
- [ ] No framework install needed — nix, jq, grep, podman are all already in the dev shell or the host.
- [ ] If Plan 2 opts for a reproducibility script (optional per D-06), that script itself needs a `bash -n` syntax check — Wave 0 would cover that.

*(No Wave 0 gaps beyond the optional reproducibility-script syntax check.)*

## Security Domain

`security_enforcement` is not explicitly set in `.planning/config.json` — treated as enabled per the research prompt default. However, this phase is a **documentation + orchestration phase**: it reads existing artefacts, runs an already-audited regression tool, and writes markdown. No new code paths that process untrusted input are introduced.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 3 doesn't introduce auth surface. |
| V3 Session Management | no | No sessions. |
| V4 Access Control | partial | The qualification artefacts root (`/srv/share/repo/sll/...`) is on a shared filesystem. Sign-off doc cites paths the maintainer's reviewers need read access to. Plan 2 should note the required access path. |
| V5 Input Validation | no | Plan 1 grep + Plan 2 jq work on repo-controlled + flake-generated inputs. No external inputs. |
| V6 Cryptography | no | No crypto. License files are touched as `-f` checks only. |
| V10 Secrets | partial | `quartus_license.dat` and `questa_license.dat` are FlexLM licenses, not credentials in the traditional sense. They must remain outside git; Plan 2 must NOT copy them into the repo or the sign-off doc. |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sign-off doc accidentally embeds license content | Information Disclosure | Don't `cat $LICENSE_DIR/*` in any task. License files stay at their canonical path; sign-off doc cites the path only. |
| Sign-off doc cites a stale run-id after artefacts rotation | Tampering (unintentional) | Use explicit run-id strings, not `latest`. D-04 already locks this. Plan 2 task description must repeat it. |
| Xilinx audit task reads outside scope | scope creep | Audit scope locked to the 31-file list in focus area 5. Grep commands constrain via explicit file/directory args. |
| `svunit-certify-all` runs stray pytest against the wrong repo state | Tampering | `build-info.json` records `svunit_commit` from `git rev-parse HEAD`. Plan 2's sign-off doc cites that hash — a post-hoc reviewer can `git checkout` and reproduce. |

## Sources

### Primary (HIGH confidence)

- **In-repo flake and scripts:**
  - `/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/flake.nix` — aggregator, artefact root, target enumeration
  - `/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/nix/registry.nix` — 5 target definitions
  - `/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/nix/mk-certify.nix` — env-var surface
  - `/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/scripts/certify.sh` — pass criteria + adapter dispatch
  - `/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/scripts/timing-summary.py`, `scripts/timing-report.py` — derived artefacts
  - `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_sll_tools_qualified/r_cert_tools/scripts/qualification-helpers.sh` — `qh_*` functions (run-id construction, latest-symlink behaviour, build-info writer)

- **Live artefacts root (verified on disk):**
  - `/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts/` — 3 run-id dirs + `latest` symlink, all with the expected 5-file artefact set for verilator runs

- **Phase 1+2 artefacts (verbatim sources for residuals):**
  - `.planning/phases/01-fork-delta-baseline-intent-record/01-human-review.md` (HR-01..HR-04)
  - `.planning/phases/01-fork-delta-baseline-intent-record/01-upstream-baseline.json` (merge-base, marker hashes)
  - `.planning/phases/02-history-aware-upstream-integration/02-decision-ledger.md` (LCU-01..LCU-06 + HR carry-forwards)
  - `.planning/phases/02-history-aware-upstream-integration/02-integration-summary.md` (requirement coverage precedent)
  - `.planning/phases/02-history-aware-upstream-integration/02-human-review.md` (Phase 2 carry-forward format)
  - `.planning/phases/02-history-aware-upstream-integration/02-integration-baseline.json` (merge-base confirmation)
  - `.planning/phases/02-history-aware-upstream-integration/02-VALIDATION.md` (validation table convention)

- **Git history evidence:**
  - `git show --stat 27232c2` — Phase 2 upstream merge (51 files, 935+/167-)
  - `git show 475a9d9` — Xilinx signature sweep (16 `<<SLL-FIX>>` markers across 8 files)
  - `git diff 84b88033590a1469a238be84d8526b25a9f29d10..HEAD` — full Phase 2 import diff
  - `git log 84b88033590a1469a238be84d8526b25a9f29d10..HEAD` — 45 commits between merge-base and HEAD

- **Codebase context docs:**
  - `.planning/codebase/STACK.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`
  - `.planning/todos/pending/2026-04-12-audit-imported-changes-for-xilinx-thematics.md` — Plan 1 scope source

### Secondary (MEDIUM confidence)

None used — all claims are verified against in-repo or on-disk artefacts.

### Tertiary (LOW confidence)

None — no WebSearch, Context7, or WebFetch was needed for this phase, which is entirely grounded in the existing repo + qualification tooling.

## Metadata

**Confidence breakdown:**

- **Xilinx-thematic checklist (focus area 1):** HIGH — all four themes have concrete prior-art evidence in the tree (grep-counted). `<<SLL-FIX>>` marker has 16 occurrences; `XILINX_SIMULATOR` ifdef has 4 distinct sites; parser-safe queue typing has 9 marker-comment occurrences; xsim flag set is explicit in `bin/runSVUnit` and `bin/cleanSVUnit`.
- **svunit-certify-all invocation (focus area 2):** HIGH — every field traced to an exact file:line in `flake.nix`, `nix/registry.nix`, `nix/mk-certify.nix`, or `scripts/certify.sh`. Live artefacts root contents verified on disk.
- **Sign-off doc conventions (focus area 3):** HIGH — three Phase 2 artefacts plus `01-human-review.md` provide unambiguous precedent.
- **Residuals catalog (focus area 4):** HIGH — all 7 rows have explicit source rows in `01-human-review.md` or `02-decision-ledger.md`.
- **Phase 2 import surface (focus area 5):** HIGH — derived from `git show --stat 27232c2` (51 files) and confirmed against `git diff --stat 84b88033..HEAD` (matches).
- **Run-id collision risk (Pitfall 2):** HIGH — `qh_build_run_id` source inspected at line 149 of `qualification-helpers.sh`; minute-granular timestamp confirmed; live artefacts root has 3 distinct minute-stamped dirs supporting the risk model.

**Research date:** 2026-04-18
**Valid until:** Until the flake inputs or `scripts/certify.sh` are restructured. Stable-moving tech (Nix + pytest + JUnit). 60 days as a soft expiry.

---

## RESEARCH COMPLETE

**Phase:** 3 - Quartus Verification & Sign-Off
**Confidence:** HIGH

### Key Findings

1. **`svunit-certify-all` is turn-key.** Plan 2 is orchestration + authoring — the regression tooling is complete. Exact command, artefact shape, PASS-signal grep patterns, run-id construction, and `latest` semantics all documented with file:line citations.
2. **Run-id minute collision is a real risk.** `qh_build_run_id` uses `date -u +%Y%m%d-%H%M` with no uniqueness guard. If two of the 5 targets complete within the same UTC minute, one silently overwrites the other. Plan 2 needs a "5 distinct run-ids" verification step.
3. **Xilinx themes have precedent and grep heuristics.** Four themes (T1 parser-safe queue typing, T2 explicit `input` signatures, T3 `XILINX_SIMULATOR` ifdefs, T4 xsim runtime flags) — each with concrete grep commands and 4-16 existing occurrences in the tree. The `<<SLL-FIX>>` marker convention (16 occurrences) is the established fix-annotation pattern.
4. **Plan 1 audit scope is derivable and bounded.** 31 SV/Perl/Python files from the Phase 2 merge commit (`27232c2`) in 6 directories. Noise files (goldens, pytest regressions, infra) explicitly excluded with rationale.
5. **7 residuals catalogued verbatim** with ledger pointers (`HR-01`, `HR-02`, `LCU-01`, `LCU-03`, `LCU-04`, `HR-03`, `HR-04`) — Plan 2 can copy these into the sign-off doc without reading the ledgers again.
6. **All 3 requirements (VERI-01/02/03) have grep-verifiable observables.** No behavior depends on human judgement beyond the maintainer reviewing the final doc.

### File Created

`/srv/share/repo/pub/com/github/synaptic-laboratories/svunit_x/.planning/phases/03-quartus-verification-sign-off/03-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | No new libraries introduced; everything traced to `flake.nix`. |
| Architecture | HIGH | Two-plan decomposition matches CONTEXT D-06 and requirements map cleanly. |
| Pitfalls | HIGH | Six pitfalls identified with code:line evidence; run-id collision is a surprise the planner needs to see. |
| Residuals catalog | HIGH | All 7 items have direct ledger rows. |
| Audit scope | HIGH | 51-file stat confirmed by two independent git commands. |

### Open Questions

Three open questions in the Open Questions section above (image preflight policy, timing-report inlining vs. sibling file, svunit_commit placement). All have recommended answers the planner can lock during planning without further user input.

### Ready for Planning

Research complete. Planner can now create `03-01-PLAN.md` and `03-02-PLAN.md`.
