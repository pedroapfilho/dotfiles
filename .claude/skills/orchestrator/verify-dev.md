---
name: verify-dev
description: Check dev environment setup (portless, allowedDevOrigins, husky) across all monorepos
user_invocable: true
---

# Verify Dev Environment

Audit development environment configuration.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-dev.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. Checks:
   - App dev scripts use `portless run --name <project>.<app>`
   - Next.js apps have `allowedDevOrigins` in `next.config.ts`
   - Husky pre-commit runs `lint-staged`

3. URL pattern: `http://<project>.<app>.localhost:1355`
