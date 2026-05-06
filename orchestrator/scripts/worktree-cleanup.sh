#!/usr/bin/env bash
# Remove per-task worktrees once their PRs have merged.
#
# Phase 5 of cross-repo-worktrees spec. Pairs with worktree.sh.
#
# Modes:
#   worktree-cleanup.sh <slug>           # remove all <repo>-monorepo-<slug>
#   worktree-cleanup.sh --all-merged     # scan all sibling worktrees, remove ones whose branch is merged
#
# A worktree is only removed when:
#   1. Its current branch is merged into origin/main (via git merge-base
#      --is-ancestor), OR --force is passed.
#   2. The worktree has no uncommitted changes (clean status), OR --force.
#
# The local branch is also deleted after the worktree is removed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"

usage() {
  cat <<'EOF'
Usage:
  worktree-cleanup.sh <slug>           # remove <repo>-monorepo-<slug> worktrees
  worktree-cleanup.sh --all-merged     # remove all sibling worktrees with merged branches
  worktree-cleanup.sh --help

Flags:
  --force        skip merged + clean checks (DANGEROUS — drops local-only commits)
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

MODE=""
SLUG=""
FORCE=0

case "$1" in
  --help|-h) usage; exit 0 ;;
  --all-merged) MODE="all-merged"; shift ;;
  *) MODE="slug"; SLUG="$1"; shift ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf "Unknown arg: %s\n\n" "$1"; usage; exit 1 ;;
  esac
done

if [[ -z "${_ORCH_ROOT:-}" ]]; then
  printf "${RED}error${RESET}: not in an orchestrator directory\n"
  exit 1
fi

PARENT="$_ORCH_PARENT"

# Returns 0 if branch is merged into origin/main, else 1.
is_merged() {
  local repo_dir="$1" branch="$2"
  cd "$repo_dir"
  git fetch --quiet origin main 2>/dev/null || true
  git merge-base --is-ancestor "$branch" origin/main 2>/dev/null
}

# Returns 0 if worktree has no uncommitted changes, else 1.
is_clean() {
  local wt="$1"
  cd "$wt"
  [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

remove_worktree() {
  local repo="$1" wt="$2" branch="$3"
  local canonical="${REPOS_DIR}/${repo}-monorepo"

  cd "$canonical"
  if git worktree remove "$wt" 2>/dev/null; then
    if [[ -n "$branch" ]] && git show-ref --verify --quiet "refs/heads/${branch}"; then
      git branch -D "$branch" >/dev/null 2>&1 || true
    fi
    printf "${GREEN}removed${RESET} %s -> %s\n" "$repo" "$wt"
    return 0
  fi
  return 1
}

cleanup_one() {
  local repo="$1" wt="$2"
  local canonical="${REPOS_DIR}/${repo}-monorepo"

  if [[ ! -d "$wt" ]]; then
    return 0
  fi

  cd "$wt"
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

  if [[ "$FORCE" -eq 0 ]]; then
    if [[ -z "$branch" ]] || [[ "$branch" == "main" ]]; then
      printf "${YELLOW}skip${RESET} %s: %s on '%s' (use --force to override)\n" "$repo" "$wt" "${branch:-detached}"
      return 0
    fi

    if ! is_merged "$canonical" "$branch"; then
      printf "${YELLOW}skip${RESET} %s: branch '%s' not yet merged into origin/main\n" "$repo" "$branch"
      return 0
    fi

    if ! is_clean "$wt"; then
      printf "${YELLOW}skip${RESET} %s: %s has uncommitted changes\n" "$repo" "$wt"
      return 0
    fi
  fi

  remove_worktree "$repo" "$wt" "$branch"
}

if [[ "$MODE" == "slug" ]]; then
  printf "${BOLD}Cleanup worktrees for slug '%s'${RESET}\n\n" "$SLUG"
  for repo in "${REPO_NAMES[@]}"; do
    wt="${PARENT}/${repo}-monorepo-${SLUG}"
    cleanup_one "$repo" "$wt"
  done
else
  # --all-merged: scan every sibling worktree
  printf "${BOLD}Cleanup all merged sibling worktrees${RESET}\n\n"
  for repo in "${REPO_NAMES[@]}"; do
    canonical="${REPOS_DIR}/${repo}-monorepo"
    [[ -d "$canonical" ]] || continue

    cd "$canonical"
    while IFS= read -r wt; do
      [[ -z "$wt" ]] && continue
      [[ "$wt" == "$canonical" ]] && continue
      cleanup_one "$repo" "$wt"
    done < <(git worktree list --porcelain | awk '/^worktree / { print $2 }')
  done
fi

cd "$_ORCH_ROOT"
printf "\n${BOLD}Done.${RESET}\n"
