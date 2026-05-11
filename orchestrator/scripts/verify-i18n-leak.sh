#!/usr/bin/env bash
# Verify no hardcoded non-ASCII strings leak into i18n-enabled apps' source.
#
# Why: localcine dogfood found PT-BR strings like "(Opcional)", "Brasil",
# "Documentário", "Casa" hardcoded in apps/web/apps/dashboard source while the
# UI advertises an English locale. Each leak is small in isolation but they
# compound into "this app is internally bilingual and inconsistent."
#
# Detection: non-ASCII bytes in apps/*/src/**/*.{ts,tsx}. Allowlist:
#   - messages/, locales/, i18n/ (i18n bundles — non-ASCII expected)
#   - terms/, privacy/, contact/, policies/, legal/, content/ (long-form copy)
#   - **/seed*.ts, **/mock*.ts, **/*.test.{ts,tsx}, **/*.spec.{ts,tsx}
#   - **/_components/photos*.tsx (alt text from CMS, not UI strings)
#   - any file with an `i18n-leak-allowed:` marker comment (legitimate
#     non-ASCII in regex char-classes, data constants, etc.)
#
# Only fires on repos that have an i18n setup (next-intl, react-intl, lingui).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking for hardcoded non-ASCII strings in i18n-enabled apps...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"

  # Detect i18n setup — fire only when one of these is present.
  has_i18n=0
  if grep -q "next-intl\|react-intl\|@lingui" "${REPO_PATH}/package.json" 2>/dev/null; then
    has_i18n=1
  fi
  if [[ "$has_i18n" -eq 0 ]]; then
    for app in "${REPO_PATH}"/apps/*/package.json; do
      [[ -f "$app" ]] || continue
      if grep -q "next-intl\|react-intl\|@lingui" "$app" 2>/dev/null; then
        has_i18n=1
        break
      fi
    done
  fi

  if [[ "$has_i18n" -eq 0 ]]; then
    skip "$repo" "i18n-leak" "no i18n library configured — pattern doesn't apply"
    continue
  fi

  # Build allowlist excludes for grep
  excludes=(
    --exclude-dir=node_modules
    --exclude-dir=.next
    --exclude-dir=dist
    --exclude-dir=.turbo
    --exclude-dir=generated
    --exclude-dir=messages
    --exclude-dir=locales
    --exclude-dir=i18n
    --exclude-dir=terms
    --exclude-dir=privacy
    --exclude-dir=contact
    --exclude-dir=policies
    --exclude-dir=legal
    --exclude-dir=content
    --exclude='*.test.ts'
    --exclude='*.test.tsx'
    --exclude='*.spec.ts'
    --exclude='*.spec.tsx'
    --exclude='seed*.ts'
    --exclude='mock*.ts'
    --exclude='preview-props.ts'
  )

  # Find non-ASCII in apps/*/src
  raw_offenders=()
  for app in "${REPO_PATH}"/apps/*/src; do
    [[ -d "$app" ]] || continue
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      raw_offenders+=("$line")
    done < <(LC_ALL=C grep -rEln $'[\x80-\xff]' "${excludes[@]}" --include='*.ts' --include='*.tsx' "$app" 2>/dev/null || true)
  done

  # Filter out files that opt out via `i18n-leak-allowed:` marker. Use it for
  # files where non-ASCII is legitimate (regex char-classes, data constants).
  offenders=()
  for f in "${raw_offenders[@]}"; do
    if ! grep -q "i18n-leak-allowed:" "$f" 2>/dev/null; then
      offenders+=("$f")
    fi
  done

  if [[ "${#offenders[@]}" -eq 0 ]]; then
    pass "$repo" "i18n-leak: no hardcoded non-ASCII strings in apps/*/src"
    continue
  fi

  count="${#offenders[@]}"
  example="${offenders[0]#${REPO_PATH}/}"
  fail "$repo" "i18n-leak" "$count file(s) with non-ASCII outside i18n bundles, e.g. $example"
done

summary
