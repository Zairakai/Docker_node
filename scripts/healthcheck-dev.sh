#!/bin/bash
set -euo pipefail

# Health check script for Node.js dev image
# Extends base health check with development-specific checks

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

EXIT_CODE=0
CHECKS_PASSED=0
CHECKS_TOTAL=0
BASE_HEALTH_PASSED=false

log_info() { echo -e "${GREEN}[DEV-HEALTH]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[DEV-HEALTH]${NC} $1" >&2; }
log_error() { echo -e "${RED}[DEV-HEALTH]${NC} $1" >&2; }
log_step() { echo -e "${BLUE}[DEV-HEALTH]${NC} $1"; }

increment_check() { CHECKS_TOTAL=$((CHECKS_TOTAL + 1)); }
pass_check() { CHECKS_PASSED=$((CHECKS_PASSED + 1)); log_info "✓ $1"; }
fail_check() { EXIT_CODE=1; log_error "✗ $1"; }

run_base_health_check() {
  log_step "Running base health check..."

  if [ -x "/usr/local/bin/healthcheck.sh" ]; then
    if /usr/local/bin/healthcheck.sh >/dev/null 2>&1; then
      BASE_HEALTH_PASSED=true
      log_info "Base health check passed"
    else
      log_error "Base health check failed"
      EXIT_CODE=1
    fi
  else
    log_warn "Base health check script not found"
  fi
}

check_development_tools() {
  log_step "Checking development tools..."

  increment_check
  if command -v tsc >/dev/null 2>&1; then
    local ts_version
    ts_version=$(tsc --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
    pass_check "TypeScript (${ts_version:-unknown})"
  else
    fail_check "TypeScript not installed"
  fi

  increment_check
  if command -v ts-node >/dev/null 2>&1; then
    pass_check "ts-node available"
  else
    fail_check "ts-node not installed"
  fi

  increment_check
  if command -v nodemon >/dev/null 2>&1; then
    local nodemon_version
    nodemon_version=$(nodemon --version 2>/dev/null || echo "")
    pass_check "nodemon (${nodemon_version:-unknown})"
  else
    fail_check "nodemon not installed"
  fi

  increment_check
  if command -v pm2 >/dev/null 2>&1; then
    pass_check "pm2 available"
  else
    fail_check "pm2 not installed"
  fi
}

check_development_config() {
  log_step "Checking development configuration..."

  increment_check
  if [ -f "/usr/local/etc/node-config.json" ]; then
    if node -e "
      const config = JSON.parse(require('fs').readFileSync('/usr/local/etc/node-config.json', 'utf8'));
      if (config.environment !== 'development') process.exit(1);
    " 2>/dev/null; then
      pass_check "Development node-config.json is valid"
    else
      fail_check "Development node-config.json is invalid or wrong environment"
    fi
  else
    fail_check "Development node-config.json not found"
  fi

  increment_check
  if [ "${NODE_ENV:-}" = "development" ]; then
    pass_check "NODE_ENV=development"
  else
    fail_check "NODE_ENV is not set to development (current: ${NODE_ENV:-unset})"
  fi
}

check_build_tools() {
  log_step "Checking build tools..."

  increment_check
  if command -v git >/dev/null 2>&1; then
    local git_version
    git_version=$(git --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
    pass_check "git (${git_version:-unknown})"
  else
    fail_check "git not available"
  fi

  increment_check
  if command -v make >/dev/null 2>&1 && command -v g++ >/dev/null 2>&1; then
    pass_check "Build tools available (make, g++)"
  else
    fail_check "Build tools missing"
  fi

  increment_check
  if command -v python3 >/dev/null 2>&1; then
    local python_version
    python_version=$(python3 --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
    pass_check "python3 (${python_version:-unknown})"
  else
    fail_check "python3 not available"
  fi
}

check_npm_config() {
  log_step "Checking npm configuration..."

  increment_check
  if npm config list >/dev/null 2>&1; then
    pass_check "npm configuration accessible"
  else
    fail_check "npm configuration not accessible"
  fi

  increment_check
  local npm_cache
  npm_cache=$(npm config get cache 2>/dev/null || echo "")
  if [ -n "$npm_cache" ] && [ -d "$npm_cache" ] && [ -w "$npm_cache" ]; then
    pass_check "npm cache directory writable"
  else
    fail_check "npm cache directory not accessible"
  fi
}

perform_development_health_check() {
  log_info "Starting development environment health check..."

  run_base_health_check
  check_development_tools
  check_development_config
  check_build_tools
  check_npm_config

  log_info "Checks passed: $CHECKS_PASSED/$CHECKS_TOTAL"

  if [ "$EXIT_CODE" -eq 0 ] && [ "$BASE_HEALTH_PASSED" = true ]; then
    log_info "Overall status: HEALTHY (Development Ready)"
  else
    log_error "Overall status: UNHEALTHY ($((CHECKS_TOTAL - CHECKS_PASSED)) check(s) failed)"
  fi

  return "$EXIT_CODE"
}

perform_development_health_check
