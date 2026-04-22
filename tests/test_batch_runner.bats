#!/usr/bin/env bats

command -v bats >/dev/null || { echo "ERROR: bats not found. Run: apt install bats"; exit 1; }

setup() {
  TRACKER="$BATS_TMPDIR/tracker.tsv"
  printf 'study_id\tpaper_title\textractor\tdate\tcompleteness_score\tflags\tstatus\n' > "$TRACKER"
  printf 'study1\tPaper One\tJS\t\t\t\tPENDING\n' >> "$TRACKER"
  printf 'study2\tPaper Two\tJS\t2023-01-01\t\t\tPENDING\n' >> "$TRACKER"
  printf 'study3\tPaper Three\tJS\t\t\t\tPENDING\n' >> "$TRACKER"

  # Source the script so update_tracker_status is available
  source "batch/batch-runner.sh"
}

@test "Update with blank date (sets to today's date)" {
  update_tracker_status "study1" "COMPLETE"

  today="$(date +%F)"
  run awk -F'\t' '$1=="study1" {print $4, $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "$today COMPLETE" ]
}

@test "Update with existing date (date remains unchanged)" {
  update_tracker_status "study2" "COMPLETE"

  run awk -F'\t' '$1=="study2" {print $4, $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "2023-01-01 COMPLETE" ]
}

@test "Update non-existent study_id (file remains unchanged)" {
  # Backup original file state
  cp "$TRACKER" "${TRACKER}.bak"

  update_tracker_status "study_none" "COMPLETE"

  # Check if file has changed
  run cmp -s "$TRACKER" "${TRACKER}.bak"
  [ "$status" -eq 0 ]
}

@test "Update one among multiple rows (other rows untouched)" {
  update_tracker_status "study2" "COMPLETE"

  run awk -F'\t' '$1=="study1" {print $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "PENDING" ]

  run awk -F'\t' '$1=="study3" {print $7}' "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "PENDING" ]
}

@test "Header row untouched" {
  update_tracker_status "study1" "COMPLETE"

  run head -n 1 "$TRACKER"
  [ "$status" -eq 0 ]
  [ "$output" = "study_id	paper_title	extractor	date	completeness_score	flags	status" ]
}
