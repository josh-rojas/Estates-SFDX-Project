#!/usr/bin/env bash
# Validate MkDocs site zip size before uploading as a Salesforce Static Resource
# - Fails or warns if the zipped site exceeds the 5 MB Static Resource limit
# - Emits GitHub Actions warnings/outputs when possible
#
# Env vars (optional):
#   SITE_DIR       - directory containing built MkDocs site (default: site)
#   MAX_MB         - MB threshold (default: 5)
#   SR_NAME        - Static Resource name for messages (default: SfdxHardis_MkDocsSite_CICD)
#   ZIP_FILE       - path for temporary zip (default: mktemp)
#   FAIL_ON_LIMIT  - if 'true'|'yes'|'1', exit 1 when over limit (default: true)
#   STRICT         - if 'true'|'yes'|'1', fail when size cannot be evaluated (default: false)
#
# Usage:
#   # After `mkdocs build` has produced ./site
#   scripts/validate_docs_size.sh
#
#   # Custom threshold or site dir (warn-only mode)
#   FAIL_ON_LIMIT=false SITE_DIR=site MAX_MB=5 scripts/validate_docs_size.sh
#
#   # Strict CI example (fail on unknowns and on limit)
#   STRICT=true FAIL_ON_LIMIT=true mkdocs build -v && STRICT=true scripts/validate_docs_size.sh

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

# error helper with GitHub Actions annotation
err() {
  local msg="$1"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error ::${msg}"
  fi
  echo "ERROR: ${msg}" 1>&2
}

# truthy helper for environment booleans
is_truthy() {
  case "$1" in
    [Tt][Rr][Uu][Ee]|[Yy]|[Yy][Ee][Ss]|1) return 0 ;;
    *) return 1 ;;
  esac
}

# 0) Preconditions
if [ ! -d "$SITE_DIR" ]; then
  if is_truthy "${STRICT:-false}"; then
    err "Docs size check: site dir '$SITE_DIR' not found. Strict mode enabled; failing."
    exit 1
  fi
  info "Docs size check: site dir '$SITE_DIR' not found. Skipping validation (no failure)."
  exit 0
fi
if ! command -v zip >/dev/null 2>&1; then
  if is_truthy "${STRICT:-false}"; then
    err "'zip' command not found. Strict mode enabled; failing."
    exit 1
  fi
  warn "'zip' command not found. Skipping zipped size validation. Consider installing zip to enable accurate pre-checks."
  exit 0
fi

# 1) Zip the site directory (quiet, strip extra attrs for minimal size)
(
  cd "$SITE_DIR" && zip -r -q -X "$ZIP_FILE" .
) || {
  if is_truthy "${STRICT:-false}"; then
    err "Failed to zip site directory '$SITE_DIR'. Strict mode enabled; failing."
    exit 1
  fi
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
  if is_truthy "${STRICT:-false}"; then
    err "Could not determine zip size (stat not available). Strict mode enabled; failing."
    rm -f "$ZIP_FILE"
    exit 1
  fi
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

# 5) Warn or info; optionally fail when over the limit
if [ "$SIZE_BYTES" -gt "$THRESHOLD_BYTES" ]; then
  warn "Doc package size ${SIZE_MB} MB exceeds ${LIMIT_MB} MB limit. ${SR_NAME} Static Resource upload will fail in Salesforce."
  # Decide whether to fail the pipeline based on FAIL_ON_LIMIT (default: true)
  FAIL_ON_LIMIT=${FAIL_ON_LIMIT:-true}
  if is_truthy "$FAIL_ON_LIMIT"; then
    # Cleanup temp zip before exiting
    rm -f "$ZIP_FILE" >/dev/null 2>&1 || true
    exit 1
  fi
else
  info "Doc package size ${SIZE_MB} MB within ${LIMIT_MB} MB limit. Proceeding."
fi

# 6) Cleanup temp zip but keep data emitted above
rm -f "$ZIP_FILE" >/dev/null 2>&1 || true

# Succeed (warn-only mode or within limit)
exit 0

