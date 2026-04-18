#!/usr/bin/env bash
# 03-reproduce.sh — Reproducibility companion to 03-sign-off.md (D-07).
# Contract: drives each per-target certify app into a unique per-target output-dir,
# writes a phase-dir-resident manifest TSV the sign-off doc templates against, and
# jq-verifies PASS semantically. Does NOT author or commit the sign-off doc — that
# stays a human-in-the-loop step so gap-matrix and residuals sections can be
# re-judged against the new run.
#
# Usage:
#   bash .planning/phases/03-quartus-verification-sign-off/03-reproduce.sh [--manifest PATH] [--smoke-aggregate]
#
# Preconditions:
#   - cwd must be the SVUnit repo root (Setup.bsh present)
#   - license files + container images + ARTEFACTS_ROOT present (see preflight)
#   - host has: jq, awk, comm, tee, flock, podman, nix, git, curl
#   - network access to bootstrap.pypa.io (scripts/certify.sh:153-160 fetches get-pip.py
#     inside the container each run). If offline, preflight fails fast with a clear error.
#
# Output:
#   - .planning/phases/03-quartus-verification-sign-off/03-sign-off-manifest.tsv
#     (overridable via --manifest). Committed alongside 03-sign-off.md.
#     Columns: target  run_id  qualification_status  tests_passed  tests_failed
#              tests_skipped  pytest_filter  svunit_commit  evidence_path
#   - Exit code 0 iff all 5 targets PASS jq-semantically.

set -euo pipefail

ARTEFACTS_ROOT="/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts"
LICENSE_DIR="/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch"
PHASE_DIR=".planning/phases/03-quartus-verification-sign-off"
DEFAULT_MANIFEST="$PHASE_DIR/03-sign-off-manifest.tsv"

# Per-target nix app attrs driven below (full names listed here for grep-ability
# and so a reader can audit the attribute set this script binds against):
#   svunit-certify-quartus-23-4-qrun
#   svunit-certify-quartus-23-4-modelsim
#   svunit-certify-quartus-25-1-sim-only-qrun
#   svunit-certify-quartus-25-1-sim-only-modelsim
#   svunit-certify-verilator-5-044
EXPECTED_TARGETS=(
  "quartus-23-4-qrun"
  "quartus-23-4-modelsim"
  "quartus-25-1-sim-only-qrun"
  "quartus-25-1-sim-only-modelsim"
  "verilator-5-044"
)
EXPECTED_IMAGES=(
  "localhost/quartus-pro-linux:23.4.0.79"
  "localhost/quartus-pro-linux:25.1.1.125-sim-only"
)

# Per-target pytest filter (documented here for the manifest; build-info.json is truth)
declare -A PYTEST_FILTERS=(
  ["quartus-23-4-qrun"]="qrun and not uvm_simple_model"
  ["quartus-23-4-modelsim"]="modelsim and not uvm_simple_model"
  ["quartus-25-1-sim-only-qrun"]="qrun and not uvm_simple_model"
  ["quartus-25-1-sim-only-modelsim"]="modelsim and not uvm_simple_model"
  ["verilator-5-044"]="verilator"
)

SESSION_STAMP="$(date -u +%Y%m%d-%H%M%S)-$(printf '%08x' $RANDOM$RANDOM)"
MANIFEST="$DEFAULT_MANIFEST"
SMOKE_AGGREGATE=0

# --- flag parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2 ;;
    --smoke-aggregate) SMOKE_AGGREGATE=1; shift ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "ERROR: unknown flag: $1" >&2; exit 2 ;;
  esac
done

echo "[session] stamp=$SESSION_STAMP  manifest=$MANIFEST"

# ------------------------------------------------------------------
# Preflight A — required host tools (review concern #6)
# ------------------------------------------------------------------
echo "[preflight] host tools..."
REQUIRED_TOOLS=(jq awk comm tee flock podman nix git curl)
missing=()
for t in "${REQUIRED_TOOLS[@]}"; do
  command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  echo "FAIL: missing host tools: ${missing[*]}" >&2
  echo "      install them (e.g. via nix develop or the qualified dev shell) and retry." >&2
  exit 2
fi

# ------------------------------------------------------------------
# Preflight B — repo root
# ------------------------------------------------------------------
echo "[preflight] repo root..."
test -f Setup.bsh || { echo "FAIL: Setup.bsh not found — run from SVUnit repo root" >&2; exit 2; }

# ------------------------------------------------------------------
# Preflight C — license files (container adapter)
# ------------------------------------------------------------------
echo "[preflight] license files..."
for f in quartus_license.dat questa_license.dat; do
  test -f "$LICENSE_DIR/$f" || { echo "FAIL: missing $LICENSE_DIR/$f" >&2; exit 2; }
done

# ------------------------------------------------------------------
# Preflight D — container images
# ------------------------------------------------------------------
echo "[preflight] container images..."
for img in "${EXPECTED_IMAGES[@]}"; do
  podman image exists "$img" || { echo "FAIL: missing podman image $img" >&2; exit 2; }
done

# ------------------------------------------------------------------
# Preflight E — artefacts root (exists + writable). Tolerates the case
# where the root itself was pruned: certify.sh:121-122 does `mkdir -p`,
# so we only require the PARENT is writable if the root is absent.
# ------------------------------------------------------------------
echo "[preflight] artefacts root..."
if [[ -d "$ARTEFACTS_ROOT" ]]; then
  test -w "$ARTEFACTS_ROOT" || { echo "FAIL: ARTEFACTS_ROOT not writable: $ARTEFACTS_ROOT" >&2; exit 2; }
else
  parent="$(dirname "$ARTEFACTS_ROOT")"
  test -d "$parent" && test -w "$parent" \
    || { echo "FAIL: ARTEFACTS_ROOT and its parent are both absent/non-writable: $ARTEFACTS_ROOT" >&2; exit 2; }
  mkdir -p "$ARTEFACTS_ROOT"
fi

# ------------------------------------------------------------------
# Preflight F — offline check (scripts/certify.sh:153-160 downloads get-pip.py)
# ------------------------------------------------------------------
echo "[preflight] network (bootstrap.pypa.io)..."
if ! curl -Isf --max-time 10 https://bootstrap.pypa.io/get-pip.py >/dev/null 2>&1; then
  echo "FAIL: cannot reach https://bootstrap.pypa.io/get-pip.py" >&2
  echo "      scripts/certify.sh:153-160 fetches get-pip.py inside the container each run." >&2
  echo "      Either go online, or pre-cache pip into the container images (out of scope here)." >&2
  exit 2
fi

# ------------------------------------------------------------------
# Preflight G — flake visibility (structural; not brittle text grep)
# ------------------------------------------------------------------
echo "[preflight] nix flake apps..."
for t in "${EXPECTED_TARGETS[@]}"; do
  # `nix eval` on the app attr is deterministic; does not depend on `flake show` text output.
  if ! nix eval --raw ".#apps.$(uname -m)-linux.svunit-certify-${t}.program" >/dev/null 2>&1; then
    echo "FAIL: nix flake does not expose apps.<system>.svunit-certify-${t}" >&2
    echo "      check flake.nix or run 'nix flake show .'" >&2
    exit 2
  fi
done
# The aggregate is optional (smoke only); verify only if --smoke-aggregate requested.
if [[ "$SMOKE_AGGREGATE" -eq 1 ]]; then
  nix eval --raw ".#apps.$(uname -m)-linux.svunit-certify-all.program" >/dev/null 2>&1 \
    || { echo "FAIL: --smoke-aggregate requested but svunit-certify-all not exposed" >&2; exit 2; }
fi

# ------------------------------------------------------------------
# Preflight H — concurrency lock (review concern #1)
# ------------------------------------------------------------------
echo "[preflight] acquiring sign-off lock..."
LOCKFILE="$ARTEFACTS_ROOT/.svunit-signoff.lock"
touch "$LOCKFILE"
exec 9<"$LOCKFILE"
flock -n 9 || { echo "FAIL: another sign-off session holds $LOCKFILE; wait or abort that one" >&2; exit 2; }

echo "OK: preflight complete."

# ------------------------------------------------------------------
# Drive the 5 per-target runs with explicit unique output-dirs.
# Each target writes to $ARTEFACTS_ROOT/${SESSION_STAMP}--${target}.
# ------------------------------------------------------------------
declare -A OUTDIRS
for t in "${EXPECTED_TARGETS[@]}"; do
  OUTDIRS[$t]="$ARTEFACTS_ROOT/${SESSION_STAMP}--${t}"
done

# Probe: does the app wrapper accept `-- --output-dir PATH`, or must we export
# OUTPUT_DIR? The app wrapper is a writeShellApplication that execs certify.sh;
# certify.sh reads OUTPUT_DIR as env (line 121). The passthrough form we rely on
# is `OUTPUT_DIR=<path> nix run ...` because `nix run ... -- <extra_args>` passes
# args to the program, which certify.sh does not parse. This is the documented
# contract; if nix/mk-certify.nix ever adds flag parsing, switch to that form.

RUN_LOG="$PHASE_DIR/03-reproduce-${SESSION_STAMP}.log"
touch "$RUN_LOG"

run_target() {
  local target="$1"
  local outdir="${OUTDIRS[$target]}"
  echo "=============================================" | tee -a "$RUN_LOG"
  echo "[run] target=$target outdir=$outdir" | tee -a "$RUN_LOG"
  echo "=============================================" | tee -a "$RUN_LOG"
  # certify.sh:121 respects OUTPUT_DIR env; so does the wrapper (it only exports
  # target metadata and execs certify.sh with the current env).
  OUTPUT_DIR="$outdir" nix run ".#svunit-certify-${target}" 2>&1 | tee -a "$RUN_LOG"
  local rc=${PIPESTATUS[0]}
  echo "[run] target=$target exit=$rc" | tee -a "$RUN_LOG"
  return "$rc"
}

FAILED_TARGETS=()
for t in "${EXPECTED_TARGETS[@]}"; do
  if ! run_target "$t"; then
    FAILED_TARGETS+=("$t")
  fi
done

# ------------------------------------------------------------------
# Write manifest from known paths + jq-extracted fields.
# Single source of truth: the 5 unique OUTDIRS. No /tmp.
# ------------------------------------------------------------------
mkdir -p "$(dirname "$MANIFEST")"
{
  printf 'target\trun_id\tqualification_status\ttests_passed\ttests_failed\ttests_skipped\tpytest_filter\tsvunit_commit\tevidence_path\n'
  for t in "${EXPECTED_TARGETS[@]}"; do
    outdir="${OUTDIRS[$t]}"
    bi="$outdir/build-info.json"
    if [[ -f "$bi" ]]; then
      jq -r --arg t "$t" --arg p "$outdir" '
        [ .target,
          .run_id,
          .qualification_status,
          (.tests_passed // 0),
          (.tests_failed // 0),
          (.tests_skipped // 0),
          (.pytest_filter // ""),
          (.svunit_commit // ""),
          $p ] | @tsv' "$bi"
    else
      printf '%s\tMISSING\tMISSING\t0\t0\t0\t%s\tMISSING\t%s\n' \
        "$t" "${PYTEST_FILTERS[$t]:-}" "$outdir"
    fi
  done
} > "$MANIFEST"

echo "[manifest] wrote $MANIFEST"

# ------------------------------------------------------------------
# Validate manifest semantically via jq (review concern #5).
# ------------------------------------------------------------------
fail=0

# (a) row count check (header + 5 rows == 6 lines)
rows="$(awk 'NR>1' "$MANIFEST" | wc -l)"
if [[ "$rows" -ne 5 ]]; then
  echo "FAIL: manifest has $rows data rows (expected 5)" >&2
  fail=1
fi

# (b) exact target membership
for t in "${EXPECTED_TARGETS[@]}"; do
  if ! awk -F'\t' -v t="$t" 'NR>1 && $1 == t {found=1} END {exit !found}' "$MANIFEST"; then
    echo "FAIL: expected target '$t' not present in manifest" >&2
    fail=1
  fi
done

# (c) all rows PASS semantically in build-info.json
while IFS=$'\t' read -r target run_id status tp tf ts pf sc epath; do
  [[ "$target" == "target" ]] && continue      # header
  bi="$epath/build-info.json"
  if [[ ! -f "$bi" ]]; then
    echo "FAIL: build-info.json missing at $bi (target $target)" >&2
    fail=1; continue
  fi
  bi_target="$(jq -r '.target' "$bi")"
  bi_status="$(jq -r '.qualification_status' "$bi")"
  bi_failed="$(jq -r '.tests_failed // 0' "$bi")"
  bi_errors="$(jq -r '.tests_errors // 0' "$bi")"
  bi_passed="$(jq -r '.tests_passed // 0' "$bi")"
  if [[ "$bi_target" != "$target" ]]; then
    echo "FAIL: build-info.json target=$bi_target != row target=$target ($bi)" >&2
    fail=1
  fi
  if [[ "$bi_status" != "PASS" ]]; then
    echo "FAIL: target=$target qualification_status=$bi_status (expected PASS) at $bi" >&2
    fail=1
  fi
  if [[ "$bi_failed" -ne 0 || "$bi_errors" -ne 0 || "$bi_passed" -lt 1 ]]; then
    echo "FAIL: target=$target raw counters failed/errors/passed = $bi_failed/$bi_errors/$bi_passed" >&2
    fail=1
  fi
done < "$MANIFEST"

# (d) single svunit_commit across all rows (regression consistency check)
distinct_commits="$(awk -F'\t' 'NR>1 {print $8}' "$MANIFEST" | sort -u | wc -l)"
if [[ "$distinct_commits" -ne 1 ]]; then
  echo "FAIL: manifest contains $distinct_commits distinct svunit_commit values (expected 1)" >&2
  fail=1
fi

if [[ ${#FAILED_TARGETS[@]} -gt 0 ]]; then
  echo "FAIL: ${#FAILED_TARGETS[@]} targets had non-zero exit: ${FAILED_TARGETS[*]}" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "NOT OK — inspect $MANIFEST and $RUN_LOG" >&2
  exit 1
fi

echo "OK — 5 targets PASS with 5 unique output-dirs. Sign-off doc inputs ready."
echo "     Manifest: $MANIFEST"
echo "     Log:      $RUN_LOG"
echo "     Next:     template the manifest into $PHASE_DIR/03-sign-off.md §Pass Matrix"
exit 0
