#!/usr/bin/env bats

bats_require_minimum_version 1.5.0
load "../helpers/common"

# =============================================================================
# freshness-check.sh - helpers of the scheduled freshness check
# =============================================================================

# Called first in every test: the node helper already defines setup
use_script() {
  # The php helper does not define PROJECT_ROOT, so derive it from the test file
  PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)}"
  SCRIPT="${PROJECT_ROOT}/scripts/freshness-check.sh"
  # shellcheck source=/dev/null
  source "${SCRIPT}"
}

@test "freshness-check.sh exists and is executable" {
  use_script
  [[ -f "${SCRIPT}" ]]
  [[ -x "${SCRIPT}" ]]
}

@test "freshness-check.sh uses env shebang and strict mode" {
  use_script
  run head -1 "${SCRIPT}"
  [[ "$output" == "#!/usr/bin/env bash" ]]
  run grep -q "set -euo pipefail" "${SCRIPT}"
  [[ "$status" -eq 0 ]]
}

@test "version_gt compares patch numbers numerically" {
  use_script
  version_gt 8.4.27 8.4.9
  ! version_gt 8.4.9 8.4.27
  ! version_gt 8.4.27 8.4.27
}

@test "next_patch increments the last number" {
  use_script
  [[ "$(next_patch 2.3.0)" == "2.3.1" ]]
  [[ "$(next_patch 1.3.9)" == "1.3.10" ]]
}

@test "age_days counts whole days from an ISO date" {
  use_script
  now=$(date -u -d "2026-10-23T12:00:00Z" +%s)
  [[ "$(age_days "2026-10-20T11:00:00.123456789Z" "${now}")" == "3" ]]
  [[ "$(age_days "2026-10-22T13:00:00Z" "${now}")" == "0" ]]
}

@test "latest_release_tag keeps only x.y.z tags" {
  use_script
  run bash -c "source '${SCRIPT}'; printf '%s\n' v2.2.0 2.2.1 2.3.0 2.10.0 2.3.0-dev latest | latest_release_tag"
  [[ "$output" == "2.10.0" ]]
}

@test "fixable_count counts CRITICAL and HIGH findings with a fix" {
  use_script
  report="${BATS_TEST_TMPDIR}/trivy.json"
  cat > "${report}" <<'JSON'
{"Results":[{"Vulnerabilities":[
  {"Severity":"CRITICAL","FixedVersion":"1.2.3"},
  {"Severity":"CRITICAL"},
  {"Severity":"HIGH","FixedVersion":"2.0"},
  {"Severity":"MEDIUM","FixedVersion":"3.0"}
]},{}]}
JSON
  [[ "$(fixable_count "${report}")" == "2" ]]
}

@test "fixable_count is 0 for a report without findings" {
  use_script
  report="${BATS_TEST_TMPDIR}/empty.json"
  echo '{"Results":[]}' > "${report}"
  [[ "$(fixable_count "${report}")" == "0" ]]
}

@test "upstream_from_dockerfile reads the base image of the Dockerfile" {
  use_script
  [[ "$(upstream_from_dockerfile "${PROJECT_ROOT}/Dockerfile")" == "node:24-alpine" ]]
}

@test "upstream_from_dockerfile resolves an ARG default" {
  use_script
  dockerfile="${BATS_TEST_TMPDIR}/Dockerfile"
  printf 'ARG NODE_VERSION=24\nFROM node:${NODE_VERSION}-alpine AS base\n' > "${dockerfile}"
  [[ "$(upstream_from_dockerfile "${dockerfile}")" == "node:24-alpine" ]]
}
