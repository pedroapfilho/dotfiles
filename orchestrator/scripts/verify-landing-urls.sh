#!/usr/bin/env bash
# Verify landing apps use a `lib/urls.ts` helper for cross-origin web links.
#
# Why: hardcoded production URLs (e.g., `https://app.acme.com/login`) on the
# landing site break in dev — clicking "Sign in" jumps to production instead of
# the local dev web app. Both acme and frow hit this exact bug in dogfood. The
# fix pattern is `apps/landing/src/lib/urls.ts` exporting `webAppUrl(path)` that
# reads `NEXT_PUBLIC_WEB_APP_URL` and falls back to a portless dev URL.
#
# This verifier only fires for repos with an `apps/landing/` directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking landing apps for cross-origin webAppUrl helper...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  LANDING_DIR="${REPO_PATH}/apps/landing"

  if [[ ! -d "$LANDING_DIR" ]]; then
    skip "$repo" "landing-urls" "no apps/landing/ — pattern doesn't apply"
    continue
  fi

  URLS_FILE="${LANDING_DIR}/src/lib/urls.ts"

  if [[ ! -f "$URLS_FILE" ]]; then
    fail "$repo" "landing-urls" "apps/landing/src/lib/urls.ts missing"
    continue
  fi

  # Verify the file exports webAppUrl
  if ! grep -qE "(export\s+(const|function)\s+webAppUrl|webAppUrl\s*[,}])" "$URLS_FILE"; then
    fail "$repo" "landing-urls" "lib/urls.ts exists but does not export webAppUrl"
    continue
  fi

  # Verify it reads NEXT_PUBLIC_WEB_APP_URL (the canonical env var)
  if ! grep -q "NEXT_PUBLIC_WEB_APP_URL" "$URLS_FILE"; then
    fail "$repo" "landing-urls" "lib/urls.ts does not read process.env.NEXT_PUBLIC_WEB_APP_URL"
    continue
  fi

  # Scan for hardcoded production URLs in landing source (sign-in/register/login paths)
  hardcoded=$(grep -rEn "https://(app|www)\.[a-z]+\.(so|com|io|co|app|net|tools|me)/(login|register|sign-?up|sign-?in|recover|reset-password)" \
    "${LANDING_DIR}/src" 2>/dev/null | grep -v "/lib/urls.ts" || true)

  if [[ -n "$hardcoded" ]]; then
    count=$(printf '%s\n' "$hardcoded" | wc -l | tr -d ' ')
    example=$(printf '%s\n' "$hardcoded" | head -1)
    fail "$repo" "landing-urls" "$count hardcoded prod URL(s) in landing src — should use webAppUrl(): e.g. $example"
    continue
  fi

  pass "$repo" "landing-urls: lib/urls.ts exports webAppUrl + no hardcoded prod URLs"
done

summary
