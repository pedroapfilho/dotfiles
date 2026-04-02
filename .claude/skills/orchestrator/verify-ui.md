---
name: verify-ui
description: Check UI patterns (forms, Tailwind prefix, cn(), Prisma config) across all monorepos
user_invocable: true
---

# Verify UI Patterns

Audit UI and form patterns.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-ui.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. Checks:
   - `@tanstack/react-form` used, not `react-hook-form`
   - `@repo/ui` uses `@import "tailwindcss" prefix(ui)`
   - `cn()` uses `extendTailwindMerge` with `experimentalParseClassName`
   - `prisma.config.ts` uses `process.env.DATABASE_URL ?? ""`
