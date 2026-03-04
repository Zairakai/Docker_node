#!/bin/bash
set -euo pipefail

# Health check script for Node.js test image
# Extends dev health check with testing-specific checks

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

EXIT_CODE=0
CHECKS_PASSED=0
CHECKS_TOTAL=0
DEV_HEALTH_PASSED=false

log_info() { echo -e "${GREEN}[TEST-HEALTH]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[TEST-HEALTH]${NC} $1" >&2; }
log_error() { echo -e "${RED}[TEST-HEALTH]${NC} $1" >&2; }
log_step() { echo -e "${BLUE}[TEST-HEALTH]${NC} $1"; }

increment_check() { CHECKS_TOTAL=$((CHECKS_TOTAL + 1)); }
pass_check() { CHECKS_PASSED=$((CHECKS_PASSED + 1)); log_info "✓ $1"; }
fail_check() { EXIT_CODE=1; log_error "✗ $1"; }

run_dev_health_check() {
  log_step "Running development health check..."

  if [ -x "/usr/local/bin/healthcheck-dev.sh" ]; then
    if /usr/local/bin/healthcheck-dev.sh >/dev/null 2>&1; then
      DEV_HEALTH_PASSED=true
      log_info "Development health check passed"
    else
      log_error "Development health check failed"
      EXIT_CODE=1
    fi
  else
    log_warn "Development health check script not found"
  fi
}

check_testing_frameworks() {
  log_step "Checking testing frameworks..."

  increment_check
  if command -v vitest >/dev/null 2>&1; then
    local version
    version=$(vitest --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
    pass_check "vitest (${version:-unknown})"
  else
    fail_check "vitest not installed"
  fi

  increment_check
  if command -v c8 >/dev/null 2>&1; then
    local version
    version=$(c8 --version 2>/dev/null || echo "")
    pass_check "c8 coverage (${version:-unknown})"
  else
    fail_check "c8 not installed"
  fi
}

check_testing_config() {
  log_step "Checking testing configuration..."

  increment_check
  if [ -f "/usr/local/etc/node-config.json" ]; then
    if node -e "
      const config = JSON.parse(require('fs').readFileSync('/usr/local/etc/node-config.json', 'utf8'));
      if (config.environment !== 'test') process.exit(1);
    " 2>/dev/null; then
      pass_check "Test node-config.json is valid"
    else
      fail_check "Test node-config.json is invalid or wrong environment"
    fi
  else
    fail_check "Test node-config.json not found"
  fi

  increment_check
  if [ "${NODE_ENV:-}" = "test" ]; then
    pass_check "NODE_ENV=test"
  else
    fail_check "NODE_ENV is not set to test (current: ${NODE_ENV:-unset})"
  fi
}

check_testing_directories() {
  log_step "Checking testing directories..."

  increment_check
  local missing=""
  for dir in "$HOME/test-results" "$HOME/coverage"; do
    if [ ! -d "$dir" ]; then
      missing="$missing $(basename "$dir")"
    fi
  done
  if [ -z "$missing" ]; then
    pass_check "Test output directories exist"
  else
    fail_check "Missing test directories:$missing"
  fi

  increment_check
  if [ -w "/tmp" ]; then
    pass_check "Temporary directory writable"
  else
    fail_check "Temporary directory not writable"
  fi
}

perform_testing_health_check() {
  log_info "Starting testing environment health check..."

  run_dev_health_check
  check_testing_frameworks
  check_testing_config
  check_testing_directories

  log_info "Checks passed: $CHECKS_PASSED/$CHECKS_TOTAL"

  if [ "$EXIT_CODE" -eq 0 ] && [ "$DEV_HEALTH_PASSED" = true ]; then
    log_info "Overall status: HEALTHY (Testing Ready)"
  else
    log_error "Overall status: UNHEALTHY ($((CHECKS_TOTAL - CHECKS_PASSED)) check(s) failed)"
  fi

  return "$EXIT_CODE"
}

perform_testing_health_check
