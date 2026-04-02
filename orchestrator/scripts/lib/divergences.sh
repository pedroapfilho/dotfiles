#!/usr/bin/env bash
# Reads divergences.json and provides skip-checking functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIVERGENCES_FILE="${SCRIPT_DIR}/../../divergences.json"

# Check if a repo has a specific divergence in a category
# Usage: has_divergence "frow" "lint" "sort-rules-off"
has_divergence() {
  local repo="$1" category="$2" divergence="$3"
  jq -e --arg r "$repo" --arg c "$category" --arg d "$divergence" \
    '.[$r][$c] // [] | index($d) != null' \
    "$DIVERGENCES_FILE" &>/dev/null
}

# Get divergence reason string for skip output
# Usage: divergence_reason "frow" "lint" "sort-rules-off"
divergence_reason() {
  echo "$3"
}
