# Mode: extract — Single Paper Extraction

## Trigger
`/review-ops extract [paper_filename]`

## Purpose
Read a single paper and populate every field in the extraction form, producing a
complete, flagged, source-traced extraction record.

## Pre-flight Checks
Before extracting, verify all three context files exist and are populated:
- `config/review-profile.yml` — must have title and quality_tool set
- `forms/extraction-form.md` — must exist (run `/review-ops form` first if not)
- `modes/_shared.md` — must have PICO and inclusion/exclusion criteria filled in

If any file is missing or unpopulated, halt and state exactly what needs to be
completed before extraction can proceed.

Also verify the target paper exists in `papers/`. Accepted formats:
- `.md` transcript
- `.pdf` (read via file tool)
- `.txt`

If the paper is not found, halt and list what is present in `papers/`.

---

## Extraction Instructions

### 1. Load the extraction form
Read every field defined in `forms/extraction-form.md` in block order (A → H).
This is your complete field list — do not add or remove fields.

### 2. Read the paper in full before extracting
Do not extract field by field as you read. Read the entire paper first to build
a complete picture, then extract. This prevents early-read bias where abstract
framing distorts later data extraction.

### 3. Extract field by field
For each field in the form:

**a) Locate** — Find the section(s) of the paper where this data appears.
More than one section may be relevant (e.g., sample size in abstract AND methods).
When values conflict across sections, record both and apply `[CONFLICT]`.

**b) Extract** — Copy numeric values, p-values, and effect estimates verbatim.
For narrative fields, write a tight, accurate summary — do not editorialize.

**c) Source** — Record the source location in this format:
- `Methods, p.3` — for page-referenced PDFs
- `Section 2.1` — for section-referenced documents
- `Table 2` / `Figure 3` — for tabular or figure data
- `Abstract` — only if the data does not appear elsewhere

**d) Flag** — Apply the appropriate flag(s):
- `[NOT REPORTED]` — data not present anywhere in the paper; leave value blank
- `[AMBIGUOUS]` — data present but unclear or inconsistently described; record verbatim
- `[CONFLICT]` — contradictory values within the paper; record all values found
- `[CALCULATED]` — value derived by you, not directly stated; show your working in reviewer notes
- `[FROM FIGURE]` — extracted from a figure only; note that value is approximate

A field may carry more than one flag. Multiple flags are space-separated.

### 4. Completeness Score
After all fields are extracted, calculate:

```
Completeness Score = (mandatory fields with a value / total mandatory fields) × 100
```

A field counts as having a value if it contains anything other than `[NOT REPORTED]`.
Record the score in the extraction record header.

### 5. Flag Summary
In Block H, count and list all flagged fields by flag type.
Do not suppress or minimise flags — the researcher needs full visibility.

### 6. Extraction Confidence
Assign an overall confidence rating:
- **High**: ≥ 80% completeness, no major ambiguities, all key results traceable to text
- **Medium**: 60–79% completeness, or ≥ 3 ambiguous fields, or one result only in a figure
- **Low**: < 60% completeness, or primary outcome not reported, or paper quality is poor

State the reason if not High.

---

## Output

### Primary output
Write the completed extraction to:
```
extractions/[study_id]-extraction-R1.md
```
Use `templates/extraction-output.md` as the base structure.
Populate every block with the fields from `forms/extraction-form.md`.
Do not leave any field row blank — every field must have either a value or `[NOT REPORTED]`.

### Tracker update
Append one row to `data/tracker.tsv`:

```
[study_id]	[paper_title]	[extractor_initials]	[YYYY-MM-DD]	[completeness_%]	[flag_list]	EXTRACTED_R1
```

- `flag_list`: comma-separated list of field labels that carry any flag
- `status`: always `EXTRACTED_R1` after a first-pass extraction

### Console output
After writing the file, print a brief extraction summary:
```
✅ Extraction complete: [study_id]
   Completeness: [X%]
   Mandatory fields missing: [n]
   Flags: [NOT REPORTED: n] [AMBIGUOUS: n] [CONFLICT: n] [CALCULATED: n] [FROM FIGURE: n]
   Confidence: [High / Medium / Low]
   Output: extractions/[study_id]-extraction-R1.md
   Next step: /review-ops qa [paper] — then assign to second reviewer for R2 pass
```

---

## Hard Rules (repeated from CLAUDE.md for emphasis)
- Never populate a field with inferred or assumed data
- Never round or paraphrase a p-value — copy exactly as written
- Never resolve a `[CONFLICT]` — surface it; a human adjudicates
- Never mark status as anything other than `EXTRACTED_R1` after a first pass
- If a result exists only in a figure, note `[FROM FIGURE]` and record the
  approximate value with explicit uncertainty (e.g., `~42% [FROM FIGURE, ±2%]`)
