#!/usr/bin/env bash
# Render divergences.json as a readable table per repo.
# Usage: ./scripts/show-divergences.sh [--repo <name>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"

DIVERGENCES_FILE="${SCRIPT_DIR}/../divergences.json"

parse_repo_flag "$@"

printf "${BOLD}Fleet divergences${RESET}\n"
printf "Source: %s\n\n" "$DIVERGENCES_FILE"

total_categories=0
total_entries=0
repos_with=0

for repo in "${SCOPED_REPOS[@]}"; do
  has_any=$(jq -r --arg r "$repo" '.[$r] // {} | length' "$DIVERGENCES_FILE")
  if [[ "$has_any" -eq 0 ]]; then
    printf "${GREEN}● %-12s${RESET} clean (0 divergences)\n" "$repo"
    continue
  fi

  repos_with=$((repos_with + 1))
  printf "${YELLOW}● %-12s${RESET} %d categor%s\n" \
    "$repo" \
    "$has_any" \
    "$([[ "$has_any" -eq 1 ]] && echo "y" || echo "ies")"

  categories=$(jq -r --arg r "$repo" '.[$r] | keys[]' "$DIVERGENCES_FILE")
  while IFS= read -r cat; do
    [[ -z "$cat" ]] && continue
    total_categories=$((total_categories + 1))
    entries=$(jq -r --arg r "$repo" --arg c "$cat" '.[$r][$c][]' "$DIVERGENCES_FILE")
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      total_entries=$((total_entries + 1))
      printf "    ${BOLD}%-18s${RESET} %s\n" "$cat" "$entry"
    done <<< "$entries"
  done <<< "$categories"
  printf "\n"
done

printf "${BOLD}Summary:${RESET} %d repo(s) with divergences, %d categor%s, %d entr%s total\n" \
  "$repos_with" \
  "$total_categories" \
  "$([[ "$total_categories" -eq 1 ]] && echo "y" || echo "ies")" \
  "$total_entries" \
  "$([[ "$total_entries" -eq 1 ]] && echo "y" || echo "ies")"
