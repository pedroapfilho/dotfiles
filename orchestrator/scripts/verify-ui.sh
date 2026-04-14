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

  # Workshop Tailwind pattern: standard @import "tailwindcss" (no prefix) + @source directives
  ui_css="${REPO_PATH}/packages/ui/src/styles/globals.css"
  if [[ -f "$ui_css" ]]; then
    if grep -q 'prefix(ui)' "$ui_css"; then
      fail "$repo" "@repo/ui globals.css" "prefix(ui) should be removed — workshop pattern uses standard @import \"tailwindcss\""
    else
      pass "$repo" "@repo/ui globals.css uses standard @import \"tailwindcss\""
    fi

    if grep -q '@source' "$ui_css"; then
      pass "$repo" "@repo/ui globals.css has @source directives"
    else
      fail "$repo" "@repo/ui @source" "no @source directives in globals.css — Tailwind won't scan app code"
    fi
  else
    fail "$repo" "@repo/ui globals.css" "packages/ui/src/styles/globals.css not found"
  fi

  # cn() uses plain twMerge — no experimentalParseClassName hack (workshop pattern)
  cn_file="${REPO_PATH}/packages/ui/src/lib/utils.ts"
  if [[ -f "$cn_file" ]]; then
    if grep -q "experimentalParseClassName" "$cn_file"; then
      fail "$repo" "@repo/ui cn()" "experimentalParseClassName should be removed — use plain twMerge(clsx)"
    else
      pass "$repo" "@repo/ui cn() uses plain twMerge(clsx)"
    fi
  else
    fail "$repo" "@repo/ui cn()" "packages/ui/src/lib/utils.ts not found"
  fi

  # @repo/ui exposes workshop subpath exports (no build step, no bundled dist/)
  ui_pkg="${REPO_PATH}/packages/ui/package.json"
  if [[ -f "$ui_pkg" ]]; then
    if grep -q '"./globals.css"' "$ui_pkg" && grep -q '"./components/\*"' "$ui_pkg"; then
      pass "$repo" "@repo/ui exposes workshop subpath exports"
    else
      fail "$repo" "@repo/ui exports" "expected ./globals.css + ./components/* subpath exports"
    fi

    if grep -q '"./dist/index.css"' "$ui_pkg" || grep -q '"./src/index.ts"' "$ui_pkg"; then
      fail "$repo" "@repo/ui exports" "still references bundled dist/ or src/index.ts barrel (workshop pattern removes both)"
    else
      pass "$repo" "@repo/ui has no bundled dist or barrel"
    fi
  fi

  # @repo/ui has its own postcss.config.mjs (apps re-export from it)
  if [[ -f "${REPO_PATH}/packages/ui/postcss.config.mjs" ]]; then
    pass "$repo" "@repo/ui postcss.config.mjs exists"
  else
    fail "$repo" "@repo/ui postcss.config.mjs" "not found — apps re-export from @repo/ui/postcss.config"
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
