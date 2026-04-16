#!/usr/bin/env bash
# Verify no @tanstack/react-form `field` object appears in React hook deps.
# See standards.md § Forms: "NEVER use field.handleChange in useEffect/useCallback
# with field in deps — use field.form.setFieldValue(field.name, value)".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AST_SCRIPT="${SCRIPT_DIR}/lib/form-field-in-effect-deps.mjs"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for unstable 'field' in React hook deps...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  if [[ ! -d "${REPO_PATH}/node_modules/typescript" ]]; then
    skip "$repo" "form-field-in-effect-deps" "node_modules/typescript missing"
    continue
  fi

  if offenders=$(node "$AST_SCRIPT" "$REPO_PATH" 2>&1); then
    pass "$repo" "no unstable 'field' in hook deps"
  else
    rc=$?
    if [[ "$rc" -eq 1 ]]; then
      count=$(printf '%s\n' "$offenders" | wc -l | tr -d ' ')
      example=$(printf '%s\n' "$offenders" | head -1)
      fail "$repo" "field in hook deps" "$count file(s), e.g. $example"
    else
      fail "$repo" "form-field-in-effect-deps" "ast script error: $offenders"
    fi
  fi
done

summary
