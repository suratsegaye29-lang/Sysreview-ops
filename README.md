# review-ops

Multi-agent systematic review data extraction system. Operates under PRISMA 2020 and Cochrane Handbook standards.

## Setup
```bash
cp config/review-profile.example.yml config/review-profile.yml
# Fill in review-profile.yml, modes/_shared.md, and questions/questions.md
```

## Quick Commands
```
/review-ops form          → Generate extraction form from your questions
/review-ops extract       → Extract a single paper
/review-ops batch         → Process all pending papers
/review-ops validate      → Reconcile dual extractions
/review-ops qa            → Risk of bias assessment
/review-ops synthesis     → Narrative synthesis
/review-ops audit         → Pipeline integrity check
/review-ops status        → Tracker dashboard
```

See `docs/WORKFLOW.md` for the full end-to-end process.
