#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

TOTAL_FAILURES=0

run_verifier() {
  local name="$1"
  shift
  local script="${SCRIPT_DIR}/verify-${name}.sh"

  printf "\n${BOLD}════════════════════════════════════════${RESET}\n"
  printf "${BOLD}  %s${RESET}\n" "$name"
  printf "${BOLD}════════════════════════════════════════${RESET}\n\n"

  if "$script" "$@"; then
    : # pass
  else
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
  fi
}

for verifier in versions ci lint packages dev e2e ui naming theme primitives shared-ui tsconfig no-pointless-async form-field-in-effect-deps i18n-prefix-collision prisma-config root-scripts gitignore; do
  run_verifier "$verifier" "$@"
done

printf "\n${BOLD}════════════════════════════════════════${RESET}\n"
if [[ "$TOTAL_FAILURES" -eq 0 ]]; then
  printf "${GREEN}${BOLD}  All verifiers passed!${RESET}\n"
else
  printf "${RED}${BOLD}  %d verifier(s) reported failures${RESET}\n" "$TOTAL_FAILURES"
fi
printf "${BOLD}════════════════════════════════════════${RESET}\n"

[[ "$TOTAL_FAILURES" -eq 0 ]]
