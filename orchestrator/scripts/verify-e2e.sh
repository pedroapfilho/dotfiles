#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking E2E test patterns...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # playwright.config.ts exists
  if [[ -f "${REPO_PATH}/playwright.config.ts" ]]; then
    pass "$repo" "playwright.config.ts exists"
  else
    fail "$repo" "playwright.config.ts" "not found at repo root"
    continue
  fi

  # tests/e2e/ directory exists
  if [[ -d "${REPO_PATH}/tests/e2e" ]]; then
    pass "$repo" "tests/e2e/ directory exists"
  else
    fail "$repo" "tests/e2e/" "directory not found"
  fi

  # Fixture pattern (base.extend)
  if grep -rq "base.extend" "${REPO_PATH}/tests/e2e/" 2>/dev/null; then
    pass "$repo" "fixture pattern (base.extend)"
  else
    fail "$repo" "fixture pattern" "no base.extend found in tests/e2e/"
  fi

  # Page Object pattern (*.page.ts files)
  if find "${REPO_PATH}/tests/e2e" -name "*.page.ts" -print -quit 2>/dev/null | grep -q .; then
    pass "$repo" "page object pattern (*.page.ts)"
  else
    fail "$repo" "page object pattern" "no *.page.ts files found in tests/e2e/"
  fi

  # storageState configured
  if grep -q "storageState" "${REPO_PATH}/playwright.config.ts"; then
    pass "$repo" "storageState configured"
  else
    fail "$repo" "storageState" "not found in playwright.config.ts"
  fi

  # Global setup or teardown configured
  has_setup=false
  if grep -q "globalSetup\|globalTeardown" "${REPO_PATH}/playwright.config.ts"; then
    has_setup=true
  fi
  if [[ "$has_setup" == true ]]; then
    pass "$repo" "global setup/teardown configured"
  else
    fail "$repo" "global setup/teardown" "neither globalSetup nor globalTeardown found"
  fi

  # Auth setup file exists
  if [[ -f "${REPO_PATH}/tests/e2e/setup/auth.setup.ts" ]]; then
    pass "$repo" "auth setup file exists"
  else
    fail "$repo" "auth setup" "tests/e2e/setup/auth.setup.ts not found"
  fi
done

summary
