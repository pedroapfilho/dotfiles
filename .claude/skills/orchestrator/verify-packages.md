---
name: verify-packages
description: Verify shared package architecture (ui, db, config-*) exists and follows patterns across all monorepos
user_invocable: true
---

# Verify Packages

Audit shared package architecture.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-packages.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. Required packages: `ui`, `db`, `config-typescript`, `config-tailwind`, `config-vitest`.

3. `config-vitest` must export both `react.ts` and `node.ts` configs.

4. `config-typescript` must have `base.json` and `nextjs.json`.

5. Flag vestigial packages like `config-eslint` (unless registered in divergences.json).
