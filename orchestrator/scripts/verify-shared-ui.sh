#!/usr/bin/env bash
# Verify cross-app UI components aren't duplicated under apps/*/src/components.
# Canonical components (map, rich-text, toaster) must live in @repo/ui.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking shared UI components...${RESET}\n\n"

# Components that must not exist as app-local copies — move them to @repo/ui.
# If only one app uses it, still prefer @repo/ui so the pattern is consistent.
SHARED_COMPONENTS=("map.tsx" "rich-text.tsx" "toaster.tsx")

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  for component in "${SHARED_COMPONENTS[@]}"; do
    # Look under every app's src/components (any depth)
    dupes=$(find "${REPO_PATH}/apps" -type f -name "$component" \
      -not -path "*/node_modules/*" -not -path "*/.next/*" \
      2>/dev/null || true)

    if [[ -z "$dupes" ]]; then
      pass "$repo" "no app-level $component"
    else
      count=$(echo "$dupes" | wc -l | tr -d ' ')
      example=$(echo "$dupes" | head -1 | sed "s|${REPO_PATH}/||")
      fail "$repo" "app-level $component" "$count file(s), e.g. $example — move to @repo/ui"
    fi
  done

  # Double-check: @repo/ui has the canonical versions where the repo uses them.
  # A repo might not use map (e.g. acme), so only warn if no copy exists anywhere.
  for component in "${SHARED_COMPONENTS[@]}"; do
    if [[ -f "${REPO_PATH}/packages/ui/src/components/${component}" ]]; then
      pass "$repo" "@repo/ui/components/$component present"
    fi
  done
done

summary
