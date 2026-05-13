#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/divergences.sh"

parse_repo_flag "$@"

printf "${BOLD}Checking CI workflows...${RESET}\n\n"

REQUIRED_WORKFLOWS=("test.yml" "lint.yml" "format.yml" "fallow.yml" "e2e.yml")
EXPECTED_RUNNER="ubuntu-latest"
EXPECTED_NODE_VERSION="24"
EXPECTED_ACTIONS=("actions/checkout@v5" "pnpm/action-setup@v4" "actions/setup-node@v5")

for repo in "${SCOPED_REPOS[@]}"; do
  REPO_PATH="$(repo_path "$repo")"
  WORKFLOWS_DIR="${REPO_PATH}/.github/workflows"

  # Skip the whole repo if `.github/workflows/` doesn't exist — that's the
  # signal that the repo intentionally opted out of GH Actions CI (e.g. acme
  # moved off GH Actions runners). Per-workflow checks below would otherwise
  # flood the report with file-not-found.
  if [[ ! -d "$WORKFLOWS_DIR" ]]; then
    skip "$repo" "no .github/workflows/ — repo opted out of GH Actions CI"
    continue
  fi

  # Check required workflow files exist
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    if [[ -f "${WORKFLOWS_DIR}/${wf}" ]]; then
      pass "$repo" "workflow ${wf} exists"
    else
      fail "$repo" "workflow ${wf}" "file not found"
      continue
    fi
  done

  # Check runner across all workflows
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    if grep -q "$EXPECTED_RUNNER" "$wf_path"; then
      pass "$repo" "${wf} runner ($EXPECTED_RUNNER)"
    else
      actual=$(grep "runs-on:" "$wf_path" | head -1 | sed 's/.*runs-on:\s*//' | tr -d ' ')
      fail "$repo" "${wf} runner" "expected $EXPECTED_RUNNER, got $actual"
    fi
  done

  # Check node-version pinned to expected version (matches local)
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    if grep -qE "node-version:\s*[\"']?${EXPECTED_NODE_VERSION}[\"']?\s*$" "$wf_path"; then
      pass "$repo" "${wf} node-version: ${EXPECTED_NODE_VERSION}"
    else
      actual=$(grep "node-version:" "$wf_path" | head -1 | sed 's/.*node-version:\s*//' | tr -d ' ')
      fail "$repo" "${wf} node-version" "expected ${EXPECTED_NODE_VERSION}, got ${actual:-unset}"
    fi
  done

  # Check FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 — forces built-in JS actions
  # (checkout, setup-node, etc.) to run on Node 24 instead of the action's
  # declared runtime. Pairs with node-version above to keep runner node
  # entirely on 24, matching local.
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    if grep -q "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true" "$wf_path"; then
      pass "$repo" "${wf} FORCE_JAVASCRIPT_ACTIONS_TO_NODE24"
    else
      fail "$repo" "${wf} FORCE_JAVASCRIPT_ACTIONS_TO_NODE24" "not set"
    fi
  done

  # Check action versions in non-e2e workflows
  for wf in "test.yml" "lint.yml" "format.yml" "fallow.yml"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    for action in "${EXPECTED_ACTIONS[@]}"; do
      if grep -q "$action" "$wf_path"; then
        pass "$repo" "${wf} uses ${action}"
      else
        fail "$repo" "${wf} uses ${action}" "not found"
      fi
    done
  done

  # Check permissions
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    if grep -q "contents: read" "$wf_path"; then
      pass "$repo" "${wf} permissions: contents: read"
    else
      fail "$repo" "${wf} permissions" "contents: read not set"
    fi
  done

  # Check frozen-lockfile
  for wf in "${REQUIRED_WORKFLOWS[@]}"; do
    wf_path="${WORKFLOWS_DIR}/${wf}"
    [[ ! -f "$wf_path" ]] && continue

    if grep -q "\-\-frozen-lockfile" "$wf_path"; then
      pass "$repo" "${wf} --frozen-lockfile"
    else
      fail "$repo" "${wf} --frozen-lockfile" "pnpm install missing --frozen-lockfile"
    fi
  done
done

summary
