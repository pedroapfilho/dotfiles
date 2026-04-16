#!/usr/bin/env bash
# Verify prisma.config.ts uses `process.env.DATABASE_URL ?? ""` (not Prisma's
# env() helper). Standards.md § Prisma: this lets `prisma generate` succeed in
# CI without database credentials.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking prisma.config.ts uses process.env...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  configs=$(find "$REPO_PATH" -name "prisma.config.ts" \
    -not -path "*/node_modules/*" \
    -not -path "*/.next/*" \
    -not -path "*/.turbo/*" \
    -not -path "*/dist/*" \
    -not -path "*/generated/*" 2>/dev/null || true)

  if [[ -z "$configs" ]]; then
    skip "$repo" "prisma-config" "no prisma.config.ts found"
    continue
  fi

  bad=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    rel="${f#${REPO_PATH}/}"
    if ! grep -qE 'process\.env\.DATABASE_URL\s*\?\?' "$f"; then
      bad+="${rel} (missing process.env.DATABASE_URL ?? \"\"); "
    elif grep -qE '\benv\(\s*["'\'']DATABASE_URL' "$f"; then
      bad+="${rel} (uses env(\"DATABASE_URL\")); "
    fi
  done <<< "$configs"

  if [[ -z "$bad" ]]; then
    pass "$repo" "prisma.config.ts uses process.env"
  else
    fail "$repo" "prisma-config" "${bad%; }"
  fi
done

summary
