---
name: verify-ci
description: Audit CI workflow files across all monorepos for runner, action, and permission consistency
user_invocable: true
---

# Verify CI

Audit GitHub Actions workflow consistency.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-ci.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. For each `FAIL`:
   - Read the workflow file in the failing repo
   - Read the equivalent workflow in acme
   - Show the diff and propose the fix

3. CI standards reference:
   - Runner: `blacksmith-4vcpu-ubuntu-2404`
   - Actions: `actions/checkout@v5`, `pnpm/action-setup@v4`, `actions/setup-node@v5`
   - Env: `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`
   - Permissions: `contents: read`
   - Install: `pnpm install --frozen-lockfile`
