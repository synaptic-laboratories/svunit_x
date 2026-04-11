#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PHASE_DIR="$ROOT_DIR/.planning/phases/01-fork-delta-baseline-intent-record"
MANIFEST_FILE="$PHASE_DIR/01-upstream-baseline.json"
REFS_FILE="$PHASE_DIR/evidence/refs.txt"
MERGE_BASE_FILE="$PHASE_DIR/evidence/merge-base.txt"
REVIEW_NOTE_FILE="$PHASE_DIR/01-baseline-review.md"

EXPECTED_UPSTREAM_URL="https://github.com/svunit/svunit.git"
EXPECTED_TARGET_TAG="v3.38.1"
EXPECTED_TARGET_COMMIT="8e70653e2cbfe3ebe154a863a46bf482ded4bc19"
EXPECTED_BASELINE_TAG="v3.37.0"
EXPECTED_BASELINE_COMMIT="355c1411baf4d0233cb7862e53873ae90ec807e5"
EXPECTED_FORK_HEAD="c2cb87111cf93cbf0f3f485730d314dbad3cb858"
EXPECTED_MERGE_BASE="84b88033590a1469a238be84d8526b25a9f29d10"
EXPECTED_CANDIDATE_MARKER="dc7ed0a5a8b88533b52d884e2c473beb9d4ce273"
EXPECTED_FIRST_PARENT_DESCENDANT="6e179cadaa036554452f8e82e9ca9e94bf307c40"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'usage: %s {refs|graph}\n' "$0" >&2
    exit 1
}

require_file() {
    [ -f "$1" ] || fail "missing required artifact: $1"
}

json_field() {
    field_expr=$1
    field_name=$2
    value=$(jq -r "$field_expr" "$MANIFEST_FILE" 2>/dev/null) || fail "unable to read JSON field: $field_name from $MANIFEST_FILE"
    [ "$value" != "null" ] || fail "missing JSON field: $field_name in $MANIFEST_FILE"
    printf '%s\n' "$value"
}

refs_hash_for() {
    ref_name=$1
    value=$(awk -v ref_name="$ref_name" '$2 == ref_name { print $1; found = 1; exit } END { if (!found) exit 1 }' "$REFS_FILE") || fail "missing ref entry: $ref_name in $REFS_FILE"
    printf '%s\n' "$value"
}

refs_count_for() {
    ref_name=$1
    awk -v ref_name="$ref_name" '$2 == ref_name { count++ } END { print count + 0 }' "$REFS_FILE"
}

merge_base_field() {
    field_name=$1
    value=$(awk -v field_name="$field_name" '$1 == field_name { print $2; found = 1; exit } END { if (!found) exit 1 }' "$MERGE_BASE_FILE") || fail "missing merge-base evidence field: $field_name in $MERGE_BASE_FILE"
    printf '%s\n' "$value"
}

require_in_review_note() {
    needle=$1
    grep -F "$needle" "$REVIEW_NOTE_FILE" >/dev/null 2>&1 || fail "review note is missing required text: $needle"
}

expect_equal() {
    label=$1
    actual=$2
    expected=$3
    [ "$actual" = "$expected" ] || fail "$label mismatch: expected $expected but found $actual"
}

expect_boolean() {
    label=$1
    actual=$2
    expected=$3
    case "$actual" in
        true|false) ;;
        *) fail "$label must be true or false, found $actual" ;;
    esac
    expect_equal "$label" "$actual" "$expected"
}

validate_refs() {
    require_file "$MANIFEST_FILE"
    require_file "$REFS_FILE"
    require_file "$MERGE_BASE_FILE"

    target_tag_ref="refs/tags/$EXPECTED_TARGET_TAG"
    target_commit_ref="${target_tag_ref}^{}"
    baseline_tag_ref="refs/tags/$EXPECTED_BASELINE_TAG"
    baseline_commit_ref="${baseline_tag_ref}^{}"

    manifest_upstream_url=$(json_field '.upstream_url' 'upstream_url')
    manifest_target_tag=$(json_field '.target_tag' 'target_tag')
    manifest_target_tag_object=$(json_field '.target_tag_object' 'target_tag_object')
    manifest_target_commit=$(json_field '.target_commit' 'target_commit')
    manifest_baseline_tag=$(json_field '.remembered_baseline_tag' 'remembered_baseline_tag')
    manifest_baseline_commit=$(json_field '.remembered_baseline_commit' 'remembered_baseline_commit')
    manifest_fork_head=$(json_field '.fork_head' 'fork_head')
    manifest_merge_base=$(json_field '.derived_merge_base' 'derived_merge_base')

    refs_target_tag_object=$(refs_hash_for "$target_tag_ref")
    refs_target_commit=$(refs_hash_for "$target_commit_ref")
    refs_baseline_tag_object=$(refs_hash_for "$baseline_tag_ref")
    refs_baseline_commit=$(refs_hash_for "$baseline_commit_ref")
    evidence_merge_base=$(merge_base_field 'merge_base')

    expect_equal 'upstream_url' "$manifest_upstream_url" "$EXPECTED_UPSTREAM_URL"
    expect_equal 'target_tag' "$manifest_target_tag" "$EXPECTED_TARGET_TAG"
    expect_equal 'target_commit' "$manifest_target_commit" "$EXPECTED_TARGET_COMMIT"
    expect_equal 'remembered_baseline_tag' "$manifest_baseline_tag" "$EXPECTED_BASELINE_TAG"
    expect_equal 'remembered_baseline_commit' "$manifest_baseline_commit" "$EXPECTED_BASELINE_COMMIT"
    expect_equal 'fork_head' "$manifest_fork_head" "$EXPECTED_FORK_HEAD"
    expect_equal 'derived_merge_base' "$manifest_merge_base" "$EXPECTED_MERGE_BASE"

    expect_equal 'target_tag_object' "$manifest_target_tag_object" "$refs_target_tag_object"
    expect_equal 'target_commit evidence' "$manifest_target_commit" "$refs_target_commit"
    expect_equal 'remembered_baseline_commit evidence' "$manifest_baseline_commit" "$refs_baseline_commit"
    [ -n "$refs_baseline_tag_object" ] || fail "missing baseline tag object hash in $REFS_FILE"
    expect_equal 'derived_merge_base evidence' "$manifest_merge_base" "$evidence_merge_base"

    expect_equal 'target tag ref count' "$(refs_count_for "$target_tag_ref")" "1"
    expect_equal 'target peeled ref count' "$(refs_count_for "$target_commit_ref")" "1"
    expect_equal 'baseline tag ref count' "$(refs_count_for "$baseline_tag_ref")" "1"
    expect_equal 'baseline peeled ref count' "$(refs_count_for "$baseline_commit_ref")" "1"
}

validate_graph() {
    require_file "$MANIFEST_FILE"
    require_file "$REFS_FILE"
    require_file "$MERGE_BASE_FILE"
    require_file "$REVIEW_NOTE_FILE"

    target_commit_ref="refs/tags/$EXPECTED_TARGET_TAG^{}"
    target_count=$(refs_count_for "$target_commit_ref")

    if [ "$target_count" != "1" ]; then
        require_in_review_note 'blocking'
        fail "target ref resolution for $EXPECTED_TARGET_TAG is not unique in $REFS_FILE (expected 1 peeled ref, found $target_count)"
    fi

    manifest_baseline_tag=$(json_field '.remembered_baseline_tag' 'remembered_baseline_tag')
    manifest_baseline_commit=$(json_field '.remembered_baseline_commit' 'remembered_baseline_commit')
    manifest_merge_base=$(json_field '.derived_merge_base' 'derived_merge_base')
    manifest_candidate_marker=$(json_field '.candidate_marker' 'candidate_marker')
    manifest_full_descendant=$(json_field '.candidate_marker_full_ancestry_first_descendant' 'candidate_marker_full_ancestry_first_descendant')
    manifest_first_parent_descendant=$(json_field '.candidate_marker_first_parent_first_descendant' 'candidate_marker_first_parent_first_descendant')
    manifest_baseline_matches=$(json_field '.remembered_baseline_matches_merge_base' 'remembered_baseline_matches_merge_base')
    manifest_full_match=$(json_field '.candidate_marker_matches_full_ancestry_first_descendant' 'candidate_marker_matches_full_ancestry_first_descendant')
    manifest_first_parent_match=$(json_field '.candidate_marker_matches_first_parent_first_descendant' 'candidate_marker_matches_first_parent_first_descendant')
    manifest_disposition=$(json_field '.baseline_disposition' 'baseline_disposition')

    evidence_merge_base=$(merge_base_field 'merge_base')
    evidence_baseline_commit=$(merge_base_field 'remembered_baseline_commit')
    evidence_candidate_marker=$(merge_base_field 'candidate_marker')
    evidence_full_descendant=$(merge_base_field 'full_ancestry_first_descendant')
    evidence_first_parent_descendant=$(merge_base_field 'first_parent_first_descendant')

    expect_equal 'remembered_baseline_tag' "$manifest_baseline_tag" "$EXPECTED_BASELINE_TAG"
    expect_equal 'remembered_baseline_commit' "$manifest_baseline_commit" "$EXPECTED_BASELINE_COMMIT"
    expect_equal 'derived_merge_base' "$manifest_merge_base" "$EXPECTED_MERGE_BASE"
    expect_equal 'candidate_marker' "$manifest_candidate_marker" "$EXPECTED_CANDIDATE_MARKER"
    expect_equal 'candidate_marker_full_ancestry_first_descendant' "$manifest_full_descendant" "$EXPECTED_CANDIDATE_MARKER"
    expect_equal 'candidate_marker_first_parent_first_descendant' "$manifest_first_parent_descendant" "$EXPECTED_FIRST_PARENT_DESCENDANT"

    expect_equal 'remembered_baseline_commit evidence' "$manifest_baseline_commit" "$evidence_baseline_commit"
    expect_equal 'derived_merge_base evidence' "$manifest_merge_base" "$evidence_merge_base"
    expect_equal 'candidate_marker evidence' "$manifest_candidate_marker" "$evidence_candidate_marker"
    expect_equal 'full ancestry first descendant evidence' "$manifest_full_descendant" "$evidence_full_descendant"
    expect_equal 'first-parent first descendant evidence' "$manifest_first_parent_descendant" "$evidence_first_parent_descendant"

    if [ "$manifest_baseline_commit" = "$manifest_merge_base" ]; then
        derived_baseline_match=true
    else
        derived_baseline_match=false
    fi

    if [ "$manifest_candidate_marker" = "$manifest_full_descendant" ]; then
        derived_full_match=true
    else
        derived_full_match=false
    fi

    if [ "$manifest_candidate_marker" = "$manifest_first_parent_descendant" ]; then
        derived_first_parent_match=true
    else
        derived_first_parent_match=false
    fi

    expect_boolean 'remembered_baseline_matches_merge_base' "$manifest_baseline_matches" "$derived_baseline_match"
    expect_boolean 'candidate_marker_matches_full_ancestry_first_descendant' "$manifest_full_match" "$derived_full_match"
    expect_boolean 'candidate_marker_matches_first_parent_first_descendant' "$manifest_first_parent_match" "$derived_first_parent_match"

    if [ "$derived_baseline_match" = "false" ] || [ "$derived_first_parent_match" = "false" ]; then
        expect_equal 'baseline_disposition' "$manifest_disposition" 'human-review'
        require_in_review_note 'human-review'
        require_in_review_note 'silent auto-resolution'
    fi

    require_in_review_note "$EXPECTED_BASELINE_TAG"
    require_in_review_note "$manifest_baseline_commit"
    require_in_review_note "$manifest_merge_base"
    require_in_review_note "$manifest_candidate_marker"
    require_in_review_note "$manifest_first_parent_descendant"
}

command_name=${1:-}

case "$command_name" in
    refs)
        [ $# -eq 1 ] || usage
        validate_refs
        ;;
    graph)
        [ $# -eq 1 ] || usage
        validate_graph
        ;;
    *)
        usage
        ;;
esac
