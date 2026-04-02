---
name: verify-versions
description: Check that tooling versions (pnpm, turbo, oxlint, etc.) match acme across all monorepos
user_invocable: true
---

# Verify Versions

Check tooling version alignment across all monorepos.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-versions.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. For each `FAIL`, compare the version in the failing repo against acme's `package.json`.

3. Propose version bumps. When fixing:
   - Update the version in `package.json`
   - Run `pnpm install` to update the lockfile
   - Run `pnpm lint && pnpm test` to validate
   - Commit with message: `chore: align <package> version with acme (<old> → <new>)`
