#!/usr/bin/env bash
# Validate MkDocs site zip size before uploading as a Salesforce Static Resource
# - Warns (does not fail) if the zipped site exceeds the 5 MB Static Resource limit
# - Emits GitHub Actions warnings/outputs when possible
#
# Env vars (optional):
#   SITE_DIR   - directory containing built MkDocs site (default: site)
#   MAX_MB     - MB threshold (default: 5)
#   SR_NAME    - Static Resource name for messages (default: SfdxHardis_MkDocsSite_CICD)
#   ZIP_FILE   - path for temporary zip (default: mktemp)
#
# Usage:
#   # After `mkdocs build` has produced ./site
#   scripts/validate_docs_size.sh
#
#   # Custom threshold or site dir
#   SITE_DIR=site MAX_MB=5 scripts/validate_docs_size.sh

set -u

SITE_DIR=${SITE_DIR:-site}
MAX_MB=${MAX_MB:-5}
SR_NAME=${SR_NAME:-SfdxHardis_MkDocsSite_CICD}

# Create temp ZIP file path
if command -v mktemp >/dev/null 2>&1; then
  ZIP_FILE=${ZIP_FILE:-"$(mktemp -t mkdocs_site).zip"}
else
  ZIP_FILE=${ZIP_FILE:-"/tmp/mkdocs_site_$$.zip"}
fi

# Helper: print as GitHub Actions warning if available
warn() {
  local msg="$1"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    # Append to step summary
    echo "${msg}" >>"$GITHUB_STEP_SUMMARY"
  fi
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    # Emit annotation
    echo "::warning ::${msg}"
  fi
  echo "WARNING: ${msg}" 1>&2
}

info() {
  echo "$1"
}

# 0) Preconditions
if [ ! -d "$SITE_DIR" ]; then
  info "Docs size check: site dir '$SITE_DIR' not found. Skipping validation (no failure)."
  exit 0
fi
if ! command -v zip >/dev/null 2>&1; then
  warn "'zip' command not found. Skipping zipped size validation. Consider installing zip to enable accurate pre-checks."
  exit 0
fi

# 1) Zip the site directory (quiet, strip extra attrs for minimal size)
(
  cd "$SITE_DIR" && zip -r -q -X "$ZIP_FILE" .
) || {
  warn "Failed to zip site directory '$SITE_DIR'. Skipping validation (no failure)."
  exit 0
}

# 2) Determine zip size in bytes (macOS vs Linux stat)
SIZE_BYTES=""
if stat -f%z "$ZIP_FILE" >/dev/null 2>&1; then
  SIZE_BYTES=$(stat -f%z "$ZIP_FILE")
elif stat -c%s "$ZIP_FILE" >/dev/null 2>&1; then
  SIZE_BYTES=$(stat -c%s "$ZIP_FILE")
else
  warn "Could not determine zip size (stat not available). Skipping validation."
  rm -f "$ZIP_FILE"
  exit 0
fi

THRESHOLD_BYTES=$(( MAX_MB * 1024 * 1024 ))

# 3) Human-friendly MB values with 1 decimal
mb_fmt() {
  awk -v bytes="$1" 'BEGIN { printf "%.1f", bytes/1024/1024 }'
}

SIZE_MB=$(mb_fmt "$SIZE_BYTES")
LIMIT_MB=$(mb_fmt "$THRESHOLD_BYTES")

# 4) Emit outputs for CI if available
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "docs_zip_path=$ZIP_FILE"
    echo "docs_zip_bytes=$SIZE_BYTES"
    echo "docs_zip_size_mb=$SIZE_MB"
    echo "docs_zip_over_limit=$([ "$SIZE_BYTES" -gt "$THRESHOLD_BYTES" ] && echo true || echo false)"
  } >> "$GITHUB_OUTPUT"
fi

# 5) Warn or info
if [ "$SIZE_BYTES" -gt "$THRESHOLD_BYTES" ]; then
  warn "Doc package size ${SIZE_MB} MB exceeds ${LIMIT_MB} MB limit. ${SR_NAME} Static Resource upload will fail in Salesforce. Consider removing large assets or slimming the site before upload."
else
  info "Doc package size ${SIZE_MB} MB within ${LIMIT_MB} MB limit. Proceeding."
fi

# 6) Cleanup temp zip but keep data emitted above
rm -f "$ZIP_FILE" >/dev/null 2>&1 || true

# Always succeed (warn-only behavior)
exit 0

