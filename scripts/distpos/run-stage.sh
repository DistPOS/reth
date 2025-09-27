#!/usr/bin/env bash
# Lightweight runner to execute a stage-specific subset of tests and collect artifacts.
# Usage:
#   ./scripts/distpos/run-stage.sh <STAGE_NUMBER> <OUTPUT_DIR>
#
# Example:
#   ./scripts/distpos/run-stage.sh 3 artifacts/distpos/stage3/20250101T000000Z
#
# Notes:
# - This script does not enable ignored tests by default; it passes the flags to include them.
# - It captures stdout/stderr to the output directory for inspection.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <STAGE_NUMBER> <OUTPUT_DIR>"
  exit 2
fi

STAGE="$1"
OUTDIR="$2"

mkdir -p "$OUTDIR"

echo "[distpos] Listing tests for stage$STAGE..." | tee "$OUTDIR/list.log"
# List all tests in the crate (for traceability)
cargo test -p distpos-tests -- --list | tee -a "$OUTDIR/list.log"

echo "[distpos] Running stage$STAGE tests (including ignored)..." | tee "$OUTDIR/run.log"
# Run only tests prefixed with stageN_, include ignored, exact prefix match
# Note: --exact with a trailing underscore filters by exact test name prefix.
set +e
cargo test -p distpos-tests --lib -- --include-ignored --ignored --exact "stage${STAGE}_" 2>&1 | tee -a "$OUTDIR/run.log"
CODE=${PIPESTATUS[0]}
set -e

echo "[distpos] Exit code: $CODE" | tee -a "$OUTDIR/run.log"

# Simple metrics snapshot placeholder (extend when metrics endpoints are wired)
echo "[distpos] Artifacts collected at: $OUTDIR"
exit "$CODE"