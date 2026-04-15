# Mode: synthesis — Narrative Synthesis

## Trigger
`/review-ops synthesis`

## Purpose
Aggregate all finalised extractions into a structured narrative synthesis
following PRISMA 2020 Section 13 reporting standards.

## Pre-flight Checks
Verify:
- At least one file exists matching `extractions/*-final.md`
- `reports/audit-report.md` exists and contains no `[BLOCKER]` flags
  (run `/review-ops audit` first if not)
- `modes/_shared.md` is populated with outcomes defined

If the audit report has unresolved blockers, halt and list them.
Do not synthesise over incomplete or unvalidated data.

---

## Instructions

### 1. Load all final extractions
Read every file matching `extractions/*-final.md`.
Build an internal index: study_id → extracted fields.
Note any papers still in `PENDING_ADJUDICATION` status — exclude them from
synthesis and list them in the report as pending.

### 2. Study characteristics table
Generate a summary table with one row per included study:

| Study ID | Authors | Year | Country | Design | N | Intervention | Comparator | Primary Outcome | Follow-up | Overall RoB |
|---|---|---|---|---|---|---|---|---|---|---|

Pull `overall_rob` from `extractions/[study_id]-qa.md` if it exists.
If QA has not been run for a paper, mark RoB as `[NOT ASSESSED]`.

### 3. Narrative synthesis per outcome domain
For each outcome defined in `modes/_shared.md`:

**a) Tabulate findings**
List all studies reporting this outcome with their effect estimates,
confidence intervals, p-values, and measurement tools.

**b) Direction of effect**
Summarise the direction and consistency of findings across studies.
Use plain language: "All three studies reporting X showed improvement..."
Do not calculate pooled estimates — this is narrative synthesis only.
If meta-analysis is warranted, flag it for the researcher.

**c) Heterogeneity**
Note sources of conceptual heterogeneity (different populations, doses,
follow-up durations) and methodological heterogeneity (different measurement
tools, timepoints, designs). Do not calculate I² — flag if statistical
heterogeneity assessment is needed.

**d) Certainty of evidence (GRADE)**
If `config/review-profile.yml` has `grade: true`, apply GRADE per outcome:

| Factor | Assessment |
|---|---|
| Study design (starting certainty) | RCTs = High; Observational = Low |
| Risk of bias | Downgrade if most studies High RoB |
| Inconsistency | Downgrade if direction of effect inconsistent |
| Indirectness | Downgrade if population/intervention differs from review question |
| Imprecision | Downgrade if wide CIs or small total N |
| Publication bias | Downgrade if suspected |

Certainty ratings: High / Moderate / Low / Very Low

### 4. Evidence gaps
Identify and report:
- Outcomes defined in the review question but not reported by any included study
- Populations specified in PICO but not represented in included studies
- Study designs absent from the evidence base
- Follow-up durations not covered

### 5. Recommendations
Based on gaps identified, provide brief, specific recommendations for
future research. These are observational recommendations from the evidence
base — not editorial opinions.

---

## Output

Write to `reports/synthesis-report.md`:

```markdown
# Narrative Synthesis Report
## Review: [title]
## Date: [YYYY-MM-DD]
## Studies included in synthesis: [n]
## Studies excluded (pending adjudication): [list]

---

## 1. Study Characteristics
[summary table]

---

## 2. Synthesis by Outcome

### Outcome 1: [name]
#### Findings
[table of study results]
#### Direction of Effect
[narrative]
#### Heterogeneity
[narrative]
#### Certainty of Evidence (GRADE)
[table if applicable]

[repeat for each outcome]

---

## 3. Evidence Gaps
[structured list]

---

## 4. Recommendations for Future Research
[structured list]

---

## Synthesis Notes
> Flagged for researcher review:
- Papers excluded from synthesis: [list with reason]
- Outcomes where meta-analysis may be warranted: [list]
- GRADE downgrades requiring researcher confirmation: [list]
```

### Console output
```
✅ Synthesis complete
   Studies synthesised: [n]
   Outcomes covered: [n]
   Evidence gaps identified: [n]
   Output: reports/synthesis-report.md
   Next step: human review of synthesis before manuscript preparation
```

---

## Hard Rules
- Never calculate a pooled effect estimate — flag for meta-analyst
- Never synthesise over a paper still in PENDING_ADJUDICATION
- Never assign GRADE certainty without showing the downgrade rationale
- Synthesis is descriptive — do not editorialize or advocate for findings
