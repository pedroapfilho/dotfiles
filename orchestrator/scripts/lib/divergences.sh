#!/usr/bin/env bash
# Reads divergences.json and provides skip-checking functions.
#
# Uses a private _DIVERGENCES_LIB_DIR rather than SCRIPT_DIR — sourcing this
# file used to clobber the caller's SCRIPT_DIR, which broke any verifier that
# referenced its own SCRIPT_DIR after `source lib/divergences.sh`.

_DIVERGENCES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIVERGENCES_FILE="${_DIVERGENCES_LIB_DIR}/../../divergences.json"

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
