# Mode: validate — Dual-Extraction Reconciliation

## Trigger
`/review-ops validate [study_id]`

## Purpose
Compare two independent extraction passes for the same paper, classify
disagreements by severity, auto-resolve minor discrepancies, and escalate
major conflicts to the human adjudicator.

## Pre-flight Checks
Before running, verify both files exist:
- `extractions/[study_id]-extraction-R1.md`
- `extractions/[study_id]-extraction-R2.md`

If either is missing, halt and state which pass is incomplete.
Do not proceed with only one extraction — single-extractor reconciliation
is not valid under dual-extraction protocol.

---

## Reconciliation Instructions

### 1. Load both extractions
Read R1 and R2 in full before making any comparisons.
Do not compare field by field as you read — load both completely first.

### 2. Field-by-field comparison
Work through every field in block order (A → H).
For each field, classify the agreement status:

| Classification | Definition |
|---|---|
| ✅ Agreement | Both extractors recorded identical or semantically equivalent data |
| ⚠️ Minor Discrepancy | Same substance, different phrasing, formatting, or level of detail |
| ❌ Major Conflict | Substantively different data — different values, different interpretation, or one recorded data the other flagged as `[NOT REPORTED]` |

**Agreement rules:**
- Numeric values must match exactly — `42%` vs `42.0%` is Agreement; `42%` vs `43%` is Major Conflict
- P-values must match exactly as written — `p < 0.05` vs `p = 0.04` is Major Conflict
- Flag disagreements: if R1 flagged `[AMBIGUOUS]` and R2 did not, classify as Minor Discrepancy and surface both
- `[NOT REPORTED]` vs any value is always a Major Conflict

### 3. Resolve minor discrepancies
For each ⚠️ Minor Discrepancy, auto-produce a merged value using this logic:
- Prefer the more specific or complete of the two values
- Prefer verbatim text over paraphrase
- Prefer the value with a source citation over one without
- Record the merge rationale in the reconciliation report

Do not auto-resolve anything classified as ❌ Major Conflict.

### 4. Calculate agreement rate
```
Agreement Rate = (Agreement fields + Minor Discrepancy fields) / total fields × 100
```

### 5. Determine outcome
- **Agreement Rate ≥ 90% AND no Major Conflicts** → produce final extraction
- **Agreement Rate ≥ 90% BUT Major Conflicts exist** → produce final extraction for agreed fields only; escalate conflicts
- **Agreement Rate < 90%** → do not produce final extraction; escalate entire paper

---

## Output

### Reconciliation Report
Write to `reports/[study_id]-reconciliation.md`:

```markdown
# Reconciliation Report
## Study ID: [study_id]
## R1 Extractor: [initials] — [date]
## R2 Extractor: [initials] — [date]
## Reconciliation Date: [YYYY-MM-DD]
## Agreement Rate: [X%]
## Outcome: [AUTO-FINALISED / PARTIAL-ESCALATION / FULL-ESCALATION]

---

### Agreement Summary
| Status | Count | % of Fields |
|---|---|---|
| ✅ Agreement | | |
| ⚠️ Minor Discrepancy (auto-resolved) | | |
| ❌ Major Conflict (escalated) | | |

---

### Minor Discrepancies — Auto-Resolved
| Field | R1 Value | R2 Value | Merged Value | Rationale |
|---|---|---|---|---|

---

### Major Conflicts — Escalated for Human Adjudication
| Field | R1 Value | R1 Source | R2 Value | R2 Source | Notes |
|---|---|---|---|---|---|

---

### Adjudicator Decision Log
> To be completed by human adjudicator. Do not edit above this line.

| Field | Final Value | Source | Adjudicator | Date |
|---|---|---|---|---|
```

### Final extraction (if conditions met)
If outcome is AUTO-FINALISED or PARTIAL-ESCALATION, write the resolved fields to:
```
extractions/[study_id]-final.md
```
Use the same structure as `templates/extraction-output.md`.
Mark `Extraction Pass: Final` in the header.
For any field still awaiting adjudication, write `[PENDING ADJUDICATION]` as the value.

### Tracker update
Update the existing row for this study_id in `data/tracker.tsv`.
Append to the flags column any new flags from reconciliation.
Update status to one of:
- `FINALISED` — auto-finalised, no conflicts
- `PENDING_ADJUDICATION` — major conflicts exist
- `NEEDS_R2` — second extraction not yet complete (should not reach validate mode, but handle gracefully)

### Console output
```
✅ Reconciliation complete: [study_id]
   Agreement rate: [X%]
   Auto-resolved: [n] minor discrepancies
   Escalated: [n] major conflicts
   Outcome: [AUTO-FINALISED / PARTIAL-ESCALATION / FULL-ESCALATION]
   Report: reports/[study_id]-reconciliation.md
   [If finalised]: Final extraction: extractions/[study_id]-final.md
   [If conflicts]: Next step: human adjudicator must complete Adjudicator Decision Log
```

---

## Hard Rules
- Never auto-resolve a Major Conflict — surface it without exception
- Never produce a final extraction if Agreement Rate < 90% and Major Conflicts exist
- Never modify R1 or R2 files — they are the permanent record of each pass
- The Adjudicator Decision Log section is human-only — the agent writes the table header but never fills in decisions
