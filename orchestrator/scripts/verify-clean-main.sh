#!/usr/bin/env bash
# Verify no managed-repo worktree has unpushed commits on `main`.
#
# Phase 4 of cross-repo-worktrees spec. Catches the failure mode where an
# agent or pre-commit-hook bypass committed straight to main inside a
# worktree (canonical or sibling).
#
# Walks every worktree of the canonical repo via `git worktree list`,
# checks each one currently on `main`, and fails if HEAD is ahead of
# `origin/main`.
#
# Skips repos that have a `clean-main` divergence (e.g. transient setup
# branches that intentionally land on main pre-spec).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for unpushed commits on main across all worktrees...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  canonical="${REPOS_DIR}/${repo}-monorepo"

  if [[ ! -d "$canonical" ]]; then
    skip "$repo" "clean-main" "canonical repo not found at $canonical"
    continue
  fi

  if has_divergence "$repo" "git" "clean-main"; then
    skip "$repo" "clean-main" "divergence"
    continue
  fi

  cd "$canonical"

  # Refresh remote tracking ref so `origin/main` reflects the actual remote.
  git fetch --quiet origin main 2>/dev/null || true

  worktrees=$(git worktree list --porcelain | awk '/^worktree / { print $2 }')
  fail_lines=()

  while IFS= read -r wt; do
    [[ -z "$wt" ]] && continue
    [[ ! -d "$wt" ]] && continue

    cd "$wt"
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

    if [[ "$branch" == "main" ]]; then
      ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
      if [[ "$ahead" -gt 0 ]]; then
        fail_lines+=("$wt (ahead $ahead)")
      fi
    fi
  done <<< "$worktrees"

  cd "$canonical"

  if [[ ${#fail_lines[@]} -eq 0 ]]; then
    pass "$repo" "no unpushed commits on main across worktrees"
  else
    fail "$repo" "clean-main" "unpushed commits on main: ${fail_lines[*]}"
  fi
done

summary
