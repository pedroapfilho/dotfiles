#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking lint and format configuration...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # oxlint.config.ts exists (replaced .oxlintrc.json with the JS-API format that consumes the shared package)
  if [[ -f "${REPO_PATH}/oxlint.config.ts" ]]; then
    pass "$repo" "oxlint.config.ts exists"
  else
    fail "$repo" "oxlint.config.ts" "file not found"
  fi

  # oxlint.config.ts must extend the shared awesomeness config
  if [[ -f "${REPO_PATH}/oxlint.config.ts" ]] && grep -q "oxlint-config-awesomeness" "${REPO_PATH}/oxlint.config.ts"; then
    pass "$repo" "oxlint.config.ts extends oxlint-config-awesomeness"
  else
    fail "$repo" "oxlint.config.ts extends" "no reference to oxlint-config-awesomeness"
  fi

  # .oxfmtrc.json exists
  if [[ -f "${REPO_PATH}/.oxfmtrc.json" ]]; then
    pass "$repo" ".oxfmtrc.json exists"
  else
    fail "$repo" ".oxfmtrc.json" "file not found"
  fi

  # No legacy oxlint JSON config (superseded by oxlint.config.ts)
  if [[ -f "${REPO_PATH}/.oxlintrc.json" ]]; then
    fail "$repo" "legacy config" ".oxlintrc.json should not exist (use oxlint.config.ts)"
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

  # lint-staged config matches pattern (glob excludes .d.ts since oxlint has nothing to check on type-only declarations)
  lint_staged_ts=$(pkg_get "$REPO_PATH" '.["lint-staged"]["!(*.d).{ts,tsx,js,jsx}"][0] // empty')
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

  # Sort rules now live in the shared package (oxlint-config-awesomeness/index.js).
  # Per-consumer overrides may legitimately disable them in design-system dirs
  # (e.g. packages/ui), so we no longer enforce per-repo enablement here.
done

summary
