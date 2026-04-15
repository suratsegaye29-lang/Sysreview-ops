# review-ops — End-to-End Workflow

## Overview
RESEARCHER SETUP
│
▼

Fill config/review-profile.yml
│
▼
Fill modes/_shared.md (PICO, criteria, rules)
│
▼
Add questions to questions/questions.md
│
▼
/review-ops form ──────────────────► forms/extraction-form.md
│
▼
Add papers to papers/ (PDF or .md)
Add rows to data/tracker.tsv with status PENDING
│
▼
/review-ops batch ─────────────────► extractions/*-extraction-R1.md
│                                   tracker updated to EXTRACTED_R1
▼
Second reviewer runs:
/review-ops extract [paper] ───────► extractions/*-extraction-R2.md
│
▼
/review-ops validate [study_id] ──► reports/-reconciliation.md
│                                  extractions/-final.md (if consensus)
▼                                  tracker → FINALISED or PENDING_ADJUDICATION
Human adjudicator resolves conflicts
(edits Adjudicator Decision Log in reconciliation report)
│
▼
/review-ops qa [study_id] ────────► extractions/*-qa.md
│                                  tracker → QA_COMPLETE
▼
/review-ops audit ────────────────► reports/audit-report.md
│                                  confirms pipeline integrity
▼
/review-ops synthesis ────────────► reports/synthesis-report.md


## Status Definitions

| Status | Meaning |
|---|---|
| `PENDING` | Paper added to tracker, extraction not yet started |
| `EXTRACTED_R1` | First extraction pass complete |
| `EXTRACTED_R2` | Second extraction pass complete |
| `PENDING_ADJUDICATION` | Major conflicts exist between R1 and R2 |
| `FINALISED` | Reconciliation complete, final extraction written |
| `QA_COMPLETE` | Risk of bias / quality assessment complete |
| `FAILED` | Worker error during batch extraction |
| `COMPLETE` | Human sign-off given — do not set programmatically |

## Adding a Paper to the Tracker

Add a row to `data/tracker.tsv` manually before running batch:
AuthorYYYY	Full paper title	[lead_reviewer_initials]	[YYYY-MM-DD]		 	PENDING

Leave completeness and flags blank — the extraction worker will populate them.

## File Naming Conventions

| File | Pattern |
|---|---|
| First extraction | `extractions/[study_id]-extraction-R1.md` |
| Second extraction | `extractions/[study_id]-extraction-R2.md` |
| Final extraction | `extractions/[study_id]-final.md` |
| QA record | `extractions/[study_id]-qa.md` |
| Reconciliation report | `reports/[study_id]-reconciliation.md` |

## Tips

- Run `/review-ops status` at any time for a live pipeline dashboard
- Run `/review-ops audit` before synthesis — it will catch problems early
- Never manually edit R1 or R2 extraction files after they are written
- The tracker is the source of truth — keep it in sync
