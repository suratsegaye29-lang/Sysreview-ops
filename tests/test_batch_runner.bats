#!/usr/bin/env bats

setup() {
  # Source the script so we can test its functions
  source batch/batch-runner.sh

  # Create a temporary config file for testing
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
  # We have to mock TRACKER since update_tracker_status uses it directly
  TRACKER=$(mktemp)
  # Write a dummy header and row
  echo -e "study_id\tpaper_title\textractor\tdate\tcompleteness\tflags\tstatus\trest" > "$TRACKER"
  echo -e "ST-1\tTitle\t\t\t\t\tPENDING\t" >> "$TRACKER"

  update_tracker_status "ST-1" "FAILED"

  run grep "ST-1" "$TRACKER"
  [ "$status" -eq 0 ]
  # Status is in the 7th column, let's just make sure FAILED is in the output for that row
  [[ "$output" == *"FAILED"* ]]

  rm -f "$TRACKER"
}
