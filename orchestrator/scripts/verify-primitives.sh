#!/usr/bin/env bash
# Verify the component-primitive story:
#   - @repo/ui depends on @base-ui/react, not radix-ui / @radix-ui/*
#   - base-ui wrappers don't ship spurious "use client" directives
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking component primitives...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  UI_PKG="${REPO_PATH}/packages/ui/package.json"

  [[ -f "$UI_PKG" ]] || { skip "$repo" "@repo/ui" "no packages/ui"; continue; }

  # @base-ui/react must be a dependency of @repo/ui
  if pkg_get "${REPO_PATH}/packages/ui" '.dependencies["@base-ui/react"] // empty' | grep -q .; then
    pass "$repo" "@repo/ui uses @base-ui/react"
  else
    fail "$repo" "@base-ui/react missing" "not in @repo/ui dependencies"
  fi

  # radix-ui / @radix-ui/* must NOT be in @repo/ui deps
  radix_hits=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | to_entries[] | select(.key == "radix-ui" or (.key | startswith("@radix-ui/"))) | .key' "$UI_PKG" 2>/dev/null || true)
  if [[ -z "$radix_hits" ]]; then
    pass "$repo" "@repo/ui has no radix-ui dependency"
  else
    fail "$repo" "radix-ui present" "$(echo "$radix_hits" | tr '\n' ' ')"
  fi

  # No "use client" in base-ui wrappers that don't use React hooks.
  # Heuristic: look for files in packages/ui/src/components that
  #   - import from "@base-ui/react/..."
  #   - start with "use client"
  #   - don't use useState/useEffect/useRef/useMemo/useCallback/useReducer/useContext/useId
  offenders=$(find "${REPO_PATH}/packages/ui/src/components" -type f -name "*.tsx" 2>/dev/null | while read -r f; do
    head -1 "$f" | grep -q '"use client"' || continue
    grep -q '@base-ui/react' "$f" || continue
    # Uses a React hook? (look for useSomething( at a word boundary, but not `useRender`
    # which is a base-ui utility, not a React state hook)
    if grep -qE '\buse(State|Effect|Ref|Memo|Callback|Reducer|Context|Id|LayoutEffect|Transition|DeferredValue|SyncExternalStore|InsertionEffect|ImperativeHandle|OptimisticValue|ActionState)\b' "$f"; then
      continue
    fi
    echo "$f"
  done)

  if [[ -z "$offenders" ]]; then
    pass "$repo" "no unnecessary \"use client\" in base-ui wrappers"
  else
    count=$(echo "$offenders" | wc -l | tr -d ' ')
    example=$(echo "$offenders" | head -1 | sed "s|${REPO_PATH}/||")
    fail "$repo" "spurious 'use client'" "$count file(s), e.g. $example"
  fi
done

summary
