#!/usr/bin/env bash
# Verify Server Components don't have pointless `async` (no `await` in body).
# Targets: apps/*/src/app/**/{page,layout,template,default}.tsx
# Skips: not-found.tsx, error.tsx, loading.tsx (boundary files, usually trivial)
#
# Marking a Server Component async with no suspense point forces extra runtime
# overhead and prevents some prerender wins. See standards.md § Server Performance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AST_SCRIPT="${SCRIPT_DIR}/lib/no-pointless-async.mjs"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for pointless async on Server Components...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  if [[ ! -d "${REPO_PATH}/node_modules/typescript" ]]; then
    skip "$repo" "no-pointless-async" "node_modules/typescript missing — run pnpm install"
    continue
  fi

  if offenders=$(node "$AST_SCRIPT" "$REPO_PATH" 2>&1); then
    pass "$repo" "no pointless async on Server Components"
  else
    rc=$?
    if [[ "$rc" -eq 1 ]]; then
      count=$(printf '%s\n' "$offenders" | wc -l | tr -d ' ')
      example=$(printf '%s\n' "$offenders" | head -1)
      fail "$repo" "pointless async" "$count file(s), e.g. $example"
    else
      fail "$repo" "no-pointless-async" "ast script error: $offenders"
    fi
  fi
done

summary
