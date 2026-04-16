#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking dev environment...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Check portless in dev scripts (app-level package.json)
  for app_dir in "${REPO_PATH}"/apps/*/; do
    [[ ! -d "$app_dir" ]] && continue
    app_name=$(basename "$app_dir")
    app_pkg="${app_dir}package.json"
    [[ ! -f "$app_pkg" ]] && continue

    dev_script=$(jq -r '.scripts.dev // empty' "$app_pkg")
    if [[ -n "$dev_script" ]] && echo "$dev_script" | grep -q "portless"; then
      pass "$repo" "apps/${app_name} dev uses portless"
    elif [[ -n "$dev_script" ]]; then
      fail "$repo" "apps/${app_name} dev" "missing portless — got: $dev_script"
    fi
  done

  # Check allowedDevOrigins in next.config
  for app_dir in "${REPO_PATH}"/apps/*/; do
    [[ ! -d "$app_dir" ]] && continue
    app_name=$(basename "$app_dir")
    next_config=""
    for ext in "ts" "mjs" "js"; do
      if [[ -f "${app_dir}next.config.${ext}" ]]; then
        next_config="${app_dir}next.config.${ext}"
        break
      fi
    done
    [[ -z "$next_config" ]] && continue

    expected_main="${repo}.${app_name}.localhost"
    expected_wildcard="*.${repo}.${app_name}.localhost"
    has_main=false
    has_wildcard=false
    grep -qF "\"${expected_main}\"" "$next_config" && has_main=true
    grep -qF "\"${expected_wildcard}\"" "$next_config" && has_wildcard=true

    if [[ "$has_main" == "true" && "$has_wildcard" == "true" ]]; then
      pass "$repo" "apps/${app_name} allowedDevOrigins (main + worktree wildcard)"
    elif [[ "$has_main" == "true" ]]; then
      fail "$repo" "apps/${app_name} allowedDevOrigins" "missing worktree wildcard \"${expected_wildcard}\""
    elif grep -q "allowedDevOrigins" "$next_config"; then
      fail "$repo" "apps/${app_name} allowedDevOrigins" "set but missing \"${expected_main}\" + \"${expected_wildcard}\""
    else
      fail "$repo" "apps/${app_name} allowedDevOrigins" "not found in $(basename "$next_config")"
    fi
  done

  # Check Husky pre-commit exists
  if [[ -f "${REPO_PATH}/.husky/pre-commit" ]]; then
    if grep -q "lint-staged" "${REPO_PATH}/.husky/pre-commit"; then
      pass "$repo" "husky pre-commit runs lint-staged"
    else
      fail "$repo" "husky pre-commit" "does not run lint-staged"
    fi
  else
    fail "$repo" "husky pre-commit" ".husky/pre-commit not found"
  fi
done

summary
