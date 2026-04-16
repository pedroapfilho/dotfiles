#!/usr/bin/env bash
# Verify each repo's root .gitignore contains the canonical patterns from
# standards.md. Repo-specific extras are allowed; missing canonical entries
# fail unless covered by a `gitignore` divergence.
#
# Comparison strips comments + blank lines, then exact-matches each canonical
# pattern. Order doesn't matter; extras are permitted.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

CANONICAL_PATTERNS=(
  "node_modules"
  ".pnp"
  ".pnp.js"
  ".pnpm-store"
  "coverage"
  "tests/e2e/.auth/"
  "playwright-report/"
  "blob-report/"
  "test-results/"
  ".next/"
  "out/"
  "build"
  "next-env.d.ts"
  "dist/"
  "*.tsbuildinfo"
  ".turbo"
  ".vercel"
  ".DS_Store"
  "*.pem"
  "npm-debug.log*"
  "yarn-debug.log*"
  "yarn-error.log*"
  ".pnpm-debug.log*"
  ".env*"
  "!.env.example"
  ".idea"
  ".vscode"
  "*.swp"
  "*.swo"
  "logs/"
  "*.log"
  "**/src/generated/"
  "*.rdb"
  "agents/"
)

printf "${BOLD}Checking root .gitignore matches canonical shape...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  GITIGNORE="${REPO_PATH}/.gitignore"

  if [[ ! -f "$GITIGNORE" ]]; then
    fail "$repo" "gitignore" "root .gitignore missing"
    continue
  fi

  # Effective lines: strip comments, trim whitespace, drop blanks.
  effective=$(sed -E 's/[[:space:]]+$//; s/^[[:space:]]+//' "$GITIGNORE" \
    | grep -v '^#' \
    | grep -v '^$' || true)

  missing=()
  for pattern in "${CANONICAL_PATTERNS[@]}"; do
    if ! printf '%s\n' "$effective" | grep -qxF "$pattern"; then
      if has_divergence "$repo" "gitignore" "${pattern}-missing"; then
        skip "$repo" "$pattern" "$(divergence_reason "$repo" "gitignore" "${pattern}-missing")"
      else
        missing+=("$pattern")
      fi
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    pass "$repo" "all canonical .gitignore patterns present"
  else
    fail "$repo" "missing patterns" "${missing[*]}"
  fi
done

summary
