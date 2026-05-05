#!/usr/bin/env bash
# Verify each repo's @repo/auth/server.ts gates `requireEmailVerification`
# on email-infra availability — not bare `true`.
#
# Why: a bare `true` locks dev/CI users out (no Resend → no verification email →
# user can't log in). Frow regressed this in 2026-04 and only surfaced via
# dogfood. The canonical patterns are:
#   - `requireEmailVerification: Boolean(resend)` (acme/collabtime/localcine)
#   - `requireEmailVerification: !skipExternalServices` (frow)
# Both are functions of "does this environment have working email infra?"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking requireEmailVerification gates on email-infra availability...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  AUTH_FILE="${REPO_PATH}/packages/auth/src/server.ts"

  if [[ ! -f "$AUTH_FILE" ]]; then
    skip "$repo" "auth-config" "packages/auth/src/server.ts missing"
    continue
  fi

  # Find the requireEmailVerification line value
  value=$(grep -E "^\s*requireEmailVerification:" "$AUTH_FILE" | head -1 | sed -E 's/^\s*requireEmailVerification:\s*//; s/,$//' | tr -d ' ')

  if [[ -z "$value" ]]; then
    fail "$repo" "auth-config" "requireEmailVerification not set in packages/auth/src/server.ts"
    continue
  fi

  case "$value" in
    "true")
      fail "$repo" "auth-config" "requireEmailVerification: true (bare literal — should gate on email-infra availability, e.g. Boolean(resend) or !skipExternalServices)"
      ;;
    "false")
      fail "$repo" "auth-config" "requireEmailVerification: false (bare literal — should gate on email-infra availability)"
      ;;
    "Boolean(resend)"|"Boolean(resendApiKey)"|"!skipExternalServices"|"!config.skipExternalServices")
      pass "$repo" "auth-config: requireEmailVerification gates on email-infra ($value)"
      ;;
    *)
      # Allow other expressions but warn — anything that's not a literal is probably fine
      pass "$repo" "auth-config: requireEmailVerification: $value (not a bare literal)"
      ;;
  esac
done

summary
