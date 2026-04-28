#!/usr/bin/env bash
# Verify the canonical base styles block in each repo's @repo/ui globals.css.
#
# Tailwind v4 dropped the default cursor:pointer on <button>; we add it back
# globally for both <button> and [role="button"] so consumers don't need to
# remember per-button. Same block ships a thin themed scrollbar so the design
# system feels cohesive across browsers (webkit + standards-track).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

# Each pattern is grepped with -F (literal). All must be present in the file
# for the repo to pass. Update both this list and the source-of-truth block in
# every repo's packages/ui/src/styles/globals.css when extending.
REQUIRED_PATTERNS=(
  'button:not(:disabled),'
  '[role="button"]:not(:disabled) {'
  'cursor: pointer;'
  '::-webkit-scrollbar {'
  '::-webkit-scrollbar-track {'
  '::-webkit-scrollbar-thumb {'
  'background: var(--border);'
  'scrollbar-width: thin;'
  'scrollbar-color: var(--border) transparent;'
)

# Common typo we've shipped before; explicit guard so a future copy-paste
# doesn't silently regress.
BANNED_TYPO='::-webkot-'

printf "${BOLD}Checking canonical base styles in @repo/ui globals.css...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  GLOBALS="${REPO_PATH}/packages/ui/src/styles/globals.css"

  if [[ ! -f "$GLOBALS" ]]; then
    fail "$repo" "globals.css" "packages/ui/src/styles/globals.css missing"
    continue
  fi

  if grep -qF "$BANNED_TYPO" "$GLOBALS"; then
    fail "$repo" "typo" "found '${BANNED_TYPO}' (probably ::-webkit- typo) in globals.css"
    continue
  fi

  missing=()
  for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -qF "$pattern" "$GLOBALS"; then
      missing+=("$pattern")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    pass "$repo" "all canonical base styles present"
  else
    fail "$repo" "missing patterns" "${missing[*]}"
  fi
done

summary
