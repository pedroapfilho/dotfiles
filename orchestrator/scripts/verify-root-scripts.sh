#!/usr/bin/env bash
# Verify each repo's root package.json defines the canonical script names from
# standards.md § Root Scripts. Extras are allowed; missing canonical scripts
# fail unless covered by a `root-scripts` divergence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

CANONICAL_SCRIPTS=(
  "start"
  "dev"
  "lint"
  "format"
  "format:check"
  "typecheck"
  "build"
  "clean"
  "test"
  "test:e2e"
  "test:e2e:ui"
  "db:generate"
  "db:push"
  "db:seed"
  "prepare"
)

printf "${BOLD}Checking canonical root scripts...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  PKG="${REPO_PATH}/package.json"

  if [[ ! -f "$PKG" ]]; then
    fail "$repo" "root-scripts" "package.json missing"
    continue
  fi

  missing=()
  for script in "${CANONICAL_SCRIPTS[@]}"; do
    if ! jq -e --arg s "$script" '.scripts | has($s)' "$PKG" >/dev/null 2>&1; then
      if has_divergence "$repo" "root-scripts" "${script}-missing"; then
        skip "$repo" "$script" "$(divergence_reason "$repo" "root-scripts" "${script}-missing")"
      else
        missing+=("$script")
      fi
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    pass "$repo" "all canonical scripts present"
  else
    fail "$repo" "missing scripts" "${missing[*]}"
  fi
done

summary
