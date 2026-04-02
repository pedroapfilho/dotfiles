#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking UI patterns...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # @tanstack/react-form used (not react-hook-form)
  if grep -rq "react-hook-form" "${REPO_PATH}/apps/" "${REPO_PATH}/packages/" --include="package.json" 2>/dev/null; then
    fail "$repo" "form library" "react-hook-form found — should use @tanstack/react-form"
  else
    pass "$repo" "no react-hook-form"
  fi

  # Check for @tanstack/react-form in at least one app
  if grep -rq "@tanstack/react-form" "${REPO_PATH}/apps/" --include="package.json" 2>/dev/null; then
    pass "$repo" "@tanstack/react-form in use"
  else
    skip "$repo" "@tanstack/react-form" "not found in any app (may not have forms yet)"
  fi

  # @repo/ui uses Tailwind ui: prefix
  ui_css="${REPO_PATH}/packages/ui/src/styles/globals.css"
  if [[ -f "$ui_css" ]]; then
    if grep -q 'prefix(ui)' "$ui_css"; then
      pass "$repo" "@repo/ui Tailwind prefix(ui)"
    else
      fail "$repo" "@repo/ui prefix" "prefix(ui) not found in globals.css"
    fi
  else
    fail "$repo" "@repo/ui globals.css" "packages/ui/src/styles/globals.css not found"
  fi

  # cn() uses extendTailwindMerge with experimentalParseClassName
  found_cn=false
  while IFS= read -r -d '' f; do
    if grep -q "experimentalParseClassName" "$f" 2>/dev/null; then
      found_cn=true
      break
    fi
  done < <(find "${REPO_PATH}/packages/ui/src" -type f \( -name "*.ts" -o -name "*.tsx" \) -print0 2>/dev/null)
  if [[ "$found_cn" == true ]]; then
    pass "$repo" "cn() uses experimentalParseClassName"
  else
    fail "$repo" "cn() helper" "experimentalParseClassName not found in @repo/ui"
  fi

  # Prisma config uses process.env.DATABASE_URL ?? ""
  prisma_config="${REPO_PATH}/packages/db/prisma.config.ts"
  if [[ -f "$prisma_config" ]]; then
    if grep -q 'process.env.DATABASE_URL' "$prisma_config"; then
      pass "$repo" "prisma.config.ts uses process.env.DATABASE_URL"
    else
      fail "$repo" "prisma.config.ts" "should use process.env.DATABASE_URL ?? \"\""
    fi
  fi
done

summary
