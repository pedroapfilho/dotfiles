---
name: sync-repos
description: Propagate a config or version change from acme to all downstream monorepos (localcine, collabtime, frow)
user_invocable: true
---

# Sync Repos

Propagate changes from acme (source of truth) to downstream repos.

## Steps

1. Identify what changed in acme. The user will tell you, or you can run a verify script to find drift.

2. For each downstream repo (localcine, collabtime, frow):
   a. Check `~/dev/dotfiles/orchestrator/divergences.json` — skip if the change conflicts with an intentional divergence
   b. Apply the same change
   c. Run `pnpm install` if dependencies changed
   d. Run `pnpm lint && pnpm test && pnpm format:check` to validate
   e. Commit with a descriptive message

3. If the user wants PRs, create them on each repo using `gh pr create`.

4. Report results: which repos were updated, which were skipped (with reason), and any failures.

## Important

- Never overwrite intentional divergences without asking
- Always validate with lint + test before committing
- Acme is always the source — never sync in the other direction
- Read `~/dev/orchestrator/standards.md` for the full standards reference
