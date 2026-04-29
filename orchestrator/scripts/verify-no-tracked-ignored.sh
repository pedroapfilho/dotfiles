#!/usr/bin/env bash
# Verify no files are tracked in git that match a .gitignore pattern.
#
# `.gitignore` only prevents *new* files from being added — files already
# tracked stay tracked until explicitly untracked with `git rm --cached`.
# This drift produced noisy diffs in collabtime when Prisma client files
# regenerated on every version bump (16 tracked files inside an ignored
# `packages/db/src/generated/` tree).
#
# Uses `git ls-files -i --exclude-standard -c` which lists files that are
# both tracked AND matched by an exclude pattern. Empty output = clean.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking no tracked files match .gitignore patterns...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  if [[ ! -d "$REPO_PATH/.git" ]]; then
    skip "$repo" "no-tracked-ignored" "not a git repo"
    continue
  fi

  # `-i` ignored, `--exclude-standard` use .gitignore + .git/info/exclude
  # + global excludes, `-c` cached (currently tracked).
  tracked_ignored=$(cd "$REPO_PATH" && git ls-files -i --exclude-standard -c 2>/dev/null || true)

  if [[ -z "$tracked_ignored" ]]; then
    pass "$repo" "no tracked files match .gitignore"
  else
    count=$(printf "%s\n" "$tracked_ignored" | wc -l | tr -d ' ')
    # Show first 3 paths in the failure message so the cause is obvious;
    # full list is one `git ls-files -i --exclude-standard -c` away.
    sample=$(printf "%s\n" "$tracked_ignored" | head -3 | paste -sd ', ' -)
    [[ $count -gt 3 ]] && sample+=", +$((count - 3)) more"
    fail "$repo" "no-tracked-ignored" "$count file(s) tracked despite gitignore: $sample"
  fi
done

summary
