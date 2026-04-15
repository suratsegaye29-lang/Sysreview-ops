# Mode: batch — Batch Extraction Orchestrator

## Trigger
`/review-ops batch`

## Purpose
Identify all papers with status `PENDING` in the tracker and orchestrate
parallel extraction across all of them using sub-agent workers.

## Pre-flight Checks
Verify:
- `data/tracker.tsv` exists and has at least one row with status `PENDING`
- `forms/extraction-form.md` exists
- `config/review-profile.yml` exists and `batch.max_parallel` is set
- All papers listed as PENDING have a corresponding file in `papers/`

If any PENDING paper has no corresponding file in `papers/`, list the missing
files and halt. Do not begin batch processing with incomplete inputs.

---

## Instructions

### 1. Load the tracker
Read `data/tracker.tsv` and collect all rows where status = `PENDING`.
Print a pre-run summary:
```
📋 Batch run starting
   Papers queued: [n]
   Max parallel workers: [n from config]
   Estimated papers per wave: [n]
```

### 2. Chunk into waves
Divide the PENDING papers into waves of `batch.max_parallel` papers each.
Process one wave at a time — do not start wave N+1 until wave N is complete.

### 3. For each paper in a wave
Invoke a sub-agent worker using:
```bash
claude -p batch/batch-prompt.md --file papers/[filename]
```
Pass the following as context variables in the prompt:
- `PAPER_FILE`: path to the paper
- `STUDY_ID`: from tracker
- `EXTRACTOR`: from review-profile.yml `lead_reviewer` initials
- `FORM_PATH`: `forms/extraction-form.md`

### 4. Monitor completion
After each wave:
- Verify output file exists at `extractions/[study_id]-extraction-R1.md`
- Verify tracker row has been updated from `PENDING` to `EXTRACTED_R1`
- If a worker failed (no output file), mark that paper `FAILED` in tracker
  and log the error; continue processing remaining papers

### 5. Post-batch summary
After all waves complete, print:

```
✅ Batch run complete
   Processed: [n]
   Succeeded: [n]
   Failed: [n] [list study_ids if any]

   Completeness distribution:
   ≥ 80%: [n] papers
   60–79%: [n] papers
   < 60%: [n] papers

   Flag frequency:
   [NOT REPORTED]: [n] total instances across [n] papers
   [AMBIGUOUS]: [n] total instances across [n] papers
   [CONFLICT]: [n] total instances across [n] papers
   [CALCULATED]: [n] total instances across [n] papers
   [FROM FIGURE]: [n] total instances across [n] papers

   Papers needing attention:
   [List any papers with completeness < 60% or confidence = Low]

   Next step: assign each extracted paper to second reviewer for R2 pass
```

---

## Hard Rules
- Never skip a PENDING paper without logging the reason
- Never mark a paper COMPLETE — only EXTRACTED_R1 after a first pass
- Failed workers must be logged; do not silently discard failures
- Batch mode does not run QA or validate — extraction only
