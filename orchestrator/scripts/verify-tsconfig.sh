#!/usr/bin/env bash
# Verify @repo/config-typescript has the canonical 5 configs and matches acme byte-for-byte.
# Canonical shape (sourced from shadcn workshop + our lib/next/server needs):
#   base.json, library.json, nextjs.json, react-library.json, server.json
# Dead configs (vite.json, electron.json, node.json) must not exist — nobody extends them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking @repo/config-typescript shape...${RESET}\n\n"

ACME_CONFIG="$(repo_path acme)/packages/config-typescript"

CANONICAL_CONFIGS=("base.json" "library.json" "nextjs.json" "react-library.json" "server.json")
DEAD_CONFIGS=("vite.json" "electron.json" "node.json")

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  CFG_DIR="${REPO_PATH}/packages/config-typescript"

  if [[ ! -d "$CFG_DIR" ]]; then
    fail "$repo" "@repo/config-typescript" "packages/config-typescript missing"
    continue
  fi

  # Canonical files must exist and match acme exactly (acme is the source of truth).
  for cfg in "${CANONICAL_CONFIGS[@]}"; do
    if [[ ! -f "${CFG_DIR}/${cfg}" ]]; then
      # server.json is optional for repos without a standalone Node server
      if [[ "$cfg" == "server.json" ]]; then
        if grep -rq "@repo/typescript-config/server.json" "${REPO_PATH}/apps" "${REPO_PATH}/packages" --include="tsconfig*.json" 2>/dev/null; then
          fail "$repo" "$cfg" "missing but extended somewhere"
        else
          skip "$repo" "$cfg" "not needed (no consumer extends it)"
        fi
        continue
      fi
      fail "$repo" "$cfg" "missing"
      continue
    fi

    if [[ "$repo" == "acme" ]]; then
      pass "$repo" "$cfg exists (source of truth)"
    else
      if diff -q "${ACME_CONFIG}/${cfg}" "${CFG_DIR}/${cfg}" >/dev/null 2>&1; then
        pass "$repo" "$cfg matches acme"
      else
        fail "$repo" "$cfg" "differs from acme"
      fi
    fi
  done

  # Dead configs must not exist.
  for dead in "${DEAD_CONFIGS[@]}"; do
    if [[ -f "${CFG_DIR}/${dead}" ]]; then
      fail "$repo" "$dead" "dead config present — nothing extends it, delete"
    else
      pass "$repo" "no dead $dead"
    fi
  done

  # Every consumer tsconfig must extend one of the canonical configs.
  offenders=$(find "${REPO_PATH}/apps" "${REPO_PATH}/packages" -name "tsconfig*.json" \
    -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/.turbo/*" \
    -not -path "*/generated/*" -not -path "*/dist/*" -not -path "*/config-typescript/*" \
    2>/dev/null | while read -r f; do
      ext=$(jq -r '.extends // empty' "$f" 2>/dev/null)
      [[ -z "$ext" ]] && continue
      [[ "$ext" == "@repo/typescript-config/base.json" ]] && continue
      [[ "$ext" == "@repo/typescript-config/library.json" ]] && continue
      [[ "$ext" == "@repo/typescript-config/nextjs.json" ]] && continue
      [[ "$ext" == "@repo/typescript-config/react-library.json" ]] && continue
      [[ "$ext" == "@repo/typescript-config/server.json" ]] && continue
      echo "$f -> $ext"
    done)

  if [[ -z "$offenders" ]]; then
    pass "$repo" "all tsconfigs extend a canonical base"
  else
    count=$(echo "$offenders" | wc -l | tr -d ' ')
    example=$(echo "$offenders" | head -1 | sed "s|${REPO_PATH}/||")
    fail "$repo" "non-canonical extends" "$count file(s), e.g. $example"
  fi
done

summary
