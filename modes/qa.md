# Mode: qa — Quality Assessment & Risk of Bias

## Trigger
`/review-ops qa [paper_filename or study_id]`

## Purpose
Perform structured methodological quality assessment using the appropriate
tool for the study design. Produce a domain-by-domain judgement with
verbatim evidence from the paper for every rating assigned.

## Pre-flight Checks
Verify:
- `config/review-profile.yml` has `quality_tool` set
- The target paper exists in `papers/` OR `extractions/[study_id]-extraction-R1.md` exists
- `modes/_shared.md` is populated

If `quality_tool` is set to `custom`, halt and ask the researcher to paste
their custom tool's domain structure before proceeding.

---

## Tool Selection

Read `quality_tool` from `config/review-profile.yml` and apply the
corresponding domain structure below.

---

### RoB 2 — Cochrane Risk of Bias Tool 2.0
_For randomised controlled trials_

| Domain | What to assess |
|---|---|
| D1 — Randomisation process | Was the allocation sequence random? Was it concealed? Were groups balanced at baseline? |
| D2 — Deviations from intended interventions | Were participants/carers aware of assignment? Were there protocol deviations? Was analysis intention-to-treat? |
| D3 — Missing outcome data | Were outcome data available for nearly all participants? Was missingness related to the true outcome? |
| D4 — Outcome measurement | Was the method of measurement appropriate? Were assessors aware of assignment? |
| D5 — Selection of reported results | Were results pre-specified? Is the reported analysis consistent with the registered protocol? |

**Judgements per domain**: Low risk / Some concerns / High risk
**Overall RoB**: Low / Some concerns / High
- Overall is Low only if ALL domains are Low
- Overall is Some concerns if any domain is Some concerns and none are High
- Overall is High if any domain is High

---

### ROBINS-I — Risk of Bias in Non-Randomised Studies of Interventions

| Domain | What to assess |
|---|---|
| D1 — Confounding | Were all important confounders measured and controlled for? |
| D2 — Selection of participants | Was selection into the study related to intervention and outcome? |
| D3 — Classification of interventions | Was intervention status defined and applied consistently? |
| D4 — Deviations from intended interventions | Were co-interventions balanced? Was adherence measured? |
| D5 — Missing data | Were outcome data complete? Was missingness handled appropriately? |
| D6 — Outcome measurement | Was measurement of outcomes appropriate and consistent across groups? |
| D7 — Selection of reported results | Is the reported analysis consistent with the pre-specified plan? |

**Judgements per domain**: Low / Moderate / Serious / Critical / No information
**Overall**: Low / Moderate / Serious / Critical

---

### Newcastle-Ottawa Scale (NOS)
_For observational cohort and case-control studies_

**Cohort studies (max 9 stars):**

| Category | Item | Max Stars |
|---|---|---|
| Selection | Representativeness of exposed cohort | 1 |
| Selection | Selection of non-exposed cohort | 1 |
| Selection | Ascertainment of exposure | 1 |
| Selection | Outcome not present at start | 1 |
| Comparability | Comparability of cohorts on design/analysis | 2 |
| Outcome | Assessment of outcome | 1 |
| Outcome | Follow-up length adequate | 1 |
| Outcome | Adequacy of follow-up | 1 |

**Quality thresholds**: ≥ 7 stars = Good; 4–6 = Fair; < 4 = Poor

---

### QUADAS-2 — Quality Assessment of Diagnostic Accuracy Studies

| Domain | Signalling Questions | Judgement |
|---|---|---|
| Patient selection | Was a consecutive or random sample enrolled? Was a case-control design avoided? Did the study avoid inappropriate exclusions? | Low / High / Unclear |
| Index test | Were results interpreted without knowledge of reference standard? | Low / High / Unclear |
| Reference standard | Is the reference standard likely to correctly classify the target condition? Were results interpreted without knowledge of index test? | Low / High / Unclear |
| Flow and timing | Was there an appropriate interval between index test and reference standard? Did all patients receive the same reference standard? Were all patients included in the analysis? | Low / High / Unclear |

Each domain also receives an **Applicability** judgement: Low concern / High concern / Unclear

---

## Extraction Instructions

For each domain of the applicable tool:

1. **Search the paper** for evidence relevant to that domain
2. **Record the verbatim evidence** — quote the exact text from the paper that
   informs your judgement; include the source location (section, page, table)
3. **Assign a judgement** using only the permitted ratings for that tool
4. **State the rationale** linking the evidence to the judgement in 1–3 sentences

If no relevant evidence exists for a domain, record:
- Judgement: `No information` (ROBINS-I) or `Unclear` (QUADAS-2) or `Some concerns` (RoB 2)
- Evidence: `[NOT REPORTED]`
- Do not infer low risk from absence of reporting

5. After all domains, assign the **Overall judgement** using the aggregation
   rules defined for the applicable tool above.

---

## Output

### QA record
Write to `extractions/[study_id]-qa.md`:

```markdown
# Quality Assessment Record
## Study ID: [study_id]
## Tool: [RoB2 / ROBINS-I / NOS / QUADAS-2]
## Assessor: [initials]
## Date: [YYYY-MM-DD]

---

### Domain Assessments

#### [Domain Name]
- **Judgement**: [rating]
- **Evidence**: "[verbatim quote from paper]" ([source location])
- **Rationale**: [1–3 sentence explanation]

[repeat for each domain]

---

### Overall Risk of Bias / Quality
- **Overall judgement**: [rating]
- **Rationale**: [explanation referencing domain judgements]

---

### Assessor Notes
[Any uncertainties, edge cases, or items for second assessor review]
```

### Tracker update
Append a `qa_status` and `overall_rob` value to the tracker row for this study_id:
- `qa_status`: `QA_COMPLETE`
- `overall_rob`: the overall judgement rating

### Console output
```
✅ QA complete: [study_id]
   Tool: [tool name]
   Overall judgement: [rating]
   Domains assessed: [n]
   Domains with concerns: [n]
   Output: extractions/[study_id]-qa.md
   Next step: /review-ops validate [study_id] if R2 is complete
```

---

## Hard Rules
- Never assign Low risk from absence of reporting — absence = Unclear or No information
- Always quote verbatim evidence; never paraphrase the paper's methods as your rationale
- Never upgrade an Overall judgement beyond what the domain rules permit
- QA is a separate pass from extraction — do not conflate the two
