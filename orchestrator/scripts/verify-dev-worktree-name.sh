#!/usr/bin/env bash
# Verify every repo's dev pipeline propagates WORKTREE_NAME correctly:
#   1. Root `dev` script captures WORKTREE_NAME from $(basename $PWD), with
#      the canonical `<project>-monorepo` directory special-cased to empty.
#   2. turbo.json declares `WORKTREE_NAME` in the `dev` task's `env` (required
#      by turbo strict-env mode — otherwise the var is scrubbed before
#      reaching app dev scripts).
#   3. Every app `dev` script that invokes `portless run` uses
#      `--name ${WORKTREE_NAME:+${WORKTREE_NAME}.}<project>.<slug>` so the
#      worktree prefix flows through.
#
# Why: the inline-shell-substitution pattern fails silently if turbo strips
# the env var. We standardized the shape so conductor worktrees get the right
# URLs without per-worktree .env edits — this verifier locks that in.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking WORKTREE_NAME propagation in dev pipeline...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  PKG="${REPO_PATH}/package.json"
  TURBO="${REPO_PATH}/turbo.json"

  # 1) Root `dev` script captures WORKTREE_NAME
  if [[ ! -f "$PKG" ]]; then
    fail "$repo" "dev-worktree-name" "root package.json missing"
    continue
  fi
  root_dev=$(jq -r '.scripts.dev // ""' "$PKG")
  if [[ "$root_dev" != *"WORKTREE_NAME="*"basename"*"PWD"* ]]; then
    fail "$repo" "root-dev" "missing WORKTREE_NAME=\$(basename \$PWD) capture, got: ${root_dev:0:80}"
    continue
  fi

  # 2) turbo.json declares WORKTREE_NAME in dev.env
  if [[ ! -f "$TURBO" ]]; then
    fail "$repo" "dev-worktree-name" "turbo.json missing"
    continue
  fi
  declares=$(jq -r '
    (.tasks.dev.env // []) +
    (.globalEnv // []) +
    (.tasks.dev.passThroughEnv // []) +
    (.globalPassThroughEnv // [])
    | map(select(. == "WORKTREE_NAME"))
    | length
  ' "$TURBO" 2>/dev/null || echo 0)
  if [[ "$declares" -eq 0 ]]; then
    fail "$repo" "turbo-env" "WORKTREE_NAME not declared in turbo.json (dev.env or globalEnv)"
    continue
  fi

  # 3) Every app `dev` script using `portless run` uses ${WORKTREE_NAME:+...} prefix
  missing_prefix=()
  for app_pkg in "${REPO_PATH}"/apps/*/package.json; do
    [[ -f "$app_pkg" ]] || continue
    app_dev=$(jq -r '.scripts.dev // ""' "$app_pkg")
    # Only inspect scripts that invoke portless run
    if [[ "$app_dev" == *"portless run"* ]]; then
      if [[ "$app_dev" != *'${WORKTREE_NAME:+'* ]]; then
        rel_path="${app_pkg#${REPO_PATH}/}"
        missing_prefix+=("$rel_path")
      fi
    fi
  done

  if [[ "${#missing_prefix[@]}" -gt 0 ]]; then
    fail "$repo" "app-dev-prefix" "missing \${WORKTREE_NAME:+...} prefix in: ${missing_prefix[*]}"
    continue
  fi

  pass "$repo" "dev-worktree-name: root captures, turbo declares, app dev scripts prefix"
done

summary
