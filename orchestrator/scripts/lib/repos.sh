#!/usr/bin/env bash
# Shared repo definitions and helper functions for verification scripts
# Compatible with bash 3.2+ (macOS default)

REPOS_DIR="${HOME}/dev"

REPO_NAMES=("acme" "localcine" "collabtime" "frow" "easeia")
SOURCE_OF_TRUTH="acme"

# --- Sibling-worktree resolution ----------------------------------------------
#
# When orchestrator runs from a non-canonical worktree (e.g. Conductor spawns
# `~/conductor/orchestrator-feat-x/`), look for matching managed-repo worktrees
# next to it (`~/conductor/<repo>-monorepo-feat-x/`). If found, those win over
# the canonical `~/dev/<repo>-monorepo/`.
#
# Detection: this file is sourced as `<orch>/scripts/lib/repos.sh`. We walk two
# `..` from `BASH_SOURCE[0]` to land at `<orch>` and confirm by checking that
# `AGENTS.md` is present — otherwise we're being sourced from dotfiles or some
# other location and should stay canonical-only.
#
# Suffix derivation: orchestrator basename `orchestrator-<x>` yields suffix
# `-<x>`. Bare `orchestrator` yields empty suffix (canonical behavior).

_REPOS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ORCH_ROOT="$(cd "${_REPOS_LIB_DIR}/../.." 2>/dev/null && pwd)"
if [[ ! -f "${_ORCH_ROOT}/AGENTS.md" ]]; then
  _ORCH_ROOT=""
fi

_ORCH_PARENT=""
_ORCH_SUFFIX=""
if [[ -n "$_ORCH_ROOT" ]]; then
  _ORCH_PARENT="$(dirname "$_ORCH_ROOT")"
  _ORCH_BASENAME="$(basename "$_ORCH_ROOT")"
  case "$_ORCH_BASENAME" in
    orchestrator)   _ORCH_SUFFIX="" ;;
    orchestrator-*) _ORCH_SUFFIX="${_ORCH_BASENAME#orchestrator}" ;; # e.g. "-feat-x"
    *)              _ORCH_SUFFIX="" ;;
  esac
fi

# Resolve a managed-repo path: prefer sibling worktree if orchestrator is in
# a non-canonical location and a matching `<repo>-monorepo<suffix>` exists.
# Fallback: canonical `~/dev/<repo>-monorepo`.
repo_path() {
  local name="$1" repo_dir
  case "$name" in
    acme)       repo_dir="acme-monorepo" ;;
    localcine)  repo_dir="localcine-monorepo" ;;
    collabtime) repo_dir="collabtime-monorepo" ;;
    frow)       repo_dir="frow-monorepo" ;;
    easeia)     repo_dir="easeia-monorepo" ;;
    *) return 1 ;;
  esac

  if [[ -n "$_ORCH_SUFFIX" ]]; then
    local candidate="${_ORCH_PARENT}/${repo_dir}${_ORCH_SUFFIX}"
    if [[ -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  echo "${REPOS_DIR}/${repo_dir}"
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
