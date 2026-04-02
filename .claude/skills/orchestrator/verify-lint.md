---
name: verify-lint
description: Check oxlint and oxfmt configuration consistency across all monorepos
user_invocable: true
---

# Verify Lint

Audit linting and formatting configuration.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-lint.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. For `SKIP` items (e.g., frow's sort rules), explain the intentional divergence.

3. For `FAIL` items:
   - Compare `.oxlintrc.json` / `.oxfmtrc.json` against acme
   - Check `lint-staged` config in root `package.json`
   - Propose specific fixes

4. Watch for legacy configs (`.eslintrc*`, `.prettierrc*`) that should be deleted.
