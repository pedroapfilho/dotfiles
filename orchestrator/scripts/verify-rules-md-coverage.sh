#!/usr/bin/env bash
# Verify standards.md indexes every verify-*.sh script.
#
# standards.md is the canonical fleet rule list. Each rule should map to a
# verifier so it can be enforced; conversely each verifier should be
# documented so future maintainers know what it checks.
#
# This meta-verifier walks `scripts/verify-*.sh` and asserts every name
# appears in standards.md (Contents table or anywhere). Excludes:
#   - verify-all.sh                  (orchestrator entry, not a rule)
#   - verify-rules-md-coverage.sh    (this file, also meta)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"

STANDARDS_MD="${SCRIPT_DIR}/../../../orchestrator/standards.md"

printf "${BOLD}Checking standards.md indexes every verify-*.sh script...${RESET}\n\n"

if [[ ! -f "$STANDARDS_MD" ]]; then
  printf "${RED}FAIL${RESET} standards.md not found at %s\n" "$STANDARDS_MD"
  exit 1
fi

missing=()
for script in "${SCRIPT_DIR}"/verify-*.sh; do
  name=$(basename "$script")
  case "$name" in
    verify-all.sh|verify-rules-md-coverage.sh) continue ;;
  esac
  if ! grep -qF "$name" "$STANDARDS_MD"; then
    missing+=("$name")
  fi
done

if [[ "${#missing[@]}" -eq 0 ]]; then
  printf "${GREEN}PASS${RESET} every verifier listed in standards.md\n"
  exit 0
fi

printf "${RED}FAIL${RESET} %d verifier(s) missing from standards.md:\n" "${#missing[@]}"
for name in "${missing[@]}"; do
  printf "  - %s\n" "$name"
done
exit 1
