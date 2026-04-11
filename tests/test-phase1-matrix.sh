#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PHASE_DIR="$ROOT_DIR/.planning/phases/01-fork-delta-baseline-intent-record"
MATRIX_FILE="$PHASE_DIR/01-fork-delta-matrix.md"
FORK_ONLY_FILE="$PHASE_DIR/evidence/fork-only.log"
RANGE_DIFF_FILE="$PHASE_DIR/evidence/range-diff.txt"
PATH_OVERLAP_FILE="$PHASE_DIR/evidence/path-overlap.txt"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'usage: %s <command>\n' "$0" >&2
    exit 1
}

require_file() {
    [ -f "$1" ] || fail "missing required artifact: $1"
}

check_presence() {
    require_file "$MATRIX_FILE"
    require_file "$FORK_ONLY_FILE"
    require_file "$RANGE_DIFF_FILE"
    require_file "$PATH_OVERLAP_FILE"
}

check_table() {
    mode=$1

    require_file "$MATRIX_FILE"

    awk -v mode="$mode" '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        function load_cells(line, cells,    field_count, count, parts, i) {
            field_count = split(line, parts, /\|/)
            count = 0
            for (i = 2; i < field_count; i++) {
                cells[++count] = trim(parts[i])
            }
            return count
        }

        function row_name(cells) {
            if (cells[1] != "") {
                return cells[1]
            }
            return "unknown-row"
        }

        function is_separator(cells, count,    i) {
            if (count != 8) {
                return 0
            }
            for (i = 1; i <= count; i++) {
                if (cells[i] !~ /^:?-+:?$/) {
                    return 0
                }
            }
            return 1
        }

        function has_value(value) {
            value = trim(value)
            return value != "" && value != "-"
        }

        function has_hash(value) {
            return value ~ /[0-9a-f]{7,40}/
        }

        function has_allowed_path(value) {
            return value ~ /(bin\/|svunit_base\/|src\/experimental\/sv\/|test\/|README\.md|CHANGELOG\.md|docs\/)/
        }

        function is_xilinx_related(value) {
            value = tolower(value)
            return value ~ /(xilinx|vivado)/
        }

        function defers_to_other_doc(value) {
            value = tolower(value)
            return value ~ /(01-executive-summary\.md|01-human-review\.md)/
        }

        function fail(message) {
            print "ERROR: " message > "/dev/stderr"
            exit 1
        }

        BEGIN {
            expected[1] = "logical_change_id"
            expected[2] = "files_touched"
            expected[3] = "commits"
            expected[4] = "likely_purpose_or_interpretation"
            expected[5] = "xilinx_relevance"
            expected[6] = "classification"
            expected[7] = "merge_handling_notes"
            expected[8] = "evidence_refs"
            header_found = 0
            separator_found = 0
            logical_rows = 0
            xilinx_rows = 0
        }

        /^\|/ {
            count = load_cells($0, cells)

            if (!header_found) {
                matched_header = count == 8
                for (i = 1; i <= 8 && matched_header; i++) {
                    if (cells[i] != expected[i]) {
                        matched_header = 0
                    }
                }
                if (matched_header) {
                    header_found = 1
                    next
                }
                if (index($0, "logical_change_id") > 0 || index($0, "files_touched") > 0 || index($0, "commits") > 0 || index($0, "likely_purpose_or_interpretation") > 0 || index($0, "xilinx_relevance") > 0 || index($0, "classification") > 0 || index($0, "merge_handling_notes") > 0 || index($0, "evidence_refs") > 0) {
                    fail("matrix header must use the exact D-16 columns in order")
                }
                next
            }

            if (!separator_found) {
                if (is_separator(cells, count)) {
                    separator_found = 1
                    next
                }
                fail("matrix header separator row is missing or malformed")
            }

            if (count != 8) {
                fail("row " row_name(cells) " must have exactly 8 columns")
            }

            row_id = row_name(cells)
            if (row_id !~ /^LCU-[0-9][0-9A-Za-z-]*$/) {
                fail("row " row_id " must use logical_change_id like LCU-01")
            }

            logical_rows++

            files_touched = cells[2]
            commits = cells[3]
            purpose = cells[4]
            xilinx_relevance = cells[5]
            classification = cells[6]
            merge_notes = cells[7]
            evidence_refs = cells[8]

            if (!has_value(evidence_refs)) {
                fail("row " row_id " is missing evidence_refs")
            }

            if (mode == "classifications") {
                if (classification != "keep" && classification != "superseded" && classification != "rewrite" && classification != "human-review") {
                    fail("row " row_id " has invalid classification: " classification)
                }
                if (classification == "superseded" && evidence_refs !~ /range-diff\.txt/) {
                    fail("row " row_id " is marked superseded but does not cite concrete upstream evidence from range-diff.txt")
                }
            } else if (mode == "xilinx-trace") {
                if (is_xilinx_related(xilinx_relevance)) {
                    xilinx_rows++
                    if (!has_value(commits) || !has_hash(commits)) {
                        fail("row " row_id " is Xilinx/Vivado-relevant but is missing a traced commit")
                    }
                    if (!has_value(files_touched)) {
                        fail("row " row_id " is Xilinx/Vivado-relevant but is missing files_touched")
                    }
                    if (!has_allowed_path(files_touched)) {
                        fail("row " row_id " is Xilinx/Vivado-relevant but does not name a touched file under bin/, svunit_base/, src/experimental/sv/, test/, or repo docs")
                    }
                }
            } else if (mode == "intent") {
                if (!has_value(purpose)) {
                    fail("row " row_id " is missing likely_purpose_or_interpretation")
                }
                if (!has_value(merge_notes)) {
                    fail("row " row_id " is missing merge_handling_notes")
                }
                if (is_xilinx_related(xilinx_relevance)) {
                    if (defers_to_other_doc(purpose)) {
                        fail("row " row_id " defers likely_purpose_or_interpretation to another document")
                    }
                    if (defers_to_other_doc(merge_notes)) {
                        fail("row " row_id " defers merge_handling_notes to another document")
                    }
                }
            } else {
                fail("unknown validation mode: " mode)
            }
        }

        END {
            if (!header_found) {
                fail("matrix header not found in " FILENAME)
            }
            if (!separator_found) {
                fail("matrix header separator row not found in " FILENAME)
            }
            if (logical_rows == 0) {
                fail("matrix does not contain any logical change rows")
            }
            if (mode == "xilinx-trace" && xilinx_rows == 0) {
                fail("matrix does not contain any Xilinx/Vivado-relevant rows")
            }
        }
    ' "$MATRIX_FILE"
}

command_name=${1:-}

case "$command_name" in
    files)
        [ $# -eq 1 ] || usage
        check_presence
        ;;
    classifications)
        [ $# -eq 1 ] || usage
        check_table "$command_name"
        ;;
    xilinx-trace)
        [ $# -eq 1 ] || usage
        check_table "$command_name"
        ;;
    intent)
        [ $# -eq 1 ] || usage
        check_table "$command_name"
        ;;
    *)
        usage
        ;;
esac
