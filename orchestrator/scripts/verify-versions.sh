#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking tooling versions against %s...${RESET}\n\n" "$SOURCE_OF_TRUTH"

ACME="$(repo_path "$SOURCE_OF_TRUTH")"

# Versions to check from root package.json
ACME_PKG_MANAGER=$(pkg_get "$ACME" '.packageManager')
ACME_NODE_ENGINE=$(pkg_get "$ACME" '.engines.node')

# devDependencies to compare
DEV_DEPS=("turbo" "oxlint" "oxfmt" "oxlint-config-awesomeness" "husky" "lint-staged" "@playwright/test" "fallow")

for repo in "${SCOPED_REPOS[@]}"; do
  [[ "$repo" == "$SOURCE_OF_TRUTH" ]] && continue
  REPO_PATH="$(repo_path "$repo")"

  # packageManager
  local_val=$(pkg_get "$REPO_PATH" '.packageManager')
  if [[ "$local_val" == "$ACME_PKG_MANAGER" ]]; then
    pass "$repo" "packageManager ($local_val)"
  else
    fail "$repo" "packageManager" "expected $ACME_PKG_MANAGER, got $local_val"
  fi

  # engines.node
  local_val=$(pkg_get "$REPO_PATH" '.engines.node')
  if [[ "$local_val" == "$ACME_NODE_ENGINE" ]]; then
    pass "$repo" "engines.node ($local_val)"
  else
    fail "$repo" "engines.node" "expected $ACME_NODE_ENGINE, got $local_val"
  fi

  # devDependencies
  for dep in "${DEV_DEPS[@]}"; do
    acme_ver=$(pkg_get "$ACME" ".devDependencies[\"$dep\"] // empty")
    [[ -z "$acme_ver" ]] && continue
    local_ver=$(pkg_get "$REPO_PATH" ".devDependencies[\"$dep\"] // empty")
    if [[ "$local_ver" == "$acme_ver" ]]; then
      pass "$repo" "$dep ($local_ver)"
    elif [[ -z "$local_ver" ]]; then
      fail "$repo" "$dep" "not found in devDependencies (acme has $acme_ver)"
    else
      fail "$repo" "$dep" "expected $acme_ver, got $local_ver"
    fi
  done
done

summary
