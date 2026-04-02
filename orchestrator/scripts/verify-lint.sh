#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking lint and format configuration...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # .oxlintrc.json exists
  if [[ -f "${REPO_PATH}/.oxlintrc.json" ]]; then
    pass "$repo" ".oxlintrc.json exists"
  else
    fail "$repo" ".oxlintrc.json" "file not found"
  fi

  # .oxfmtrc.json exists
  if [[ -f "${REPO_PATH}/.oxfmtrc.json" ]]; then
    pass "$repo" ".oxfmtrc.json exists"
  else
    fail "$repo" ".oxfmtrc.json" "file not found"
  fi

  # No legacy eslint configs
  for legacy in ".eslintrc" ".eslintrc.js" ".eslintrc.json" "eslint.config.js" "eslint.config.mjs"; do
    if [[ -f "${REPO_PATH}/${legacy}" ]]; then
      fail "$repo" "legacy config" "${legacy} should not exist"
    fi
  done

  # No legacy prettier configs
  for legacy in ".prettierrc" ".prettierrc.js" ".prettierrc.json" "prettier.config.js"; do
    if [[ -f "${REPO_PATH}/${legacy}" ]]; then
      fail "$repo" "legacy config" "${legacy} should not exist"
    fi
  done

  # oxlint-config-awesomeness in devDependencies
  if pkg_get "$REPO_PATH" '.devDependencies["oxlint-config-awesomeness"] // empty' | grep -q .; then
    pass "$repo" "oxlint-config-awesomeness in devDependencies"
  else
    fail "$repo" "oxlint-config-awesomeness" "not found in devDependencies"
  fi

  # lint-staged config matches pattern
  lint_staged_ts=$(pkg_get "$REPO_PATH" '.["lint-staged"]["*.{ts,tsx,js,jsx}"][0] // empty')
  lint_staged_fmt=$(pkg_get "$REPO_PATH" '.["lint-staged"]["*.{ts,tsx,js,jsx,json,md}"][0] // empty')

  if [[ "$lint_staged_ts" == "oxlint" ]]; then
    pass "$repo" "lint-staged runs oxlint on TS/JS"
  else
    fail "$repo" "lint-staged oxlint" "expected 'oxlint', got '$lint_staged_ts'"
  fi

  if [[ "$lint_staged_fmt" == "oxfmt" ]]; then
    pass "$repo" "lint-staged runs oxfmt on TS/JS/JSON/MD"
  else
    fail "$repo" "lint-staged oxfmt" "expected 'oxfmt', got '$lint_staged_fmt'"
  fi

  # Check sort rules (with divergence support for frow)
  if [[ -f "${REPO_PATH}/.oxlintrc.json" ]]; then
    sort_rules=("perfectionist/sort-interfaces" "perfectionist/sort-jsx-props" "perfectionist/sort-object-types" "perfectionist/sort-objects")
    for rule in "${sort_rules[@]}"; do
      rule_value=$(json_get "${REPO_PATH}/.oxlintrc.json" ".rules[\"$rule\"] // \"not-set\"")
      if [[ "$rule_value" == "off" || "$rule_value" == "not-set" ]]; then
        if has_divergence "$repo" "lint" "sort-rules-off"; then
          skip "$repo" "$rule" "sort-rules-off"
        else
          fail "$repo" "$rule" "expected 'error', got '$rule_value'"
        fi
      else
        pass "$repo" "$rule enabled"
      fi
    done
  fi
done

summary
