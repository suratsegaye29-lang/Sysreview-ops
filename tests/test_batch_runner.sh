#!/bin/bash
# tests/test_batch_runner.sh

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

CONFIG_FILE="config/review-profile.yml"
CONFIG_TEMP="config/review-profile.yml.test"
CONFIG_BACKUP="config/review-profile.yml.bak.test"
FORM_FILE="forms/extraction-form.md"
FORM_BACKUP="forms/extraction-form.md.bak.test"

cleanup() {
    echo "Cleaning up..."
    if [ -f "$CONFIG_BACKUP" ]; then
        mv "$CONFIG_BACKUP" "$CONFIG_FILE"
    fi
    if [ -f "$FORM_BACKUP" ]; then
        mv "$FORM_BACKUP" "$FORM_FILE"
    fi
    rm -f "$CONFIG_TEMP"
}

trap cleanup EXIT

# Backup existing files
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_BACKUP"
else
    # Create a dummy backup if it doesn't exist so it can be "restored" (deleted)
    touch "$CONFIG_BACKUP"
fi

if [ -f "$FORM_FILE" ]; then
    cp "$FORM_FILE" "$FORM_BACKUP"
fi

mkdir -p config
mkdir -p forms

run_test() {
    local test_name=$1
    local config_content=$2
    local expected_error=$3
    local remove_form=${4:-false}

    echo "Testing $test_name..."
    echo "$config_content" > "$CONFIG_FILE"

    if [ "$remove_form" = true ]; then
        [ -f "$FORM_FILE" ] && rm "$FORM_FILE"
    else
        # Ensure form file exists for other tests
        touch "$FORM_FILE"
    fi

    output=$(./batch/batch-runner.sh 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ] && echo "$output" | grep -q "$expected_error"; then
        echo -e "${GREEN}PASS: $test_name${NC}"
        return 0
    else
        echo -e "${RED}FAIL: $test_name${NC}"
        echo "Expected error: $expected_error"
        echo "Actual exit code: $exit_code"
        echo "Actual output: $output"
        return 1
    fi
}

# Run tests
FAILED=0

run_test "missing max_parallel" "review:
  lead_reviewer: \"JD\"
batch:
" "ERROR: batch.max_parallel not set or invalid" || FAILED=1

run_test "invalid max_parallel" "review:
  lead_reviewer: \"JD\"
batch:
  max_parallel: \"abc\"
" "ERROR: batch.max_parallel not set or invalid" || FAILED=1

run_test "missing lead_reviewer" "review:
  lead_reviewer: \"\"
batch:
  max_parallel: 3
" "ERROR: review.lead_reviewer is not set" || FAILED=1

run_test "missing extraction-form.md" "review:
  lead_reviewer: \"JD\"
batch:
  max_parallel: 3
" "ERROR: forms/extraction-form.md not found" true || FAILED=1

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed.${NC}"
    exit 1
fi
