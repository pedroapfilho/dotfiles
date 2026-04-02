---
name: verify-e2e
description: Check E2E test structure (Playwright config, fixtures, page objects) across all monorepos
user_invocable: true
---

# Verify E2E

Audit Playwright E2E test patterns.

## Steps

1. Run:
   ```bash
   ~/dev/dotfiles/orchestrator/scripts/verify-e2e.sh
   ```
   Pass `--repo <name>` to scope to a single repo.

2. Expected structure:
   ```
   tests/e2e/
     setup/auth.setup.ts
     teardown/cleanup.ts (or globalSetup)
     fixtures/auth.fixture.ts
     pages/*.page.ts
   ```

3. Patterns to verify:
   - Fixtures use `base.extend<Fixtures>`
   - Page objects use private locators, arrow function methods
   - `storageState` configured in playwright.config.ts
   - Global setup or teardown configured
