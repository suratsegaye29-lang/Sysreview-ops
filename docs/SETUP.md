# review-ops — Setup Guide

## Requirements
- Claude Code installed and authenticated
- Bash shell (macOS / Linux / WSL)
- Papers available as PDF or Markdown transcripts

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/review-ops.git
cd review-ops
mkdir -p logs  # for batch worker logs
chmod +x batch/batch-runner.sh
```

## Configuration

### 1. Review profile
```bash
cp config/review-profile.example.yml config/review-profile.yml
```
Edit `config/review-profile.yml` with your review metadata, PICO elements,
and quality tool selection.

### 2. Shared review context
Open `modes/_shared.md` and fill in:
- Review title and registration
- PICO / SPIDER / PCC framework
- Inclusion and exclusion criteria
- Any language or publication constraints

### 3. Extraction questions
Create `questions/questions.md` using `questions/questions.example.md` as
a reference. Write questions in plain language — the form mode will
structure them.

## First Run

```bash
# Open Claude Code
claude

# Generate extraction form
/review-ops form

# Review the generated form
# Edit forms/extraction-form.md if any fields need adjustment
# Then add papers to papers/ and rows to data/tracker.tsv

# Begin extraction
/review-ops batch
```

## Tracker Setup

Before running batch, populate `data/tracker.tsv` with one row per paper:
study_id    paper_title    extractor    date    completeness_score    flags    status
Smith2023   Title here     SH           2026-04-13                            PENDING

Use tabs between columns. Leave completeness and flags blank.
