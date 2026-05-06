#!/usr/bin/env bash
# Verify the fleet uses the canonical shadcn link-as-button pattern.
#
# Wrong pattern (Base UI's role=button clobbers <a>'s semantic link role):
#     <Button render={<Link href="..."/>}>label</Button>
#
# Canonical pattern (acme 589d738; landed in collabtime, localcine, frow,
# easeia after):
#     <Link className={buttonVariants({size, variant})} href="...">label</Link>
#
# Two checks per repo:
#   1. apps/*/src has zero `<Button render={<` callsites.
#   2. packages/ui/src/components/button.tsx wrapper does NOT destructure
#      `render` or pass `nativeButton={!render}` — i.e. it stays minimal
#      and just spreads `...props`. Per the Apr-28 fleet revert, that
#      derivation was removed because it didn't fix the role-clobber bug.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking link-as-button uses canonical buttonVariants pattern...${RESET}\n\n"

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  BTN="${REPO_PATH}/packages/ui/src/components/button.tsx"

  # Check 1: button.tsx wrapper stays minimal
  if [[ -f "$BTN" ]]; then
    if grep -qE "nativeButton=\{!render\}|^\s+render,\s*$" "$BTN"; then
      fail "$repo" "button-native-prop" "Button wrapper destructures \`render\` or sets \`nativeButton={!render}\` — this was reverted fleet-wide; consumers should render <Link className={buttonVariants(...)}> directly"
      continue
    fi
  fi

  # Check 2: no <Button render={<…> callsites. Multi-line tolerant — the
  # JSX render prop often spans several lines, so a single-line grep misses
  # them. Walk every .tsx/.ts in apps/ via perl with /s + whitespace before <.
  files=$(find "${REPO_PATH}/apps" -type f \( -name "*.tsx" -o -name "*.ts" \) \
    -not -path "*/node_modules/*" -not -path "*/.next/*" \
    -not -path "*/.turbo/*" -not -path "*/dist/*" 2>/dev/null)

  callsites=""
  if [[ -n "$files" ]]; then
    callsites=$(echo "$files" | xargs -I{} perl -e '
      my $f = shift;
      open my $fh, "<", $f or exit;
      local $/;
      my $c = <$fh>;
      close $fh;
      print "$f\n" if $c =~ m{<Button[^>]{0,500}?render=\{\s*<}s;
    ' {} 2>/dev/null)
  fi

  if [[ -z "$callsites" ]]; then
    pass "$repo" "no <Button render={<…/>}> callsites; wrapper minimal"
  else
    count=$(echo "$callsites" | wc -l | tr -d ' ')
    example=$(echo "$callsites" | head -1 | sed "s|${REPO_PATH}/||")
    if has_divergence "$repo" "ui" "button-render-callsite"; then
      skip "$repo" "button-render-callsite" "divergence"
    else
      fail "$repo" "button-render-callsite" "$count file(s) use <Button render={<…/>}>; convert to <Link className={buttonVariants(...)}>, e.g. $example"
    fi
  fi
done

summary
