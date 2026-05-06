#!/usr/bin/env bash
# Verify each repo wraps long-running dev scripts with the `openlogs` CLI so
# AI agents can read dev-server output via `openlogs tail` instead of asking
# the user to paste terminal output. See standards.md § Openlogs.
#
# Canonical shape: every root script whose name is `dev` or starts with `dev:`
# must begin with `openlogs `. Other scripts (`build`, `start`, `test`, ...)
# are not wrapped — openlogs is a dev-time tool only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking openlogs wrapper on dev scripts...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  PKG="${REPO_PATH}/package.json"

  if [[ ! -f "$PKG" ]]; then
    fail "$repo" "openlogs" "package.json missing"
    continue
  fi

  # All script names matching `dev` or `dev:*`. Use a while-read loop for
  # bash 3.2 compatibility (macOS default ships without `mapfile`).
  dev_scripts=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && dev_scripts+=("$line")
  done < <(jq -r '.scripts | keys[] | select(. == "dev" or startswith("dev:"))' "$PKG")

  if [[ "${#dev_scripts[@]}" -eq 0 ]]; then
    fail "$repo" "openlogs" "no dev script defined"
    continue
  fi

  unwrapped=()
  for script in "${dev_scripts[@]}"; do
    cmd="$(jq -r --arg s "$script" '.scripts[$s]' "$PKG")"
    if [[ "$cmd" != openlogs\ * && "$cmd" != ol\ * ]]; then
      if has_divergence "$repo" "openlogs" "${script}-unwrapped"; then
        skip "$repo" "$script" "$(divergence_reason "$repo" "openlogs" "${script}-unwrapped")"
      else
        unwrapped+=("$script")
      fi
    fi
  done

  if [[ "${#unwrapped[@]}" -eq 0 ]]; then
    pass "$repo" "all dev scripts wrap with openlogs (${dev_scripts[*]})"
  else
    fail "$repo" "unwrapped dev scripts" "${unwrapped[*]} — prefix with 'openlogs '"
  fi
done

summary
