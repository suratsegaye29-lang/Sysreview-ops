#!/bin/bash
# review-ops batch runner
# Spawns parallel claude -p workers for each PENDING paper in tracker

set -euo pipefail

TRACKER="${TRACKER:-data/tracker.tsv}"
BATCH_PROMPT="batch/batch-prompt.md"
PAPERS_DIR="papers"

# --- Helper: update a tracker row's status by study_id ---
update_tracker_status() {
  local study_id="$1"
  local new_status="$2"
  awk -v id="$study_id" -v status="$new_status" -v today="$(date +%F)" \
    'BEGIN{FS=OFS="\t"} $1==id{$7=status; if($4=="") $4=today} 1' \
    "$TRACKER" > "${TRACKER}.tmp" && mv "${TRACKER}.tmp" "$TRACKER"
}

# --- Read config ---
parse_yaml_value() {
  local key="$1" file="$2"
  grep -E "^[[:space:]]*${key}:" "$file" 2>/dev/null \
    | sed 's/^[^:]*:[[:space:]]*//' \
    | sed 's/[[:space:]]*#.*//'     \
    | tr -d '"'"'"                  \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true
}

main() {
  # --- Read config ---
  MAX_PARALLEL=$(parse_yaml_value 'max_parallel' config/review-profile.yml || true)
  EXTRACTOR=$(parse_yaml_value 'lead_reviewer' config/review-profile.yml || true)

  # --- Pre-flight checks ---
  if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude not found. Please install Claude Code."
    exit 1
  fi

  if [[ -z "$MAX_PARALLEL" || ! "$MAX_PARALLEL" =~ ^[0-9]+$ ]]; then
    echo "ERROR: batch.max_parallel not set or invalid in config/review-profile.yml"
    exit 1
  fi

  if [[ -z "$EXTRACTOR" ]]; then
    echo "ERROR: review.lead_reviewer is not set in config/review-profile.yml."
    echo "       All extractions must be attributable to a named reviewer."
    exit 1
  fi

  if [[ ! -f "forms/extraction-form.md" ]]; then
    echo "ERROR: forms/extraction-form.md not found. Run /review-ops form first."
    exit 1
  fi

  echo "📋 review-ops batch runner starting"
  echo "   Extractor:           $EXTRACTOR"
  echo "   Max parallel workers: $MAX_PARALLEL"
  echo ""

  # --- Collect PENDING papers ---
  PENDING=()
  while IFS=$'\t' read -r study_id paper_title extractor date completeness flags status rest; do
    [[ "$study_id" == "study_id" ]] && continue  # skip header
    [[ "$status" == "PENDING" ]] && PENDING+=("$study_id")
  done < "$TRACKER"

  TOTAL=${#PENDING[@]}
  echo "   Papers queued: $TOTAL"
  echo ""

  if [[ $TOTAL -eq 0 ]]; then
    echo "No PENDING papers found in tracker. Exiting."
    exit 0
  fi

  # --- Process in waves ---
  WAVE=1
  FAILED_COUNT=0

  for ((i=0; i<TOTAL; i+=MAX_PARALLEL)); do
    WAVE_PAPERS=("${PENDING[@]:$i:$MAX_PARALLEL}")
    echo "🌊 Wave $WAVE — processing ${#WAVE_PAPERS[@]} papers"

    declare -A PID_TO_STUDY=()
    PIDS=()

    for STUDY_ID in "${WAVE_PAPERS[@]}"; do
      # Security: check for path traversal in STUDY_ID
      if [[ "$STUDY_ID" == *"/"* ]]; then
        echo "   ❌ $STUDY_ID — INVALID study_id (contains slashes). Skipping for security."
        update_tracker_status "$STUDY_ID" "FAILED"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
      fi

      PAPER_FILE=$(find "$PAPERS_DIR" -name "${STUDY_ID}*" | head -1)
      if [[ -z "$PAPER_FILE" ]]; then
        echo "   ❌ $STUDY_ID — paper file not found in $PAPERS_DIR/"
        update_tracker_status "$STUDY_ID" "FAILED"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
      fi

      echo "   ▶ Starting worker: $STUDY_ID ($PAPER_FILE)"
      claude -p "$BATCH_PROMPT" \
        --var STUDY_ID="$STUDY_ID" \
        --var PAPER_FILE="$PAPER_FILE" \
        --var PASS="R1" \
        --var EXTRACTOR="$EXTRACTOR" \
        --var FORM_PATH="forms/extraction-form.md" \
        > "logs/${STUDY_ID}-worker.log" 2>&1 &

      PID=$!
      PIDS+=("$PID")
      PID_TO_STUDY[$PID]="$STUDY_ID"
    done

    # Wait for all workers in this wave and record outcomes
    for PID in "${PIDS[@]}"; do
      STUDY_ID="${PID_TO_STUDY[$PID]}"
      if wait "$PID"; then
        echo "   ✅ $STUDY_ID — complete"
      else
        echo "   ❌ $STUDY_ID — worker failed. See logs/${STUDY_ID}-worker.log"
        update_tracker_status "$STUDY_ID" "FAILED"
        FAILED_COUNT=$((FAILED_COUNT + 1))
      fi
    done

    unset PID_TO_STUDY
    echo "   ✅ Wave $WAVE complete"
    echo ""
    WAVE=$((WAVE + 1))
  done

  # --- Summary ---
  if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "⚠️  Batch run complete — $FAILED_COUNT failure(s) recorded in tracker."
    echo "   Run /review-ops audit to review failures before proceeding."
  else
    echo "✅ Batch run complete. Run /review-ops status to see results."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
