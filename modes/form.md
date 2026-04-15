# Mode: form — Question-to-Extraction-Form Converter

## Trigger
`/review-ops form`

## Purpose
Convert researcher-written questions from `questions/questions.md` into a structured, standardised data extraction form at `forms/extraction-form.md`.

## Instructions

1. Load `modes/_shared.md` for review context (title, PICO, inclusion/exclusion rules).
2. Read `questions/questions.md`. If the file doesn't exist, halt and tell the researcher to create it first using `questions/questions.example.md` as a template.
3. Group all questions into the standard domain blocks below. Use judgment to place each question in the most appropriate block — do not force questions into blocks where they don't belong.
4. For each question, generate a structured field entry with all five attributes defined.
5. Write the completed form to `forms/extraction-form.md`.
6. Print a confirmation summary: total fields generated, count per block, any questions that were ambiguous to classify (flag these for researcher review).

## Standard Domain Blocks

| Block | Domain |
|---|---|
| A | Study Identification |
| B | Study Design |
| C | Population / Sample |
| D | Intervention / Exposure |
| E | Outcomes |
| F | Results |
| G | Risk of Bias / Quality |
| H | Reviewer Notes |

Block A (Study Identification) is always pre-populated with mandatory baseline fields regardless of what questions are asked:
- study_id, authors, year, doi, title, journal, country, funding_source

## Field Specification Format

For each question, generate:

```
| field_label | Human-readable prompt | data_type | mandatory | rob_grade_domain |
```

- **field_label**: snake_case, concise, unique within the form
- **Human-readable prompt**: the question an extractor would ask themselves while reading the paper
- **data_type**: one of `free_text` / `numeric` / `categorical` / `date` / `boolean` / `verbatim_quote`
- **mandatory**: `Yes` or `No`
- **rob_grade_domain**: the RoB 2 / GRADE domain this field informs, or `N/A`

## Output Format for `forms/extraction-form.md`

```markdown
# Data Extraction Form
## Review: [title from review-profile.yml]
## PROSPERO ID: [id]
## Generated: [YYYY-MM-DD]
## Version: 1.0

> This form was auto-generated from questions/questions.md.
> Do not edit field labels after extraction has begun — it breaks tracker alignment.
> To add fields, increment version and document the change.

---

### Block A — Study Identification
| Field Label | Prompt | Type | Mandatory | RoB/GRADE Domain |
|---|---|---|---|---|
| study_id | Assign a unique ID in AuthorYYYY format | free_text | Yes | N/A |
| authors | List all authors (Last, First format) | free_text | Yes | N/A |
| year | Publication year | numeric | Yes | N/A |
| doi | DOI or URL | free_text | Yes | N/A |
| title | Full paper title | free_text | Yes | N/A |
| journal | Journal name | free_text | Yes | N/A |
| country | Country where study was conducted | free_text | Yes | N/A |
| funding_source | Funding source(s) as reported | verbatim_quote | Yes | Reporting bias |

---

### Block B — Study Design
[generated fields]

---

### Block C — Population / Sample
[generated fields]

---

### Block D — Intervention / Exposure
[generated fields]

---

### Block E — Outcomes
[generated fields]

---

### Block F — Results
[generated fields]

---

### Block G — Risk of Bias / Quality
[generated fields — note: detailed domain-level assessment handled by /qa mode]

---

### Block H — Reviewer Notes
| Field Label | Prompt | Type | Mandatory | RoB/GRADE Domain |
|---|---|---|---|---|
| reviewer_notes | Any uncertainties, anomalies, or items for adjudication | free_text | No | N/A |
| adjudication_needed | Does this paper need human adjudication? | boolean | No | N/A |
```

## Validation Before Writing
Before writing the output file, check:
- [ ] No duplicate field labels
- [ ] Every mandatory field has a data_type assigned
- [ ] Block A baseline fields are present and unmodified
- [ ] At least one field maps to a RoB/GRADE domain

If any check fails, report the issue and do not write the file until resolved.
