# Monorepo Standards

Standards enforced across all maintained monorepos. Acme is the template — update acme first, then propagate.

## Registry

| Repo | Path | Auth | Notes |
|------|------|------|-------|
| acme-monorepo | `~/dev/acme-monorepo` | Better Auth | Template. Source of truth. |
| localcine-monorepo | `~/dev/localcine-monorepo` | Better Auth | Live. i18n, Sentry, PostHog. |
| collabtime-monorepo | `~/dev/collabtime-monorepo` | Better Auth + Stripe | Launching. Upstash Realtime. |
| frow-monorepo | `~/dev/frow-monorepo` | Better Auth + Stripe | Launching. Hono API, BullMQ, AI/audio. |

## Tooling

| Tool | Standard | Config |
|------|----------|--------|
| Package manager | pnpm (latest 10.x) | `packageManager` field in root `package.json` |
| Build orchestrator | Turborepo (latest 2.x) | `turbo.json` |
| Node | 24 | `.node-version` |
| Linter | oxlint + `oxlint-config-awesomeness` | `.oxlintrc.json` |
| Formatter | oxfmt | `.oxfmtrc.json` |
| Pre-commit | Husky + lint-staged | `.husky/pre-commit` runs `pnpm lint-staged` |
| lint-staged | oxlint on `.ts,.tsx,.js,.jsx` + oxfmt on `.ts,.tsx,.js,.jsx,.json,.md` | Root `package.json` |
| Unit tests | Vitest | `@repo/config-vitest` with `react.ts` and `node.ts` configs |
| E2E tests | Playwright (chromium, firefox, webkit) | `playwright.config.ts` at root |
| Bundler (libs) | tsdown | Per-package `tsdown.config.ts` |
| Bundler (Next.js) | Turbopack | `next dev --turbopack` |

## Dev Environment

### Portless

Proxy runs on port 443 (HTTPS, clean URLs). Start with `portless proxy start` (requires sudo).

All dev scripts use `portless run --name <project>.<app>`.

| Pattern | URL |
|---------|-----|
| Main worktree | `https://<project>.<app>.localhost` |
| Git worktree on branch `fix-ui` | `https://fix-ui.<project>.<app>.localhost` |

Every Next.js app must have `allowedDevOrigins: ["<project>.<app>.localhost"]` in `next.config.ts`.

### Docker

Every repo has a `docker-compose.yml` with `name: <project>` (no `-monorepo` suffix).

| Repo | Services |
|------|----------|
| acme | Postgres 18 |
| localcine | MySQL 8 + MeiliSearch |
| collabtime | Postgres 18 + Redis + Redis REST |
| frow | Postgres + Redis |

Start with `docker compose up -d`. Stop with `docker compose stop`. Only run one project at a time (port conflicts on 5432/6379).

### Dev-Only Tools

- **React Scan** — `<script>` in root layout, gated by `NODE_ENV === "development"`
- **React Grab** — `<script>` in root layout, gated by `NODE_ENV === "development"`

## Package Architecture

### Shared Packages (all repos)

| Package | Purpose |
|---------|---------|
| `@repo/ui` | React component library. Tailwind `ui:` prefix. `cn()` with `experimentalParseClassName`. |
| `@repo/db` | Prisma client + schema. |
| `@repo/auth` | Auth config (Better Auth). |
| `@repo/config-typescript` | Shared `tsconfig` bases: `base.json`, `nextjs.json`, `server.json`, `library.json`. |
| `@repo/config-tailwind` | Shared Tailwind config + `shared-styles.css`. |
| `@repo/config-vitest` | Shared Vitest configs: `react.ts` (jsdom + RTL) and `node.ts`. |

### TypeScript

- Strict mode, ESNext target, Bundler module resolution, `noEmit`
- Path alias: `@/*` → `src/*` (no leading `./`)

### Tailwind CSS v4

- `@repo/ui` uses `@import "tailwindcss" prefix(ui)` — all classes inside the package are `ui:` prefixed
- Consumer apps use unprefixed classes
- `cn()` uses `extendTailwindMerge` with `experimentalParseClassName` to strip `ui:` prefix during merge

## Forms

- **@tanstack/react-form** (NOT react-hook-form)
- Validators: `{ onBlur: schema, onChange: schema }` — validate on blur, clear on fix
- Error display: `field.state.meta.isTouched && !field.state.meta.isValid`
- Field components from `@repo/ui`: `Field`, `FieldGroup`, `FieldLabel`, `FieldError`, `FieldDescription`
- `defaultValues` as separate typed object: `const defaultValues: FormValues = { ... }`
- Forms must have `noValidate` and `e.stopPropagation()` on submit
- NEVER use `field.handleChange` in `useEffect`/`useCallback` with `field` in deps — use `field.form.setFieldValue(field.name, value)`
- NEVER wrap validators in `safeParse` — pass schema directly
- Use `form.useStore()` instead of `useState` for form-derived state

## CI (GitHub Actions)

### Runners

All workflows use `blacksmith-4vcpu-ubuntu-2404`.

### Workflows

| File | Purpose | Command |
|------|---------|---------|
| `test.yml` | Unit tests | `pnpm test` |
| `e2e.yml` | E2E tests | `pnpm test:e2e` (with Postgres service, Playwright cache) |
| `lint.yml` | Linting | `pnpm oxlint --format=github .` |
| `format.yml` | Formatting | `pnpm run format:check` |

### Standard Pattern

```yaml
permissions:
  contents: read

jobs:
  <job>:
    runs-on: blacksmith-4vcpu-ubuntu-2404
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
    steps:
      - uses: actions/checkout@v5
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v5
        with:
          node-version: lts/*
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: <command>
```

### E2E Workflow Additions

- Postgres 16 service container
- `pnpm db:generate` + `pnpm db:push` + `pnpm build` before tests
- Playwright browser caching via `actions/cache@v4`
- Report artifact upload (`playwright-report/`, 14 days retention)
- Reporter: `[["html", { open: "never" }]]` in CI, `[["list"], ["html"]]` locally
- Retries: 2 in CI, 0 locally

## E2E Test Patterns

### Structure

```
tests/e2e/
  setup/auth.setup.ts       # Create test user, save storageState
  teardown/cleanup.ts        # Delete test user + data
  fixtures/auth.fixture.ts   # Page object fixtures
  pages/*.page.ts            # Page Object Models
  auth/*.spec.ts             # Auth flow tests
  <feature>/*.spec.ts        # Feature tests
```

### Fixture Pattern

```ts
const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
});
export { test };
export { expect } from "@playwright/test";
```

### Page Object Pattern

- Private locators, arrow function methods
- Use `getByRole`, `getByLabel`, `getByText` (never `getByTestId` unless necessary)
- Expose assertion methods for error/success states

### Playwright Config

- Portless integration with fallback URLs for CI
- `storageState: "tests/e2e/.auth/user.json"`
- 3 browser projects depending on `setup` project
- oxlintrc override for `**/*.fixture.ts` and `**/*.setup.ts` (disable `rules-of-hooks`)

## Prisma

- `prisma.config.ts` uses `process.env.DATABASE_URL ?? ""` (not `env("DATABASE_URL")`)
- This allows `prisma generate` to succeed in CI without database credentials

## Root Scripts

```
start, dev, lint, format, format:check, typecheck, build, clean,
test, test:e2e, test:e2e:ui,
db:generate, db:push, db:seed,
prepare
```

## React Best Practices

Performance patterns enforced across all repos, based on Vercel's React Best Practices guidelines.

### Eliminating Waterfalls (CRITICAL)

- **Parallelize independent async calls** — use `Promise.allSettled` for independent fetches in server components and server actions
- **Cheap sync before async** — run Zod validation, null checks, and other sync logic BEFORE expensive async calls (auth, DB queries)
- **Don't block responses** — use `after()` from `next/server` or `Promise.all` for side effects like realtime broadcasts, email sending, analytics

### Bundle Size (CRITICAL)

- **No `"use client"` on barrel files** — add `"use client"` to individual components that need it, not the barrel `index.ts`
- **`optimizePackageImports`** — add `["@repo/ui"]` (and `"@repo/core"` if applicable) to `next.config.ts` experimental config
- **Lazy-load heavy components** — use `next/dynamic` with `{ ssr: false }` for components only shown on interaction (modals, DnD) or conditionally (waveform, animations)
- **Defer third-party scripts** — analytics, monitoring, and logging should load after hydration, not at startup

### Server Performance (HIGH)

- **Auth in server actions** — every `"use server"` function exposed to the client must verify authentication
- **`React.cache()` for session** — wrap `auth.api.getSession` in `React.cache()` to deduplicate across layout + page in the same request
- **Minimize serialization** — don't pass full objects as RSC props when only a few fields are needed
- **Stable QueryClient** — wrap in `useState(() => new QueryClient())`, never create on every render

### Re-renders (MEDIUM)

- **No barrel imports for hooks** — import from specific files (`@/hooks/use-vote`, not `@/hooks`)
- **Delete barrel files** when only one consumer exists
- **No inline component definitions** — don't define components inside other components

## Breaking Change Patterns

| Library | Gotcha |
|---------|--------|
| Sentry | Deprecated options (`disableLogger`, `automaticVercelMonitors`) — remove if using Turbopack |
| Stripe | Uses `export default Stripe`, not named export |
| Prisma | Major bumps regenerate client — run `pnpm install` to trigger `postinstall` |
| @tanstack/react-form | `field` object is unstable — never use in effect deps |
