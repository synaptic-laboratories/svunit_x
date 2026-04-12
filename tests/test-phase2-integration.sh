#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PHASE_DIR="$ROOT_DIR/.planning/phases/02-history-aware-upstream-integration"
BASELINE_FILE="$PHASE_DIR/02-integration-baseline.json"
LEDGER_FILE="$PHASE_DIR/02-decision-ledger.md"
SUMMARY_FILE="$PHASE_DIR/02-integration-summary.md"
HUMAN_REVIEW_FILE="$PHASE_DIR/02-human-review.md"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'usage: %s {files|requirements|review}\n' "$0" >&2
    exit 1
}

require_file() {
    [ -f "$1" ] || fail "missing required artifact: $1"
}

require_text() {
    file_path=$1
    needle=$2

    grep -F "$needle" "$file_path" >/dev/null 2>&1 || fail "missing required text '$needle' in $file_path"
}

check_files() {
    require_file "$BASELINE_FILE"
    require_file "$LEDGER_FILE"
}

check_requirements() {
    check_files

    if [ -f "$SUMMARY_FILE" ]; then
        target_file=$SUMMARY_FILE
    else
        target_file=$LEDGER_FILE
        printf 'INFO: %s not found yet; falling back to %s\n' "$SUMMARY_FILE" "$LEDGER_FILE"
    fi

    require_text "$target_file" "XILX-03"
    require_text "$target_file" "SYNC-01"
    require_text "$target_file" "SYNC-02"
    require_text "$target_file" "SYNC-03"
    require_text "$target_file" "LCU-01"
    require_text "$target_file" "LCU-02"
    require_text "$target_file" "LCU-03"
    require_text "$target_file" "LCU-04"
    require_text "$target_file" "LCU-05"
    require_text "$target_file" "LCU-06"
}

check_review() {
    check_files

    require_text "$LEDGER_FILE" "LCU-01"
    require_text "$LEDGER_FILE" "LCU-02"
    require_text "$LEDGER_FILE" "LCU-03"
    require_text "$LEDGER_FILE" "LCU-04"
    require_text "$LEDGER_FILE" "LCU-05"
    require_text "$LEDGER_FILE" "LCU-06"
    require_text "$LEDGER_FILE" "HR-01"
    require_text "$LEDGER_FILE" "HR-02"
    require_text "$LEDGER_FILE" "HR-03"
    require_text "$LEDGER_FILE" "HR-04"

    if [ -f "$HUMAN_REVIEW_FILE" ]; then
        require_text "$HUMAN_REVIEW_FILE" "source_artifact"
        require_text "$HUMAN_REVIEW_FILE" "row_id_or_hash"
        require_text "$HUMAN_REVIEW_FILE" "why_human_review"
        require_text "$HUMAN_REVIEW_FILE" "safe_default_until_quartus_signoff"
    fi
}

command_name=${1:-}

case "$command_name" in
    files)
        [ $# -eq 1 ] || usage
        check_files
        ;;
    requirements)
        [ $# -eq 1 ] || usage
        check_requirements
        ;;
    review)
        [ $# -eq 1 ] || usage
        check_review
        ;;
    *)
        usage
        ;;
esac
