#!/usr/bin/env bash
# Verify each repo has the Resend-driven E2E auth/email flow tests wired:
#   - tests/e2e/auth-email/{sign-up-verification,password-reset,
#     existing-user-signup,change-email}.spec.ts
#   - tests/e2e/fixtures/verification.fixture.ts
#   - tests/e2e/helpers/test-email.ts
#   - packages/auth/src/server.ts contains `user.changeEmail` with `enabled: true`
#   - CI workflow sets RESEND_API_KEY from a secret in the e2e job
#     (skipped for repos without .github/workflows/, e.g. acme)
#
# See standards.md § Email Flow Tests (auth-email/).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking E2E auth/email flow tests...${RESET}\n\n"

REQUIRED_SPECS=(
  "tests/e2e/auth-email/sign-up-verification.spec.ts"
  "tests/e2e/auth-email/password-reset.spec.ts"
  "tests/e2e/auth-email/existing-user-signup.spec.ts"
  "tests/e2e/auth-email/change-email.spec.ts"
)

REQUIRED_SUPPORT_FILES=(
  "tests/e2e/fixtures/verification.fixture.ts"
  "tests/e2e/helpers/test-email.ts"
)

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Required spec files
  missing_specs=""
  for spec in "${REQUIRED_SPECS[@]}"; do
    if [[ ! -f "${REPO_PATH}/${spec}" ]]; then
      missing_specs+="${spec}; "
    fi
  done
  if [[ -n "$missing_specs" ]]; then
    fail "$repo" "auth-email specs" "missing: ${missing_specs%; }"
  else
    pass "$repo" "auth-email specs present (4/4)"
  fi

  # Required support files (fixture + helper)
  missing_support=""
  for support in "${REQUIRED_SUPPORT_FILES[@]}"; do
    if [[ ! -f "${REPO_PATH}/${support}" ]]; then
      missing_support+="${support}; "
    fi
  done
  if [[ -n "$missing_support" ]]; then
    fail "$repo" "auth-email support" "missing: ${missing_support%; }"
  else
    pass "$repo" "auth-email support files present"
  fi

  # Auth config: user.changeEmail enabled
  AUTH_FILE="${REPO_PATH}/packages/auth/src/server.ts"
  if [[ ! -f "$AUTH_FILE" ]]; then
    skip "$repo" "auth-config-change-email" "packages/auth/src/server.ts missing"
  else
    # Tolerant pattern: matches `changeEmail: {` followed eventually by
    # `enabled: true` on a nearby line (within the same block).
    if grep -Pzo '(?s)changeEmail\s*:\s*\{[^}]*enabled\s*:\s*true' "$AUTH_FILE" >/dev/null 2>&1; then
      pass "$repo" "user.changeEmail enabled in auth config"
    else
      fail "$repo" "user.changeEmail" "not enabled in packages/auth/src/server.ts (expect changeEmail: { enabled: true, ... })"
    fi

    # sendChangeEmailConfirmation hook wired
    if grep -q "sendChangeEmailConfirmation" "$AUTH_FILE"; then
      pass "$repo" "sendChangeEmailConfirmation wired"
    else
      fail "$repo" "sendChangeEmailConfirmation" "hook not wired in auth config"
    fi
  fi

  # CI workflow exports RESEND_API_KEY (skip if repo has no GH Actions —
  # acme opted out; verify-ci.sh has the same skip).
  WORKFLOWS_DIR="${REPO_PATH}/.github/workflows"
  if [[ ! -d "$WORKFLOWS_DIR" ]]; then
    skip "$repo" "ci-resend-key" "no .github/workflows/ — repo opted out of GH Actions"
  else
    if grep -rqE "RESEND_API_KEY\s*:\s*\\\${{\s*secrets\." "$WORKFLOWS_DIR" 2>/dev/null; then
      pass "$repo" "CI workflow exports RESEND_API_KEY from secrets"
    else
      fail "$repo" "ci-resend-key" "no workflow exports RESEND_API_KEY from secrets"
    fi
  fi
done

summary
