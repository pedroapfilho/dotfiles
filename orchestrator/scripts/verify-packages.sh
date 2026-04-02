#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking package architecture...${RESET}\n\n"

REQUIRED_PACKAGES=("ui" "db" "config-typescript" "config-tailwind" "config-vitest")

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Required packages exist
  for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if [[ -d "${REPO_PATH}/packages/${pkg}" ]]; then
      pass "$repo" "packages/${pkg} exists"
    else
      fail "$repo" "packages/${pkg}" "directory not found"
    fi
  done

  # config-vitest exports react.ts and node.ts
  vitest_dir="${REPO_PATH}/packages/config-vitest"
  if [[ -d "$vitest_dir" ]]; then
    for config in "react.ts" "node.ts"; do
      if [[ -f "${vitest_dir}/${config}" ]]; then
        pass "$repo" "config-vitest/${config} exists"
      else
        fail "$repo" "config-vitest/${config}" "file not found"
      fi
    done
  fi

  # config-typescript has required bases
  ts_dir="${REPO_PATH}/packages/config-typescript"
  if [[ -d "$ts_dir" ]]; then
    for base in "base.json" "nextjs.json"; do
      if [[ -f "${ts_dir}/${base}" ]]; then
        pass "$repo" "config-typescript/${base} exists"
      else
        fail "$repo" "config-typescript/${base}" "file not found"
      fi
    done
  fi

  # No dead config packages (config-eslint)
  if [[ -d "${REPO_PATH}/packages/config-eslint" ]]; then
    if has_divergence "$repo" "packages" "has-config-eslint-vestigial"; then
      skip "$repo" "packages/config-eslint exists" "has-config-eslint-vestigial"
    else
      fail "$repo" "packages/config-eslint" "vestigial package — should be removed (oxlint is the standard)"
    fi
  fi
done

summary
