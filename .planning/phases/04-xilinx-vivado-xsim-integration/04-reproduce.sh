#!/usr/bin/env bash
# 04-reproduce.sh - Phase 4 all-six sign-off companion.
#
# Usage:
#   bash .planning/phases/04-xilinx-vivado-xsim-integration/04-reproduce.sh [--manifest PATH] [--performance PATH]
#   bash .planning/phases/04-xilinx-vivado-xsim-integration/04-reproduce.sh --reuse-session SESSION_STAMP
#
# Output:
#   - .planning/phases/04-xilinx-vivado-xsim-integration/04-sign-off-manifest.tsv
#   - .planning/phases/04-xilinx-vivado-xsim-integration/04-reproduce-<session>.log
#
# Exit code 0 iff all six targets PASS jq-semantically and the Vivado smoke
# evidence is present in the Vivado target output directory. With
# --reuse-session, validates and summarizes an existing session without
# rerunning the targets.

set -euo pipefail

ARTEFACTS_ROOT="/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_svunit_x/r_v3_38_1_x0_2_0_artefacts"
LICENSE_DIR="/srv/share/repo/sll/g_sll_poc/g_2026/ContainerPlayPen/launch"
PHASE_DIR=".planning/phases/04-xilinx-vivado-xsim-integration"
DEFAULT_MANIFEST="$PHASE_DIR/04-sign-off-manifest.tsv"
DEFAULT_PERFORMANCE="$PHASE_DIR/04-performance-summary.tsv"
VIVADO_TARGET="vivado-2025-2-1-synth-sim-full-xsim"
EXPECTED_VIVADO_VERSION="2025.2.1"
EXPECTED_VIVADO_PROFILE="synth-sim-full"
EXPECTED_VIVADO_ROOT="/srv/share/repo/sll/g_sll_infra/g_sll_infra_dev_001/g_ext_tools_qualified/g_xilinx_vivado/r_src_v2025_1"

EXPECTED_TARGETS=(
  "quartus-23-4-qrun"
  "quartus-23-4-modelsim"
  "quartus-25-1-sim-only-qrun"
  "quartus-25-1-sim-only-modelsim"
  "verilator-5-044"
  "$VIVADO_TARGET"
)

EXPECTED_IMAGES=(
  "localhost/quartus-pro-linux:23.4.0.79"
  "localhost/quartus-pro-linux:25.1.1.125-sim-only"
)

declare -A PYTEST_FILTERS=(
  ["quartus-23-4-qrun"]="qrun and not uvm_simple_model"
  ["quartus-23-4-modelsim"]="modelsim and not uvm_simple_model"
  ["quartus-25-1-sim-only-qrun"]="qrun and not uvm_simple_model"
  ["quartus-25-1-sim-only-modelsim"]="modelsim and not uvm_simple_model"
  ["verilator-5-044"]="verilator"
  ["$VIVADO_TARGET"]="xsim"
)

SESSION_STAMP="$(date -u +%Y%m%d-%H%M%S)-$(printf '%08x' "$RANDOM$RANDOM")"
MANIFEST="$DEFAULT_MANIFEST"
PERFORMANCE="$DEFAULT_PERFORMANCE"
REUSE_SESSION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2 ;;
    --performance) PERFORMANCE="$2"; shift 2 ;;
    --reuse-session) SESSION_STAMP="$2"; REUSE_SESSION=1; shift 2 ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "ERROR: unknown flag: $1" >&2; exit 2 ;;
  esac
done

echo "[session] stamp=$SESSION_STAMP manifest=$MANIFEST performance=$PERFORMANCE reuse=$REUSE_SESSION"

echo "[preflight] host tools..."
REQUIRED_TOOLS=(jq awk sed grep tee flock podman nix git curl timeout)
missing=()
for tool in "${REQUIRED_TOOLS[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  echo "FAIL: missing host tools: ${missing[*]}" >&2
  exit 2
fi

echo "[preflight] repo root..."
test -f Setup.bsh || { echo "FAIL: Setup.bsh not found - run from repo root" >&2; exit 2; }

echo "[preflight] license files..."
for file in quartus_license.dat questa_license.dat; do
  test -f "$LICENSE_DIR/$file" || { echo "FAIL: missing $LICENSE_DIR/$file" >&2; exit 2; }
done

echo "[preflight] container images..."
for image in "${EXPECTED_IMAGES[@]}"; do
  podman image exists "$image" || { echo "FAIL: missing podman image $image" >&2; exit 2; }
done

echo "[preflight] artefacts root..."
if [[ -d "$ARTEFACTS_ROOT" ]]; then
  test -w "$ARTEFACTS_ROOT" || { echo "FAIL: ARTEFACTS_ROOT not writable: $ARTEFACTS_ROOT" >&2; exit 2; }
else
  parent="$(dirname "$ARTEFACTS_ROOT")"
  test -d "$parent" && test -w "$parent" \
    || { echo "FAIL: cannot create ARTEFACTS_ROOT: $ARTEFACTS_ROOT" >&2; exit 2; }
  mkdir -p "$ARTEFACTS_ROOT"
fi

echo "[preflight] network (bootstrap.pypa.io for Quartus container bootstrap)..."
if ! curl -Isf --max-time 10 https://bootstrap.pypa.io/get-pip.py >/dev/null 2>&1; then
  echo "FAIL: cannot reach https://bootstrap.pypa.io/get-pip.py" >&2
  exit 2
fi

echo "[preflight] flake apps..."
system="$(uname -m)-linux"
for target in "${EXPECTED_TARGETS[@]}"; do
  nix eval --raw ".#apps.${system}.svunit-certify-${target}.program" >/dev/null \
    || { echo "FAIL: app not exposed: svunit-certify-${target}" >&2; exit 2; }
done
nix eval --raw ".#apps.${system}.svunit-certify-all.program" >/dev/null \
  || { echo "FAIL: aggregate app not exposed: svunit-certify-all" >&2; exit 2; }

echo "[preflight] aggregate wrapper membership..."
aggregate_pkg="$(nix build .#svunit-certify-all --no-link --print-out-paths 2>/dev/null)"
for target in "${EXPECTED_TARGETS[@]}"; do
  grep -q "Target: ${target}" "$aggregate_pkg/bin/svunit-certify-all" \
    || { echo "FAIL: aggregate wrapper missing target: $target" >&2; exit 2; }
done

echo "[preflight] acquiring sign-off lock..."
LOCKFILE="$ARTEFACTS_ROOT/.svunit-signoff.lock"
touch "$LOCKFILE"
exec 9<"$LOCKFILE"
flock -n 9 || { echo "FAIL: another sign-off session holds $LOCKFILE" >&2; exit 2; }

mkdir -p "$PHASE_DIR"
RUN_LOG="$PHASE_DIR/04-reproduce-${SESSION_STAMP}.log"
touch "$RUN_LOG"

declare -A OUTDIRS
for target in "${EXPECTED_TARGETS[@]}"; do
  OUTDIRS[$target]="$ARTEFACTS_ROOT/${SESSION_STAMP}--${target}"
done

run_target() {
  local target="$1"
  local outdir="${OUTDIRS[$target]}"
  echo "=============================================" | tee -a "$RUN_LOG"
  echo "[run] target=$target outdir=$outdir" | tee -a "$RUN_LOG"
  echo "=============================================" | tee -a "$RUN_LOG"
  nix run ".#svunit-certify-${target}" -- --output-dir "$outdir" 2>&1 | tee -a "$RUN_LOG"
  local rc=${PIPESTATUS[0]}
  echo "[run] target=$target exit=$rc" | tee -a "$RUN_LOG"
  return "$rc"
}

FAILED_TARGETS=()
if [[ "$REUSE_SESSION" -eq 0 ]]; then
  for target in "${EXPECTED_TARGETS[@]}"; do
    if ! run_target "$target"; then
      FAILED_TARGETS+=("$target")
    fi
  done
else
  echo "[reuse] skipping target execution; validating existing output directories" | tee -a "$RUN_LOG"
  for target in "${EXPECTED_TARGETS[@]}"; do
    test -d "${OUTDIRS[$target]}" \
      || { echo "FAIL: missing reused output directory for $target: ${OUTDIRS[$target]}" >&2; exit 1; }
  done
fi

mkdir -p "$(dirname "$MANIFEST")"
{
  printf 'target\trun_id\tqualification_status\ttests_passed\ttests_failed\ttests_errors\ttests_skipped\tpytest_filter\tsvunit_commit\tsimulator\tsimulator_display\tvivado_version\tvivado_profile\tvivado_is_stub\tevidence_path\tper_fixture_tests_passed\tper_fixture_tests_failed\tper_fixture_tests_errors\tper_fixture_tests_skipped\tcompile_once_tests_passed\tcompile_once_tests_failed\tcompile_once_tests_errors\tcompile_once_tests_skipped\n'
  for target in "${EXPECTED_TARGETS[@]}"; do
    outdir="${OUTDIRS[$target]}"
    bi="$outdir/build-info.json"
    if [[ -f "$bi" ]]; then
      jq -r --arg path "$outdir" '
        [
          .target,
          .run_id,
          .qualification_status,
          (.tests_passed // 0),
          (.tests_failed // 0),
          (.tests_errors // 0),
          (.tests_skipped // 0),
          (.pytest_filter // ""),
          (.svunit_commit // ""),
          (.simulator // ""),
          (.simulator_display // ""),
          (.vivado_version // ""),
          (.vivado_profile // ""),
          (if has("vivado_is_stub") then (.vivado_is_stub | tostring) else "" end),
          $path,
          (.per_fixture_tests_passed // .tests_passed // 0),
          (.per_fixture_tests_failed // .tests_failed // 0),
          (.per_fixture_tests_errors // .tests_errors // 0),
          (.per_fixture_tests_skipped // .tests_skipped // 0),
          (.compile_once_tests_passed // 0),
          (.compile_once_tests_failed // 0),
          (.compile_once_tests_errors // 0),
          (.compile_once_tests_skipped // 0)
        ] | @tsv' "$bi"
    else
      printf '%s\tMISSING\tMISSING\t0\t0\t0\t0\t%s\tMISSING\tMISSING\tMISSING\t\t\t\t%s\t0\t0\t0\t0\t0\t0\t0\t0\n' \
        "$target" "${PYTEST_FILTERS[$target]:-}" "$outdir"
    fi
  done
} > "$MANIFEST"

echo "[manifest] wrote $MANIFEST"

mkdir -p "$(dirname "$PERFORMANCE")"
vivado_timing="${OUTDIRS[$VIVADO_TARGET]}/timing-summary.json"
vivado_wall="$(jq -r '.wall_time_s // empty' "$vivado_timing")"
{
  printf 'target\tsimulator\ttests_total\twall_time_s\tsum_test_duration_s\tmax_test_duration_s\tvivado_wall_over_target_wall\tevidence_path\tcompile_once_tests_total\tcompile_once_wall_time_s\tcompile_once_sum_test_duration_s\tcompile_once_max_test_duration_s\n'
  for target in "${EXPECTED_TARGETS[@]}"; do
    outdir="${OUTDIRS[$target]}"
    timing="$outdir/timing-summary.json"
    compile_once_timing="$outdir/timing-summary-compile-once.json"
    compile_once_fields=$'0\t0\t0\t0'
    if [[ -f "$compile_once_timing" ]]; then
      compile_once_fields="$(jq -r '
        [
          (.tests_total // 0),
          (.wall_time_s // 0),
          ([.tests[].duration_s] | add // 0),
          ([.tests[].duration_s] | max // 0)
        ] | @tsv' "$compile_once_timing")"
    fi
    if [[ -f "$timing" ]]; then
      wall="$(jq -r '.wall_time_s // 0' "$timing")"
      ratio="$(awk -v v="$vivado_wall" -v w="$wall" 'BEGIN { if (w > 0) printf "%.3f", v / w; else printf "" }')"
      base_fields="$(jq -r --arg target "$target" --arg path "$outdir" --arg ratio "$ratio" '
        [
          $target,
          (.simulator // ""),
          (.tests_total // 0),
          (.wall_time_s // 0),
          ([.tests[].duration_s] | add // 0),
          ([.tests[].duration_s] | max // 0),
          $ratio,
          $path
        ] | @tsv' "$timing"
      )"
      printf '%s\t%s\n' "$base_fields" "$compile_once_fields"
    else
      printf '%s\tMISSING\t0\t0\t0\t0\t\t%s\t%s\n' "$target" "$outdir" "$compile_once_fields"
    fi
  done
} > "$PERFORMANCE"

echo "[performance] wrote $PERFORMANCE"

fail=0

rows="$(awk 'NR>1' "$MANIFEST" | wc -l)"
if [[ "$rows" -ne 6 ]]; then
  echo "FAIL: manifest has $rows data rows (expected 6)" >&2
  fail=1
fi

for target in "${EXPECTED_TARGETS[@]}"; do
  if ! awk -F'\t' -v t="$target" 'NR>1 && $1 == t {found=1} END {exit !found}' "$MANIFEST"; then
    echo "FAIL: expected target not present in manifest: $target" >&2
    fail=1
  fi
done

while IFS=$'\t' read -r target evidence_path; do
  bi="$evidence_path/build-info.json"
  if [[ ! -f "$bi" ]]; then
    echo "FAIL: missing build-info.json for $target at $bi" >&2
    fail=1
    continue
  fi

  bi_target="$(jq -r '.target' "$bi")"
  bi_status="$(jq -r '.qualification_status' "$bi")"
  bi_failed="$(jq -r '.tests_failed // 0' "$bi")"
  bi_errors="$(jq -r '.tests_errors // 0' "$bi")"
  bi_passed="$(jq -r '.tests_passed // 0' "$bi")"
  bi_per_fixture_passed="$(jq -r '.per_fixture_tests_passed // .tests_passed // 0' "$bi")"
  bi_per_fixture_failed="$(jq -r '.per_fixture_tests_failed // .tests_failed // 0' "$bi")"
  bi_per_fixture_errors="$(jq -r '.per_fixture_tests_errors // .tests_errors // 0' "$bi")"
  bi_compile_once_passed="$(jq -r '.compile_once_tests_passed // 0' "$bi")"
  bi_compile_once_failed="$(jq -r '.compile_once_tests_failed // 0' "$bi")"
  bi_compile_once_errors="$(jq -r '.compile_once_tests_errors // 0' "$bi")"
  if [[ "$bi_target" != "$target" || "$bi_status" != "PASS" || "$bi_failed" -ne 0 || "$bi_errors" -ne 0 || "$bi_passed" -lt 1 ]]; then
    echo "FAIL: PASS assertion failed for $target ($bi)" >&2
    fail=1
  fi
  if [[ "$bi_per_fixture_passed" -lt 1 || "$bi_per_fixture_failed" -ne 0 || "$bi_per_fixture_errors" -ne 0 ]]; then
    echo "FAIL: per-fixture regression assertion failed for $target ($bi)" >&2
    fail=1
  fi
  if [[ "$bi_compile_once_passed" -lt 1 || "$bi_compile_once_failed" -ne 0 || "$bi_compile_once_errors" -ne 0 ]]; then
    echo "FAIL: compile-once regression assertion failed for $target ($bi)" >&2
    fail=1
  fi

  if [[ "$target" == "$VIVADO_TARGET" ]]; then
    jq -e \
      --arg version "$EXPECTED_VIVADO_VERSION" \
      --arg profile "$EXPECTED_VIVADO_PROFILE" \
      --arg root "$EXPECTED_VIVADO_ROOT" \
      '.vivado_version == $version
       and .vivado_profile == $profile
       and .vivado_is_stub == false
       and .vivado_qualified_root == $root' "$bi" >/dev/null \
      || { echo "FAIL: Vivado metadata assertion failed at $bi" >&2; fail=1; }

    smoke="$evidence_path/vivado-smoke"
    test -f "$smoke/vivado-version.log" || { echo "FAIL: missing Vivado version smoke log" >&2; fail=1; }
    test -f "$smoke/xvlog-smoke.log" || { echo "FAIL: missing xvlog smoke log" >&2; fail=1; }
    test -f "$smoke/xelab-smoke.log" || { echo "FAIL: missing xelab smoke log" >&2; fail=1; }
    test -f "$smoke/xsim-smoke.log" || { echo "FAIL: missing xsim smoke log" >&2; fail=1; }
    grep -q "VIVADO_VERSION=${EXPECTED_VIVADO_VERSION}" "$smoke/vivado-version.log" \
      || { echo "FAIL: Vivado version smoke did not report $EXPECTED_VIVADO_VERSION" >&2; fail=1; }
    grep -q "Hello from SVUnit certify Vivado smoke" "$smoke/xsim-smoke.log" \
      || { echo "FAIL: Vivado xsim smoke message missing" >&2; fail=1; }

    tool_timing="$evidence_path/vivado-tool-timing/tool-invocations.tsv"
    test -f "$tool_timing" || { echo "FAIL: missing Vivado tool timing log" >&2; fail=1; }
    for tool in xvlog xelab xsim; do
      awk -F'\t' -v tool="$tool" 'NR>1 && $2 == tool {found=1} END {exit !found}' "$tool_timing" \
        || { echo "FAIL: Vivado tool timing log has no $tool invocation" >&2; fail=1; }
    done
  fi
done < <(awk -F'\t' 'NR>1 {print $1 "\t" $15}' "$MANIFEST")

distinct_commits="$(awk -F'\t' 'NR>1 {print $9}' "$MANIFEST" | sort -u | wc -l)"
if [[ "$distinct_commits" -ne 1 ]]; then
  echo "FAIL: manifest contains $distinct_commits distinct svunit_commit values (expected 1)" >&2
  fail=1
fi

if [[ ${#FAILED_TARGETS[@]} -gt 0 ]]; then
  echo "FAIL: non-zero target exits: ${FAILED_TARGETS[*]}" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "NOT OK - inspect $MANIFEST and $RUN_LOG" >&2
  exit 1
fi

echo "OK - six targets PASS with unique output directories."
echo "     Manifest: $MANIFEST"
echo "     Performance: $PERFORMANCE"
echo "     Log:      $RUN_LOG"
