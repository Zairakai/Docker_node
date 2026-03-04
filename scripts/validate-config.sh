#!/usr/bin/env bash
set -euo pipefail

# ================================
# Configuration Validation Script
# ================================

echo "━━━━━━━━━━━━━━━━"
echo "🔧 Configuration Files Validation"
echo "━━━━━━━━━━━━━━━━"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERROR_COUNT=0

validate_file() {
  local file="$1"
  local description="$2"

  if [[ ! -f "$file" ]]; then
    echo "  ❌ File not found: $file"
    ((ERROR_COUNT++))
    return 1
  fi

  if [[ "$file" == *.json ]]; then
    if node -e "JSON.parse(require('fs').readFileSync('${file}', 'utf8'))" 2>/dev/null; then
      echo "  - ✅ $description"
    else
      echo "  - ❌ Invalid JSON: $description"
      ((ERROR_COUNT++))
      return 1
    fi
  else
    echo "  - ✅ $description"
  fi
}

check_setting() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if grep -q "$pattern" "$file"; then
    echo "  - ✅ $description"
  else
    echo "  - ❌ Missing: $description"
    ((ERROR_COUNT++))
  fi
}

# Production configuration
echo ""
echo "Production Configuration:"
validate_file "$PROJECT_ROOT/config/prod/npm.conf" "npm.conf"
validate_file "$PROJECT_ROOT/config/prod/node.prod.json" "node.prod.json"

echo ""
echo "Production Security Settings:"
check_setting "$PROJECT_ROOT/config/prod/npm.conf" "strict-ssl=true" "Strict SSL enabled"
check_setting "$PROJECT_ROOT/config/prod/npm.conf" "production=true" "Production mode set"
check_setting "$PROJECT_ROOT/config/prod/npm.conf" "audit-level=moderate" "Audit level configured"

# Development configuration
echo ""
echo "Development Configuration:"
validate_file "$PROJECT_ROOT/config/dev/node.dev.json" "node.dev.json"

echo ""
echo "Development Settings:"
check_setting "$PROJECT_ROOT/config/dev/node.dev.json" '"environment": "development"' "Development environment"

# Test configuration
echo ""
echo "Test Configuration:"
validate_file "$PROJECT_ROOT/config/test/node.test.json" "node.test.json"

echo ""
echo "Test Settings:"
check_setting "$PROJECT_ROOT/config/test/node.test.json" '"environment": "test"' "Test environment"

# Scripts
echo ""
echo "Scripts:"
for script in \
    "$PROJECT_ROOT/scripts/entrypoint.sh" \
    "$PROJECT_ROOT/scripts/healthcheck.sh" \
    "$PROJECT_ROOT/scripts/dev-setup.sh" \
    "$PROJECT_ROOT/scripts/healthcheck-dev.sh" \
    "$PROJECT_ROOT/scripts/healthcheck-test.sh"; do
  if [[ -f "$script" ]] && [[ -x "$script" ]]; then
    echo "  - ✅ $(basename "$script") (executable)"
  elif [[ -f "$script" ]]; then
    echo "  - ❌ $(basename "$script") (not executable)"
    ((ERROR_COUNT++))
  else
    echo "  - ❌ $(basename "$script") (missing)"
    ((ERROR_COUNT++))
  fi
done

echo ""
if [[ "$ERROR_COUNT" -eq 0 ]]; then
  echo "🎉 All configuration files passed validation"
  echo "━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "❌ Validation failed with $ERROR_COUNT error(s)"
  echo "━━━━━━━━━━━━━━━━"
  exit 1
fi
