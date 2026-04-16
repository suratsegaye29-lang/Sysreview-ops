Load `modes/batch.md` and follow its instructions to run batch extraction across all PENDING papers in the tracker.

This invokes `batch/batch-runner.sh` which spawns parallel claude -p workers. Run all pre-flight checks (tracker has PENDING rows, forms/extraction-form.md exists, config is populated) before starting.

$ARGUMENTS
