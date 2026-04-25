#!/usr/bin/env bats

setup() {
  # Source the script so we can test its functions
  source batch/batch-runner.sh

  # Create a temporary tracker for testing update_tracker_status
  TRACKER="$BATS_TMPDIR/tracker.tsv"
  printf 'study_id\tpaper_title\textractor\tdate\tcompleteness_score\tflags\tstatus\n' > "$TRACKER"
  printf 'study1\tPaper One\tJS\t\t\t\tPENDING\n' >> "$TRACKER"
  printf 'study2\tPaper Two\tJS\t2023-01-01\t\t\tPENDING\n' >> "$TRACKER"
  printf 'study3\tPaper Three\tJS\t\t\t\tPENDING\n' >> "$TRACKER"

  # Create a temporary config file for testing parse_yaml_value
  TEST_CONFIG=$(mktemp)
}

teardown() {
  rm -f "$TEST_CONFIG"
}

@test "parse_yaml_value: unquoted value" {
  echo "max_parallel: 3" > "$TEST_CONFIG"
  run parse_yaml_value "max_parallel" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "parse_yaml_value: quoted simple value" {
  echo "lead_reviewer: \"JD\"" > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "JD" ]
}

@test "parse_yaml_value: quoted value with spaces" {
  echo "lead_reviewer: \"Jane Doe\"" > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "Jane Doe" ]
}

@test "parse_yaml_value: trailing comment stripped" {
  echo "lead_reviewer: \"JD\" # primary reviewer" > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "JD" ]
}

@test "parse_yaml_value: extra whitespace around value" {
  echo "lead_reviewer:   JD  " > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "JD" ]
}

@test "parse_yaml_value: single quotes" {
  echo "lead_reviewer: 'Jane Doe'" > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "Jane Doe" ]
}

@test "parse_yaml_value: single quotes with trailing comment" {
  echo "lead_reviewer: 'Jane Doe' # comment" > "$TEST_CONFIG"
  run parse_yaml_value "lead_reviewer" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "Jane Doe" ]
}

@test "parse_yaml_value: missing key returns empty string" {
  echo "other_key: value" > "$TEST_CONFIG"
  run parse_yaml_value "missing_key" "$TEST_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "update_tracker_status: updates status correctly" {
  update_tracker_status "study1" "COMPLETE"
  today="$(date +%F)"
  run awk -F'\t' '$1=="study1" {print $4, $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "$today COMPLETE" ]
}

@test "update_tracker_status: existing date remains unchanged" {
  update_tracker_status "study2" "COMPLETE"
  run awk -F'\t' '$1=="study2" {print $4, $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "2023-01-01 COMPLETE" ]
}

@test "update_tracker_status: non-existent study_id (file remains unchanged)" {
  cp "$TRACKER" "${TRACKER}.bak"
  update_tracker_status "study_none" "COMPLETE"
  run cmp -s "$TRACKER" "${TRACKER}.bak"
  [ "$status" -eq 0 ]
}

@test "update_tracker_status: other rows untouched" {
  update_tracker_status "study2" "COMPLETE"
  run awk -F'\t' '$1=="study1" {print $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "PENDING" ]
  run awk -F'\t' '$1=="study3" {print $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "PENDING" ]
}

@test "update_tracker_status: header row untouched" {
  update_tracker_status "study1" "COMPLETE"
  run head -n 1 "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "study_id	paper_title	extractor	date	completeness_score	flags	status" ]
}

@test "security: reject study_id with invalid characters" {
  # We test the regex matching locally, simulating the logic in main()
  STUDY_ID="invalid.study\$123"
  run bash -c "[[ ! '$STUDY_ID' =~ ^[A-Za-z0-9_-]+$ ]] && echo 'rejected'"
  [ "$status" -eq 0 ]
  [ "$output" = "rejected" ]

  STUDY_ID="../etc/passwd"
  run bash -c "[[ ! '$STUDY_ID' =~ ^[A-Za-z0-9_-]+$ ]] && echo 'rejected'"
  [ "$status" -eq 0 ]
  [ "$output" = "rejected" ]

  STUDY_ID="valid-study_123"
  run bash -c "[[ ! '$STUDY_ID' =~ ^[A-Za-z0-9_-]+$ ]] && echo 'rejected' || echo 'accepted'"
  [ "$status" -eq 0 ]
  [ "$output" = "accepted" ]
}
