#!/usr/bin/env bats

bats_require_minimum_version 1.5.0
load "../helpers/common"

# =============================================================================
# Docker scripts — existence, permissions, and shebang validation
# =============================================================================

@test "entrypoint.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/entrypoint.sh"
}

@test "entrypoint.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/entrypoint.sh"
}

@test "entrypoint.sh has bash shebang" {
  run head -1 "${PROJECT_ROOT}/scripts/entrypoint.sh"
  [[ "$output" =~ ^#!/bin/bash ]]
}

@test "entrypoint.sh uses strict error handling" {
  run grep -q "set -euo pipefail" "${PROJECT_ROOT}/scripts/entrypoint.sh"
  [ "$status" -eq 0 ]
}

@test "healthcheck.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/healthcheck.sh"
}

@test "healthcheck.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/healthcheck.sh"
}

@test "healthcheck.sh has bash shebang" {
  run head -1 "${PROJECT_ROOT}/scripts/healthcheck.sh"
  [[ "$output" =~ ^#!/bin/bash ]]
}

@test "healthcheck.sh uses strict error handling" {
  run grep -q "set -euo pipefail" "${PROJECT_ROOT}/scripts/healthcheck.sh"
  [ "$status" -eq 0 ]
}

@test "dev-setup.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/dev-setup.sh"
}

@test "dev-setup.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/dev-setup.sh"
}

@test "dev-setup.sh uses strict error handling" {
  run grep -q "set -euo pipefail" "${PROJECT_ROOT}/scripts/dev-setup.sh"
  [ "$status" -eq 0 ]
}

@test "healthcheck-dev.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/healthcheck-dev.sh"
}

@test "healthcheck-dev.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/healthcheck-dev.sh"
}

@test "healthcheck-test.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/healthcheck-test.sh"
}

@test "healthcheck-test.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/healthcheck-test.sh"
}

@test "validate-config.sh exists" {
  assert_file_exists "${PROJECT_ROOT}/scripts/validate-config.sh"
}

@test "validate-config.sh is executable" {
  assert_executable "${PROJECT_ROOT}/scripts/validate-config.sh"
}
