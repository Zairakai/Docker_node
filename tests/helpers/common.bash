#!/usr/bin/env bash
#
# Common BATS test helpers
# Source this file in BATS tests: load '../helpers/common'
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

export PROJECT_ROOT

# Setup hook - runs before each test
setup() {
    # Source project config if exists
    if [ -f "tools/config.sh" ]; then
        # shellcheck source=/dev/null
        source tools/config.sh
    fi

    # Define test directories
    export TEST_TEMP_DIR="${BATS_TEST_TMPDIR:-/tmp}/bats-$$"
    mkdir -p "${TEST_TEMP_DIR}"
}

# Teardown hook - runs after each test
teardown() {
    # Cleanup temp directory
    if [ -n "${TEST_TEMP_DIR}" ] && [ -d "${TEST_TEMP_DIR}" ]; then
        rm -rf "${TEST_TEMP_DIR}"
    fi
}

# Safe script sourcing helper
source_script() {
  local script_path="${1}"

  if [[ ! -f "$script_path" ]]; then
    echo "ERROR: Script not found: $script_path" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "$script_path"
}

# Assert helpers
assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "Expected success but got failure (exit code: $status)"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Expected failure but got success"
        echo "Output: $output"
        return 1
    fi
}

assert_output() {
    local expected="$1"
    if [ "$output" != "$expected" ]; then
        echo "Expected output: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    if ! echo "$output" | grep -q "$expected"; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_output_not_contains() {
    local unexpected="$1"
    if echo "$output" | grep -q "$unexpected"; then
        echo "Expected output to NOT contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Expected file to exist: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Expected file to NOT exist: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Expected directory to exist: $dir"
        return 1
    fi
}

assert_executable() {
    local file="$1"
    if [ ! -x "$file" ]; then
        echo "Expected file to be executable: $file"
        return 1
    fi
}

# File operations
create_temp_file() {
    local filename="${1:-testfile}"
    local content="${2:-}"
    local filepath="${TEST_TEMP_DIR}/${filename}"

    echo "$content" > "$filepath"
    echo "$filepath"
}

create_temp_script() {
    local filename="${1:-script.sh}"
    local content="${2:-#!/usr/bin/env bash\necho 'test'}"
    local filepath="${TEST_TEMP_DIR}/${filename}"

    echo -e "$content" > "$filepath"
    chmod +x "$filepath"
    echo "$filepath"
}

# Skip helpers
skip_if_not_executable() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        skip "$cmd not installed"
    fi
}

skip_if_no_docker() {
    if ! command -v docker &>/dev/null; then
        skip "Docker not installed"
    fi
}

skip_if_no_node() {
    if ! command -v node &>/dev/null; then
        skip "node not installed"
    fi
}

skip_if_no_php() {
    if ! command -v php &>/dev/null; then
        skip "php not installed"
    fi
}

skip_if_no_git() {
    if ! command -v git &>/dev/null; then
        skip "Git not installed"
    fi
}

# Docker helpers
docker_image_exists() {
    local image="$1"
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"
}

docker_container_running() {
    local container="$1"
    docker ps --format "{{.Names}}" | grep -q "^${container}$"
}

# Git helpers
git_branch_exists() {
    local branch="$1"
    git rev-parse --verify "$branch" &>/dev/null
}

git_is_clean() {
    [ -z "$(git status --porcelain)" ]
}

# Color output helpers
color_red() {
    echo -e "\033[31m$*\033[0m"
}

color_green() {
    echo -e "\033[32m$*\033[0m"
}

color_yellow() {
    echo -e "\033[33m$*\033[0m"
}

color_blue() {
    echo -e "\033[34m$*\033[0m"
}
