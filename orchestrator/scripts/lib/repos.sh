#!/usr/bin/env bash
# Shared repo definitions and helper functions for verification scripts
# Compatible with bash 3.2+ (macOS default)

REPOS_DIR="${HOME}/dev"

REPO_NAMES=("acme" "localcine" "collabtime" "frow")
SOURCE_OF_TRUTH="acme"

# Lookup repo path by name (bash 3.2 compatible — no associative arrays)
repo_path() {
  local name="$1"
  case "$name" in
    acme)      echo "${REPOS_DIR}/acme-monorepo" ;;
    localcine) echo "${REPOS_DIR}/localcine-monorepo" ;;
    collabtime) echo "${REPOS_DIR}/collabtime-monorepo" ;;
    frow)      echo "${REPOS_DIR}/frow-monorepo" ;;
    *) return 1 ;;
  esac
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Counters
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() {
  local repo="$1" check="$2"
  printf "${GREEN}PASS${RESET} %s: %s\n" "$repo" "$check"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  local repo="$1" check="$2" detail="${3:-}"
  printf "${RED}FAIL${RESET} %s: %s" "$repo" "$check"
  [[ -n "$detail" ]] && printf " — %s" "$detail"
  printf "\n"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  local repo="$1" check="$2" reason="$3"
  printf "${YELLOW}SKIP${RESET} %s: %s (%s)\n" "$repo" "$check" "$reason"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

summary() {
  printf "\n${BOLD}Summary:${RESET} ${GREEN}%d passed${RESET}, ${RED}%d failed${RESET}, ${YELLOW}%d skipped${RESET}\n" \
    "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
  [[ "$FAIL_COUNT" -eq 0 ]]
}

# Parse --repo flag to scope to a single repo
parse_repo_flag() {
  SCOPED_REPOS=("${REPO_NAMES[@]}")
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        if repo_path "$2" >/dev/null 2>&1; then
          SCOPED_REPOS=("$2")
        else
          printf "${RED}Unknown repo: %s${RESET}\n" "$2"
          exit 1
        fi
        shift 2
        ;;
      *) shift ;;
    esac
  done
}

# Get a JSON value from package.json using jq
pkg_get() {
  local repo_path="$1" query="$2"
  jq -r "$query" "${repo_path}/package.json" 2>/dev/null
}

# Get a JSON value from any JSON file using jq
json_get() {
  local file="$1" query="$2"
  jq -r "$query" "$file" 2>/dev/null
}
