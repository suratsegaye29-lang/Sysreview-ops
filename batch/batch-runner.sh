#!/bin/bash
# review-ops batch runner
# Spawns parallel claude -p workers for each PENDING paper in tracker

set -euo pipefail

TRACKER="data/tracker.tsv"
BATCH_PROMPT="batch/batch-prompt.md"
PAPERS_DIR="papers"
MAX_PARALLEL=$(grep 'max_parallel' config/review-profile.yml | awk '{print $2}')

echo "📋 review-ops batch runner starting"
echo "   Max parallel workers: $MAX_PARALLEL"
echo ""

# Collect PENDING papers
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

# Process in waves
WAVE=1
for ((i=0; i<TOTAL; i+=MAX_PARALLEL)); do
  WAVE_PAPERS=("${PENDING[@]:$i:$MAX_PARALLEL}")
  echo "🌊 Wave $WAVE — processing ${#WAVE_PAPERS[@]} papers"

  PIDS=()
  for STUDY_ID in "${WAVE_PAPERS[@]}"; do
    # Find paper file
    PAPER_FILE=$(find "$PAPERS_DIR" -name "${STUDY_ID}*" | head -1)
    if [[ -z "$PAPER_FILE" ]]; then
      echo "   ❌ $STUDY_ID — paper file not found in $PAPERS_DIR, skipping"
      continue
    fi

    echo "   ▶ Starting worker: $STUDY_ID ($PAPER_FILE)"
    claude -p "$BATCH_PROMPT" \
      --var STUDY_ID="$STUDY_ID" \
      --var PAPER_FILE="$PAPER_FILE" \
      --var EXTRACTOR="R1" \
      --var FORM_PATH="forms/extraction-form.md" \
      > "logs/${STUDY_ID}-worker.log" 2>&1 &
    PIDS+=($!)
  done

  # Wait for all workers in this wave
  for PID in "${PIDS[@]}"; do
    wait "$PID" || echo "   ⚠️  Worker PID $PID exited with error — check logs/"
  done

  echo "   ✅ Wave $WAVE complete"
  echo ""
  ((WAVE++))
done

echo "✅ Batch run complete. Run /review-ops status to see results."
