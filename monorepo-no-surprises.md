# Monorepo No-Surprises Matrix

Use this as the quick audit list when starting or standardizing a repo.

## Root

| Item | Standard |
| --- | --- |
| Node pin | `.node-version` with `24` |
| Package manager | `pnpm` pinned in `packageManager` |
| Root package type | `"type": "module"` |
| Engine | `"engines": { "node": ">=24" }` |
| Workspace file | `pnpm-workspace.yaml` |
| Turbo file | `turbo.json` |
| Lint config | `.oxlintrc.json` |
| Format config | `.oxfmtrc.json` |

## Root Scripts

Required shared scripts:

- `start`
- `dev`
- `lint`
- `format`
- `format:check`
- `typecheck`
- `build`
- `clean`
- `db:generate`
- `db:push`
- `db:seed`

Rules:

- always use `turbo run ...`
- prefer `typecheck`, never `type-check`

## Turbo Tasks

Expected tasks:

- `build`
- `lint`
- `typecheck`
- `dev`
- `start`
- `clean`
- `format:check`
- `db:generate`
- `db:push`
- `db:seed`

Rules:

- `build`, `lint`, `typecheck` depend on `^build`
- `dev` is `persistent` and `cache: false`
- `start`, `clean`, `format:check`, and db tasks are `cache: false`

## Workspace Layout

Preferred folders:

- `apps/*`
- `packages/*`

Preferred app names:

- `web`
- `api`
- `landing`
- `workshop`
- `dashboard`

Preferred package names:

- `auth`
- `db`
- `ui`
- `core`
- `email`
- `i18n`
- `config-tailwind`
- `config-typescript`

## TypeScript

Preferred shared config package:

- folder: `packages/config-typescript`
- package name: `@repo/typescript-config`

Preferred shared configs:

- `base.json`
- `nextjs.json`
- `server.json`
- `library.json`
- `react-library.json`

## App Structure

### Next.js apps

- prefer `apps/web/src/app`
- keep env access centralized in `src/lib/env.ts` when env validation is needed
- app-local path alias can use `@/* -> src/*`

### ts-reset

Use only in apps, never in libraries.

Per app TS program:

- file path: `src/types/reset.d.ts`
- contents:

```ts
import "@total-typescript/ts-reset";
```

## Packages

### Source exports

For internal workspace packages, prefer source exports:

```json
{
  "exports": {
    ".": "./src/index.ts"
  }
}
```

Rules:

- include `src/**` in `files`
- do not point internal-only packages at `dist/*`
- never use `@/` imports inside `packages/*`; use relative imports only

### tsdown

Prefer:

- `tsdown.config.ts`
- no long CLI arg strings in `package.json`

Rules:

- UI packages: `clean: false` when CSS is built separately
- Node packages: `platform: "node"`
- browser/shared UI: externalize React runtime deps
- if a Node API consumes source-exported `@repo/*` packages, bundle those internal deps in the API build

## Auth

Preferred better-auth shape:

- `packages/auth/src/server.ts`
- `packages/auth/src/client.ts`
- factory pattern via `createAuth`
- `extraPlugins` typed explicitly
- plugin subpath imports
- `rateLimit.storage: "database"`
- `nextCookies()` passed at Next.js call sites when needed

## Lint / Format

Preferred tooling:

- `oxlint`
- `oxfmt`

Preferred config files:

- `.oxlintrc.json`
- `.oxfmtrc.json`

Shared ignore baseline:

- `.next/**`
- `dist/**`
- `build/**`
- `coverage/**`
- `node_modules/**`
- `**/generated/**`
- `next-env.d.ts`

Expected targeted overrides:

- tests
- seed files
- shadcn/Radix UI package code
- app-only legacy zones where strict style rules would cause churn without product value

## Naming

Rules:

- files and directories use kebab-case
- allow framework exceptions like `page.tsx`, `layout.tsx`, `[id]`
- prefer JSON config files for Ox tools

## Cross-Repo Rule

When one repo needs a structural fix, audit the others and align them unless there is a clear product-specific reason not to.
