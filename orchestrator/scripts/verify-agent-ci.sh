#!/usr/bin/env bash
# Verify each repo exposes the agent-ci local-CI surface defined in
# standards.md § Local CI (agent-ci):
#   - @redwoodjs/agent-ci pinned in root devDependencies
#   - canonical scripts: ci:local, ci:local:fast, ci:local:e2e
#   - .husky/pre-push exists, is executable, and runs `pnpm ci:local:fast`
#   - .env.agent-ci.example checked in at repo root
#   - AGENTS.md contains a "## Local CI (agent-ci)" heading
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

REQUIRED_SCRIPTS=("ci:local" "ci:local:fast" "ci:local:e2e")

printf "${BOLD}Checking agent-ci surface...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  PKG="${REPO_PATH}/package.json"

  if [[ ! -f "$PKG" ]]; then
    fail "$repo" "package.json" "missing"
    continue
  fi

  # devDependency present
  if jq -e '.devDependencies."@redwoodjs/agent-ci"' "$PKG" >/dev/null 2>&1; then
    pass "$repo" "@redwoodjs/agent-ci pinned"
  else
    fail "$repo" "@redwoodjs/agent-ci" "not in devDependencies"
  fi

  # canonical scripts present
  for s in "${REQUIRED_SCRIPTS[@]}"; do
    if jq -e --arg s "$s" '.scripts | has($s)' "$PKG" >/dev/null 2>&1; then
      pass "$repo" "script $s present"
    else
      fail "$repo" "script $s" "missing"
    fi
  done

  # .husky/pre-push exists, is executable, runs ci:local:fast
  PRE_PUSH="${REPO_PATH}/.husky/pre-push"
  if [[ ! -f "$PRE_PUSH" ]]; then
    fail "$repo" ".husky/pre-push" "missing"
  elif [[ ! -x "$PRE_PUSH" ]]; then
    fail "$repo" ".husky/pre-push" "not executable"
  elif ! grep -q "pnpm ci:local:fast" "$PRE_PUSH"; then
    fail "$repo" ".husky/pre-push" "does not run \`pnpm ci:local:fast\`"
  else
    pass "$repo" ".husky/pre-push runs pnpm ci:local:fast"
  fi

  # .env.agent-ci.example present
  if [[ -f "${REPO_PATH}/.env.agent-ci.example" ]]; then
    pass "$repo" ".env.agent-ci.example present"
  else
    fail "$repo" ".env.agent-ci.example" "missing"
  fi

  # AGENTS.md contains the section heading
  AGENTS_MD="${REPO_PATH}/AGENTS.md"
  if [[ ! -f "$AGENTS_MD" ]]; then
    fail "$repo" "AGENTS.md" "missing"
  elif grep -q "^## Local CI (agent-ci)" "$AGENTS_MD"; then
    pass "$repo" "AGENTS.md § Local CI (agent-ci)"
  else
    fail "$repo" "AGENTS.md" "missing \`## Local CI (agent-ci)\` section"
  fi
done

summary
