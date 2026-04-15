#!/usr/bin/env bash
# Verify all user-authored source files and directories use kebab-case.
# Skips: generated code, route params, locale dirs, tests fixtures that must match upstream names.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking kebab-case file naming...${RESET}\n\n"

# Anything with an uppercase letter OR an underscore (except leading `_` for Next.js
# conventions like `_components`, `_app`). Locale dirs like `pt-BR` are fine — they
# only contain a hyphen and are inside a `messages/` or `i18n/` path we skip anyway.
is_non_kebab() {
  local name="$1"
  # Strip extension
  local base="${name%.*}"
  # Allow leading underscore (Next.js convention: _app, _components, _gallery)
  case "$base" in
    _*) base="${base#_}" ;;
  esac
  # Check for uppercase or internal underscore
  if [[ "$base" =~ [A-Z] ]] || [[ "$base" =~ [a-z0-9]_[a-z0-9] ]]; then
    return 0
  fi
  return 1
}

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Find every .ts/.tsx under apps/*/src and packages/*/src, excluding:
  #   - node_modules, .next, .turbo, dist, generated/
  #   - locale message dirs (messages/pt-BR, i18n/messages)
  offenders=$(find "${REPO_PATH}/apps" "${REPO_PATH}/packages" \
    -type f \( -name "*.ts" -o -name "*.tsx" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.next/*" \
    -not -path "*/.turbo/*" \
    -not -path "*/dist/*" \
    -not -path "*/generated/*" \
    -not -path "*/messages/*" \
    2>/dev/null | while read -r f; do
      name=$(basename "$f")
      if is_non_kebab "$name"; then
        echo "$f"
      fi
    done)

  if [[ -z "$offenders" ]]; then
    pass "$repo" "all .ts/.tsx filenames are kebab-case"
  else
    count=$(echo "$offenders" | wc -l | tr -d ' ')
    fail "$repo" "kebab-case filenames" "$count non-kebab file(s), e.g. $(echo "$offenders" | head -1 | sed "s|${REPO_PATH}/||")"
  fi

  # Also check directory names.
  # Use -prune to skip entirely (find reports the dir itself before descending,
  # so path-based filters alone still emit the excluded dir itself).
  dir_offenders=$(find "${REPO_PATH}/apps" "${REPO_PATH}/packages" \
    \( -name node_modules -o -name .next -o -name .turbo -o -name dist \
       -o -name generated -o -name messages -o -name i18n \) -prune -o \
    -type d -print \
    2>/dev/null | while read -r d; do
      # Skip the top-level apps/packages themselves
      [[ "$d" == "${REPO_PATH}/apps" || "$d" == "${REPO_PATH}/packages" ]] && continue
      name=$(basename "$d")
      # Allow bracket route params [slug], [...all], @breadcrumb, (auth) group segments
      [[ "$name" == "["*"]" ]] && continue
      [[ "$name" == "@"* ]] && continue
      [[ "$name" == "("*")" ]] && continue
      if is_non_kebab "$name"; then
        echo "$d"
      fi
    done)

  if [[ -z "$dir_offenders" ]]; then
    pass "$repo" "all directory names are kebab-case"
  else
    count=$(echo "$dir_offenders" | wc -l | tr -d ' ')
    fail "$repo" "kebab-case directories" "$count non-kebab dir(s), e.g. $(echo "$dir_offenders" | head -1 | sed "s|${REPO_PATH}/||")"
  fi
done

summary
