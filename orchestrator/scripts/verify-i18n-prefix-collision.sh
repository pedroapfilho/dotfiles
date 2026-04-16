#!/usr/bin/env bash
# Verify no i18n namespace-prefix collision.
# See standards.md § i18n: useTranslations("ns") + t("ns.foo") resolves to
# ns.ns.foo, which usually doesn't exist and renders the literal key.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AST_SCRIPT="${SCRIPT_DIR}/lib/i18n-prefix-collision.mjs"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for i18n namespace-prefix collisions...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  if [[ ! -d "${REPO_PATH}/node_modules/typescript" ]]; then
    skip "$repo" "i18n-prefix-collision" "node_modules/typescript missing"
    continue
  fi

  if offenders=$(node "$AST_SCRIPT" "$REPO_PATH" 2>&1); then
    pass "$repo" "no i18n namespace-prefix collisions"
  else
    rc=$?
    if [[ "$rc" -eq 1 ]]; then
      count=$(printf '%s\n' "$offenders" | wc -l | tr -d ' ')
      example=$(printf '%s\n' "$offenders" | head -1)
      fail "$repo" "i18n prefix collision" "$count site(s), e.g. $example"
    else
      fail "$repo" "i18n-prefix-collision" "ast script error: $offenders"
    fi
  fi
done

summary
