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

  # Check for stray top-level per-app .gitignore files. These are usually
  # `create-next-app` defaults that duplicate root patterns. Deeper files
  # like apps/<name>/<dir>/.gitignore are allowed (e.g. logs/.gitignore for
  # the empty-dir-keep pattern).
  stray_apps=$(find "${REPO_PATH}/apps" -mindepth 2 -maxdepth 2 -name ".gitignore" 2>/dev/null || true)
  if [[ -n "$stray_apps" ]]; then
    while IFS= read -r f; do
      rel="${f#${REPO_PATH}/}"
      fail "$repo" "stray per-app gitignore" "$rel — root .gitignore covers all canonical patterns; delete this file"
    done <<< "$stray_apps"
  fi
done

summary
