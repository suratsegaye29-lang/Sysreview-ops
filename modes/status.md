# Mode: status — Pipeline Dashboard

## Trigger
`/review-ops status`

## Purpose
Read `data/tracker.tsv` and render a live, human-readable dashboard showing
the current state of the pipeline at a glance. No files are modified — this
mode is strictly read-only.

## Instructions

### 1. Load the tracker
Read `data/tracker.tsv` in full. If the file is empty (header row only),
print:

```
📋 review-ops — no papers in tracker yet.
   Add papers to data/tracker.tsv with status PENDING, then run /review-ops batch.
```

Then exit.

### 2. Count by status
Tally all rows by their status column:

| Status | Count |
|---|---|
| PENDING | |
| EXTRACTED_R1 | |
| EXTRACTED_R2 | |
| PENDING_ADJUDICATION | |
| FINALISED | |
| QA_COMPLETE | |
| FAILED | |
| COMPLETE | |

### 3. Calculate progress percentage
```
Progress = (FINALISED + QA_COMPLETE + COMPLETE) / total papers × 100
```

### 4. Flag summary
Scan all flag columns in the tracker. Count total instances of each flag type
across all papers:
- [NOT REPORTED]
- [AMBIGUOUS]
- [CONFLICT]
- [CALCULATED]
- [FROM FIGURE]

### 5. Attention list
Identify papers requiring immediate action:
- Status = FAILED → needs re-extraction
- Status = PENDING_ADJUDICATION → needs human adjudicator
- Completeness score < 60% → needs review
- Status = EXTRACTED_R1 with no corresponding R2 file → needs second reviewer

### 6. Render the dashboard

Print the following to console, populated with real values:

```
════════════════════════════════════════
  review-ops — pipeline status
  [review title from config/review-profile.yml]
  [YYYY-MM-DD HH:MM]
════════════════════════════════════════

📊 PROGRESS
  ████████░░░░░░░░░░░░  [X]% complete
  [n] of [total] papers finalised or beyond

📋 PIPELINE BREAKDOWN
  PENDING              [n]
  EXTRACTED_R1         [n]
  EXTRACTED_R2         [n]
  PENDING_ADJUDICATION [n]  ⚠️  (if > 0)
  FINALISED            [n]
  QA_COMPLETE          [n]
  FAILED               [n]  ❌  (if > 0)
  COMPLETE             [n]
  ─────────────────────────
  TOTAL                [n]

🚩 FLAG SUMMARY (across all papers)
  [NOT REPORTED]   [n] instances in [n] papers
  [AMBIGUOUS]      [n] instances in [n] papers
  [CONFLICT]       [n] instances in [n] papers
  [CALCULATED]     [n] instances in [n] papers
  [FROM FIGURE]    [n] instances in [n] papers

⚠️  NEEDS ATTENTION  (omit section entirely if list is empty)
  [study_id] — FAILED — re-run /review-ops extract [paper]
  [study_id] — PENDING_ADJUDICATION since [date] — assign adjudicator
  [study_id] — completeness [X%] — below threshold, review extraction
  [study_id] — R2 missing — assign second reviewer

✅ NEXT RECOMMENDED ACTION
  [single most important next step based on current state]
════════════════════════════════════════
```

### 7. Next recommended action logic
Determine the single most important next step using this priority order:

1. If any papers are FAILED → `/review-ops extract [study_id]` for each
2. If any papers are PENDING → `/review-ops batch`
3. If any papers are EXTRACTED_R1 with no R2 → assign second reviewer
4. If any papers are EXTRACTED_R2 → `/review-ops validate [study_id]`
5. If any papers are PENDING_ADJUDICATION → human adjudicator needed
6. If any papers are FINALISED with no QA → `/review-ops qa [study_id]`
7. If all papers are QA_COMPLETE → `/review-ops audit`
8. If audit report exists and is clean → `/review-ops synthesis`
9. If synthesis report exists → human review of synthesis report

### 8. Progress bar rendering
Build the progress bar from block characters:
- Total width: 20 characters
- Filled: `█` for each completed unit
- Empty: `░` for each remaining unit
- Calculate: `filled = round(progress_pct / 100 * 20)`

---

## Hard Rules
- Status mode never writes, modifies, or deletes any file
- If tracker is missing, print a setup message and exit — do not create the file
- Never infer status from file existence alone — the tracker is the source of truth
- Omit the "Needs Attention" section entirely if there are no items — do not print an empty section
