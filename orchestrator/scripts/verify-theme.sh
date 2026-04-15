#!/usr/bin/env bash
# Verify no hardcoded Tailwind color utilities in app/package source.
# Consumers should use semantic theme tokens only: bg-background, bg-primary,
# bg-muted, text-foreground, text-muted-foreground, border-border, bg-destructive, etc.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking semantic theme tokens...${RESET}\n\n"

# Raw Tailwind palettes that should not appear as className values in source.
# Black/white overlays (bg-black/50, text-white) are allowed by convention — those
# are often intentional overlays over images/video. Status colors outside the theme
# (text-green-600 for success badges) are also allowed.
BANNED_PALETTES='(neutral|gray|zinc|slate|stone|amber)'
BANNED_UTILITIES='(bg|text|border|ring|outline|fill|stroke|placeholder|decoration|divide|accent|caret|shadow|from|to|via)'

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Search under apps/*/src and packages/*/src for the banned pattern in .tsx/.ts/.css files.
  # Exclude React Email packages — CSS vars don't resolve in email clients, so
  # hardcoded colors are correct there.
  offenders=$(grep -rE \
    --include="*.tsx" --include="*.ts" --include="*.css" \
    --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.turbo --exclude-dir=dist --exclude-dir=generated \
    --exclude-dir=email --exclude-dir=emails --exclude-dir=transactional \
    "\\b${BANNED_UTILITIES}-${BANNED_PALETTES}(-[0-9]+)?(\\/[0-9]+)?\\b" \
    "${REPO_PATH}/apps" "${REPO_PATH}/packages" 2>/dev/null || true)

  if [[ -z "$offenders" ]]; then
    pass "$repo" "no hardcoded neutral/gray/amber/etc. colors in source"
  else
    count=$(echo "$offenders" | wc -l | tr -d ' ')
    # Show the first offender inline as a hint
    example=$(echo "$offenders" | head -1 | sed "s|${REPO_PATH}/||" | cut -c1-100)
    if has_divergence "$repo" "theme" "hardcoded-colors"; then
      skip "$repo" "hardcoded-colors" "hardcoded-colors (divergence)"
    else
      fail "$repo" "hardcoded-colors" "$count match(es), e.g. $example"
    fi
  fi
done

summary
