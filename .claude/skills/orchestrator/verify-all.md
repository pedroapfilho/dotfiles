---
name: verify-all
description: Run all verification checks across the 4 monorepos (acme, localcine, collabtime, frow) to detect drift from shared standards
user_invocable: true
---

# Verify All Repos

Run all verification scripts against the monorepos.

## Steps

1. Run the verify-all script:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-all.sh
   ```
   Pass `--repo <name>` to scope to a single repo (acme, localcine, collabtime, frow).

2. Parse the output. For each `FAIL`:
   - Read the failing file in the repo
   - Read the equivalent file in acme (source of truth)
   - Explain what's different and why it matters
   - Propose the specific fix

3. For each `SKIP`:
   - Note the intentional divergence and its reason from `~/dev/dotfiles/orchestrator/divergences.json`

4. Present a summary with actionable next steps.

5. If the user approves fixes, apply them. After fixing, re-run the verifier to confirm.

## Context

- Acme is the source of truth for versions, CI, and lint config
- Read `~/dev/dotfiles/orchestrator/divergences.json` for intentional exceptions
- Read `~/dev/orchestrator/standards.md` for the full standards reference
