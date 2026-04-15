# Mode: audit — Pipeline Integrity Check

## Trigger
`/review-ops audit`

## Purpose
Verify the pipeline is complete, consistent, and ready for synthesis.
Surface any integrity failures before they propagate into the final report.

## Instructions

### 1. Load the tracker
Read `data/tracker.tsv` in full. Build a complete index of all papers
and their current status.

### 2. Run integrity checks

For each check below, classify the result as:
- ✅ PASS
- ⚠️ WARNING — should be resolved but does not block synthesis
- ❌ BLOCKER — must be resolved before synthesis can proceed

| Check | Condition | Failure classification |
|---|---|---|
| Extraction file exists | Every INCLUDED paper has `extractions/[id]-extraction-R1.md` | BLOCKER |
| Final file exists | Every FINALISED paper has `extractions/[id]-final.md` | BLOCKER |
| QA file exists | Every FINALISED paper has `extractions/[id]-qa.md` | WARNING |
| Completeness threshold | Every final extraction meets threshold in config | WARNING |
| No duplicate study IDs | No study_id appears more than once in tracker | BLOCKER |
| No stale adjudications | No paper has been in PENDING_ADJUDICATION > 14 days | WARNING |
| Reconciliation reports exist | Every FINALISED paper has `reports/[id]-reconciliation.md` | WARNING |
| Tracker row count | Number of tracker rows matches number of extraction files | BLOCKER |
| All flags reviewed | No extraction file contains `[PENDING ADJUDICATION]` in a non-adjudication-status paper | BLOCKER |

### 3. Orphan file check
Scan `extractions/` and `reports/` for files with no corresponding tracker entry.
List any orphans — these may indicate manually created files or tracker drift.

### 4. Completeness distribution
Report the distribution of completeness scores across all final extractions:
- Mean, median, min, max
- Number of papers below the configured threshold

---

## Output

Write to `reports/audit-report.md`:

```markdown
# Pipeline Audit Report
## Review: [title]
## Audit Date: [YYYY-MM-DD]
## Total papers in tracker: [n]
## Overall status: [READY FOR SYNTHESIS / BLOCKERS PRESENT / WARNINGS ONLY]

---

## Integrity Check Results

| Check | Result | Details |
|---|---|---|
| Extraction files exist | ✅/⚠️/❌ | |
| Final files exist | ✅/⚠️/❌ | |
| QA files exist | ✅/⚠️/❌ | |
| Completeness threshold met | ✅/⚠️/❌ | |
| No duplicate study IDs | ✅/⚠️/❌ | |
| No stale adjudications | ✅/⚠️/❌ | |
| Reconciliation reports exist | ✅/⚠️/❌ | |
| Tracker row count matches files | ✅/⚠️/❌ | |
| All flags reviewed | ✅/⚠️/❌ | |

---

## Blockers
[List each BLOCKER with the affected study_id and exact remediation step]

## Warnings
[List each WARNING with the affected study_id and recommended action]

## Orphan Files
[List any files with no tracker entry]

## Completeness Distribution
| Metric | Value |
|---|---|
| Mean completeness | |
| Median completeness | |
| Min | |
| Max | |
| Papers below threshold | |

---

## Pipeline Status by Stage
| Stage | Count |
|---|---|
| PENDING | |
| EXTRACTED_R1 | |
| EXTRACTED_R2 | |
| PENDING_ADJUDICATION | |
| FINALISED | |
| QA_COMPLETE | |
| FAILED | |
```

### Console output
```
[✅ READY / ❌ BLOCKERS PRESENT / ⚠️ WARNINGS ONLY]

Audit complete: [YYYY-MM-DD]
Blockers: [n]
Warnings: [n]
Orphan files: [n]
Output: reports/audit-report.md

[If blockers]: Resolve all blockers before running /review-ops synthesis
[If clean]: Safe to proceed → /review-ops synthesis
```

---

## Hard Rules
- Audit never modifies any file — read only
- A paper in PENDING_ADJUDICATION must never be counted as FINALISED
- Blockers are binary — they either exist or they don't; no partial credit
- Audit report must be regenerated fresh each run; do not append to old report
