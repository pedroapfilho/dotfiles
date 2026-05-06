#!/usr/bin/env bash
# Create parallel git worktrees on each managed repo at
# `<orchestrator-parent>/<repo>-monorepo-<slug>`.
#
# Phase 2 of cross-repo-worktrees spec. Pairs with the sibling-aware
# `repo_path` resolver in `lib/repos.sh`, which prefers `<repo>-monorepo<slug>`
# over the canonical `~/dev/<repo>-monorepo` when both exist.
#
# Worktree branches default to `feat/<slug>`, overridable via `--branch`.
# Branches are created from `origin/main`; if the branch already exists
# locally or on the remote, the worktree checks it out instead of creating
# a fresh one.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"

usage() {
  cat <<'EOF'
Usage: worktree.sh <slug> [--repos repo1,repo2,...] [--branch <name>]

Creates parallel git worktrees on each managed repo at:
  <orchestrator-parent>/<repo>-monorepo-<slug>

Branch name defaults to `feat/<slug>`. Override with --branch.

Examples:
  worktree.sh add-graphql-route                  # all 5 repos
  worktree.sh fix-auth --repos acme,frow         # scope to two repos
  worktree.sh sentry-gate --branch chore/sentry  # custom branch name
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case "$1" in
  --help|-h)
    usage
    exit 0
    ;;
esac

SLUG="$1"
shift

BRANCH=""
SCOPED=("${REPO_NAMES[@]}")

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repos)
      IFS=',' read -ra SCOPED <<< "$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf "Unknown arg: %s\n\n" "$1"
      usage
      exit 1
      ;;
  esac
done

[[ -z "$BRANCH" ]] && BRANCH="feat/${SLUG}"

if [[ -z "${_ORCH_ROOT:-}" ]]; then
  printf "${RED}error${RESET}: not in an orchestrator directory (no AGENTS.md found)\n"
  exit 1
fi

PARENT="$_ORCH_PARENT"

printf "${BOLD}Creating worktrees for slug '%s' (branch '%s')${RESET}\n" "$SLUG" "$BRANCH"
printf "Parent dir: %s\n\n" "$PARENT"

failures=0
for name in "${SCOPED[@]}"; do
  # Validate repo name is known
  if ! repo_path "$name" >/dev/null 2>&1; then
    printf "${RED}skip${RESET} %s: unknown repo\n" "$name"
    failures=$((failures + 1))
    continue
  fi

  # Always create worktrees off the canonical repo, even if a sibling
  # worktree already exists for an unrelated slug.
  canonical="${REPOS_DIR}/${name}-monorepo"
  worktree="${PARENT}/${name}-monorepo-${SLUG}"

  if [[ ! -d "$canonical" ]]; then
    printf "${RED}skip${RESET} %s: canonical repo not found at %s\n" "$name" "$canonical"
    failures=$((failures + 1))
    continue
  fi

  if [[ -d "$worktree" ]]; then
    printf "${YELLOW}skip${RESET} %s: worktree already exists at %s\n" "$name" "$worktree"
    continue
  fi

  err_log="$(mktemp)"
  cd "$canonical"

  # Reuse local or remote branch if it exists; otherwise fork from origin/main.
  if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git worktree add "$worktree" "$BRANCH" >/dev/null 2>"$err_log" || true
  elif git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    git fetch origin "$BRANCH":"$BRANCH" --quiet 2>/dev/null || true
    git worktree add "$worktree" "$BRANCH" >/dev/null 2>"$err_log" || true
  else
    git fetch origin main --quiet 2>/dev/null || true
    git worktree add "$worktree" -b "$BRANCH" origin/main >/dev/null 2>"$err_log" || true
  fi

  if [[ -d "$worktree" ]]; then
    printf "${GREEN}ok${RESET}   %s -> %s\n" "$name" "$worktree"
  else
    printf "${RED}fail${RESET} %s: %s\n" "$name" "$(cat "$err_log")"
    failures=$((failures + 1))
  fi

  rm -f "$err_log"
done

cd "$_ORCH_ROOT"

if [[ "$failures" -gt 0 ]]; then
  printf "\n${BOLD}Failed: %d${RESET}\n" "$failures"
  exit 1
fi

printf "\n${BOLD}Done.${RESET} Switch into one with: cd %s/<repo>-monorepo-%s\n" "$PARENT" "$SLUG"
