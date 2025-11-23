#!/usr/bin/env bash
# Pre-Deployment Validation Script
# Runs comprehensive checks to ensure codebase is ready for Salesforce org deployment
#
# Env vars (optional):
#   SKIP_APEX_TESTS  - if 'true'|'yes'|'1', skip Apex test execution (default: false)
#   SKIP_DEPLOY_VALIDATE - if 'true'|'yes'|'1', skip sf project deploy validate (default: false)
#   ORG_ALIAS        - Salesforce org alias for deployment validation (optional)
#
# Usage:
#   # Full validation (recommended)
#   scripts/validate_deployment.sh
#
#   # Quick validation (skip Apex tests and deploy validate)
#   SKIP_APEX_TESTS=true SKIP_DEPLOY_VALIDATE=true scripts/validate_deployment.sh
#
#   # With specific org alias
#   ORG_ALIAS=sandbox scripts/validate_deployment.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track validation results
FAILED_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0

# Helper functions
info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
  ((PASSED_CHECKS++)) || true
}

error() {
  echo -e "${RED}✗${NC} $1" >&2
  ((FAILED_CHECKS++)) || true
}

warning() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((WARNINGS++)) || true
}

section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if Salesforce org is connected
is_org_connected() {
  if [ -n "${ORG_ALIAS:-}" ]; then
    sf org list --json 2>/dev/null | grep -q "\"alias\":\s*\"${ORG_ALIAS}\"" || return 1
  else
    sf org list --json 2>/dev/null | grep -q '"isDefaultUsername":\s*true' || return 1
  fi
}

# Parse environment variables
SKIP_APEX_TESTS=${SKIP_APEX_TESTS:-false}
SKIP_DEPLOY_VALIDATE=${SKIP_DEPLOY_VALIDATE:-false}

# Truthy check helper
is_truthy() {
  case "$1" in
    [Tt][Rr][Uu][Ee]|[Yy]|[Yy][Ee][Ss]|1) return 0 ;;
    *) return 1 ;;
  esac
}

# Start validation
echo ""
section "Pre-Deployment Validation"
echo ""
info "Starting comprehensive validation checks..."
info "Skip Apex Tests: $(is_truthy "$SKIP_APEX_TESTS" && echo 'Yes' || echo 'No')"
info "Skip Deploy Validate: $(is_truthy "$SKIP_DEPLOY_VALIDATE" && echo 'Yes' || echo 'No')"
echo ""

# 1. JavaScript/LWC Linting (ESLint)
section "1. JavaScript/LWC Linting (ESLint)"
if command_exists npm; then
  if npm run lint:eslint >/dev/null 2>&1; then
    success "ESLint checks passed"
  else
    error "ESLint checks failed. Run 'npm run lint:eslint' for details."
  fi
else
  error "npm not found. Cannot run ESLint checks."
fi

# 2. Prettier Formatting Checks
section "2. Prettier Formatting Checks"
if command_exists npm; then
  if npm run lint:prettier >/dev/null 2>&1; then
    success "Prettier formatting checks passed"
  else
    error "Prettier formatting checks failed. Run 'npm run format' to auto-fix."
  fi
else
  error "npm not found. Cannot run Prettier checks."
fi

# 3. Apex Static Analysis
section "3. Apex Static Analysis (SF Scanner)"
if command_exists sf; then
  if npm run lint:apex >/dev/null 2>&1; then
    success "Apex static analysis passed"
  else
    warning "Apex static analysis found issues. Review output above."
  fi
else
  warning "Salesforce CLI (sf) not found. Skipping Apex static analysis."
fi

# 4. LWC Unit Tests
section "4. LWC Unit Tests"
if command_exists npm; then
  if npm run test:unit:coverage >/dev/null 2>&1; then
    success "LWC unit tests passed with coverage"
  else
    error "LWC unit tests failed. Run 'npm run test:unit:coverage' for details."
  fi
else
  error "npm not found. Cannot run LWC unit tests."
fi

# 5. Salesforce Deployment Validation
if ! is_truthy "$SKIP_DEPLOY_VALIDATE"; then
  section "5. Salesforce Deployment Manifest Validation"
  if command_exists sf; then
    if is_org_connected; then
      ORG_FLAG=""
      if [ -n "${ORG_ALIAS:-}" ]; then
        ORG_FLAG="--target-org ${ORG_ALIAS}"
      fi
      # Force API version 62.0 to match package.xml and avoid Gack
      if sf project deploy start --dry-run --manifest manifest/package.xml --ignore-conflicts --api-version 62.0 ${ORG_FLAG} >/dev/null 2>&1; then
        success "Deployment manifest validation passed"
      else
        error "Deployment manifest validation failed. Run 'sf project deploy start --dry-run --manifest manifest/package.xml --ignore-conflicts --api-version 62.0' for details."
      fi
    else
      warning "No Salesforce org connected. Skipping deployment validation."
      info "To validate deployment, connect to an org: sf org login web"
    fi
  else
    warning "Salesforce CLI (sf) not found. Skipping deployment validation."
  fi
else
  section "5. Salesforce Deployment Manifest Validation"
  info "Skipped (SKIP_DEPLOY_VALIDATE=true)"
fi

# 6. Apex Test Execution (Optional)
if ! is_truthy "$SKIP_APEX_TESTS"; then
  section "6. Apex Test Execution"
  if command_exists sf; then
    if is_org_connected; then
      ORG_FLAG=""
      if [ -n "${ORG_ALIAS:-}" ]; then
        ORG_FLAG="--target-org ${ORG_ALIAS}"
      fi
      info "Running Apex tests (this may take a few minutes)..."
      if sf apex run test --test-level RunLocalTests --code-coverage ${ORG_FLAG} >/dev/null 2>&1; then
        success "Apex tests passed with code coverage"
      else
        error "Apex tests failed. Run 'sf apex run test --test-level RunLocalTests --code-coverage' for details."
      fi
    else
      warning "No Salesforce org connected. Skipping Apex test execution."
      info "To run Apex tests, connect to an org: sf org login web"
    fi
  else
    warning "Salesforce CLI (sf) not found. Skipping Apex test execution."
  fi
else
  section "6. Apex Test Execution"
  info "Skipped (SKIP_APEX_TESTS=true)"
fi

# Summary Report
section "Validation Summary"
echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
  success "All critical checks passed!"
  if [ $WARNINGS -gt 0 ]; then
    warning "$WARNINGS warning(s) found. Review above for details."
  fi
  echo ""
  info "✓ Passed: $PASSED_CHECKS"
  [ $WARNINGS -gt 0 ] && info "⚠ Warnings: $WARNINGS" || true
  echo ""
  success "Codebase is ready for deployment!"
  exit 0
else
  error "Validation failed with $FAILED_CHECKS error(s)"
  [ $WARNINGS -gt 0 ] && warning "$WARNINGS warning(s) found" || true
  echo ""
  info "✗ Failed: $FAILED_CHECKS"
  info "✓ Passed: $PASSED_CHECKS"
  [ $WARNINGS -gt 0 ] && info "⚠ Warnings: $WARNINGS" || true
  echo ""
  error "Please fix the errors above before deploying."
  exit 1
fi
