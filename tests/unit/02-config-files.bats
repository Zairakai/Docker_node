#!/usr/bin/env bats

bats_require_minimum_version 1.5.0
load "../helpers/common"

# =============================================================================
# Configuration files — existence and content validation
# =============================================================================

@test "config/prod/ directory exists" {
  assert_dir_exists "${PROJECT_ROOT}/config/prod"
}

@test "config/dev/ directory exists" {
  assert_dir_exists "${PROJECT_ROOT}/config/dev"
}

@test "config/test/ directory exists" {
  assert_dir_exists "${PROJECT_ROOT}/config/test"
}

@test "config/prod/npm.conf exists" {
  assert_file_exists "${PROJECT_ROOT}/config/prod/npm.conf"
}

@test "config/prod/npm.conf has strict-ssl enabled" {
  run grep -q "strict-ssl=true" "${PROJECT_ROOT}/config/prod/npm.conf"
  [ "$status" -eq 0 ]
}

@test "config/prod/npm.conf has production mode" {
  run grep -q "production=true" "${PROJECT_ROOT}/config/prod/npm.conf"
  [ "$status" -eq 0 ]
}

@test "config/prod/node.prod.json exists" {
  assert_file_exists "${PROJECT_ROOT}/config/prod/node.prod.json"
}

@test "config/prod/node.prod.json is valid JSON" {
  skip_if_no_node
  run node -e "JSON.parse(require('fs').readFileSync('${PROJECT_ROOT}/config/prod/node.prod.json', 'utf8'))"
  [ "$status" -eq 0 ]
}

@test "config/prod/node.prod.json has production environment" {
  run grep -q '"environment": "production"' "${PROJECT_ROOT}/config/prod/node.prod.json"
  [ "$status" -eq 0 ]
}

@test "config/dev/node.dev.json exists" {
  assert_file_exists "${PROJECT_ROOT}/config/dev/node.dev.json"
}

@test "config/dev/node.dev.json is valid JSON" {
  skip_if_no_node
  run node -e "JSON.parse(require('fs').readFileSync('${PROJECT_ROOT}/config/dev/node.dev.json', 'utf8'))"
  [ "$status" -eq 0 ]
}

@test "config/dev/node.dev.json has development environment" {
  run grep -q '"environment": "development"' "${PROJECT_ROOT}/config/dev/node.dev.json"
  [ "$status" -eq 0 ]
}

@test "config/test/node.test.json exists" {
  assert_file_exists "${PROJECT_ROOT}/config/test/node.test.json"
}

@test "config/test/node.test.json is valid JSON" {
  skip_if_no_node
  run node -e "JSON.parse(require('fs').readFileSync('${PROJECT_ROOT}/config/test/node.test.json', 'utf8'))"
  [ "$status" -eq 0 ]
}

@test "config/test/node.test.json has test environment" {
  run grep -q '"environment": "test"' "${PROJECT_ROOT}/config/test/node.test.json"
  [ "$status" -eq 0 ]
}

@test "Dockerfile exists" {
  assert_file_exists "${PROJECT_ROOT}/Dockerfile"
}

@test "Dockerfile defines base stage" {
  run grep -q "AS base" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Dockerfile defines prod stage" {
  run grep -q "AS prod" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Dockerfile defines dev stage" {
  run grep -q "AS dev" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Dockerfile defines test stage" {
  run grep -q "AS test" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Dockerfile uses Node 22" {
  run grep -q "NODE_VERSION=22" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Dockerfile uses flat config/prod/ COPY paths" {
  run grep -q "COPY.*config/prod/" "${PROJECT_ROOT}/Dockerfile"
  [ "$status" -eq 0 ]
}
