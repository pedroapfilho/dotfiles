#!/usr/bin/env bash
# Verify each repo's CLAUDE.md is a symlink to AGENTS.md (the regular file).
#
# AGENTS.md is the canonical source of truth (open standard adopted by Codex,
# Cursor, GitHub Copilot, etc.); CLAUDE.md is a symlink so Claude Code reads
# the same content. A scaffold or agent that drops a regular CLAUDE.md silently
# shadows the symlink target, drifting the two views.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking CLAUDE.md is a symlink to AGENTS.md...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  CLAUDE="${REPO_PATH}/CLAUDE.md"
  AGENTS="${REPO_PATH}/AGENTS.md"

  if [[ ! -f "$AGENTS" ]]; then
    fail "$repo" "agents-md" "AGENTS.md missing — should be the regular-file source of truth"
    continue
  fi

  if [[ -L "$AGENTS" ]]; then
    fail "$repo" "agents-md" "AGENTS.md is a symlink — must be the regular file"
    continue
  fi

  if [[ ! -L "$CLAUDE" ]]; then
    if [[ -f "$CLAUDE" ]]; then
      fail "$repo" "agents-md" "CLAUDE.md is a regular file — must be a symlink to AGENTS.md (otherwise it silently shadows the source of truth)"
    else
      fail "$repo" "agents-md" "CLAUDE.md missing — should be a symlink to AGENTS.md"
    fi
    continue
  fi

  target=$(readlink "$CLAUDE")
  if [[ "$target" != "AGENTS.md" ]]; then
    fail "$repo" "agents-md" "CLAUDE.md symlinks to '$target', expected 'AGENTS.md'"
    continue
  fi

  pass "$repo" "CLAUDE.md -> AGENTS.md"
done

summary
