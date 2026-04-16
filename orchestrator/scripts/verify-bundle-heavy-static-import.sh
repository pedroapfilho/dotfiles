#!/usr/bin/env bash
# Verify "use client" components don't statically import known-heavy packages.
# Standards.md § Bundle Optimization: tiptap/leaflet/charts must be loaded via
# next/dynamic so they don't bloat first-paint JS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AST_SCRIPT="${SCRIPT_DIR}/lib/bundle-heavy-static-import.mjs"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for heavy static imports in client components...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  if [[ ! -d "${REPO_PATH}/node_modules/typescript" ]]; then
    skip "$repo" "bundle-heavy-static-import" "node_modules/typescript missing"
    continue
  fi

  if offenders=$(node "$AST_SCRIPT" "$REPO_PATH" 2>&1); then
    pass "$repo" "no heavy static imports in client components"
  else
    rc=$?
    if [[ "$rc" -eq 1 ]]; then
      count=$(printf '%s\n' "$offenders" | wc -l | tr -d ' ')
      example=$(printf '%s\n' "$offenders" | head -1)
      fail "$repo" "heavy static import" "$count site(s), e.g. $example"
    else
      fail "$repo" "bundle-heavy-static-import" "ast script error: $offenders"
    fi
  fi
done

summary
