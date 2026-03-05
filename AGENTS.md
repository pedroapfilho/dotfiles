# Dev Guidelines

## Core
- do what's asked, no more
- edit existing files; create new only if unavoidable
- no docs (`*.md`, README) unless asked
- use Context7 MCP for lib docs/setup automatically, don't wait to be asked

## TypeScript
- exports at end; arrow fns; `const` > `let`; `types` > `interfaces`
- naming: camelCase vars/fns, PascalCase types/classes, kebab-case files, MACRO_CASE constants
- event handlers prefixed with `handle` (handleClick, handleSubmit)
- no `as any`; type guards/zod over assertions; strict mode; zero TS/lint errors
- JSDoc for complex fns; WHY comments only, never WHAT
- `Promise.allSettled` > `Promise.all`
- no silent failures; error boundaries in React; handle async failures
- don't: overuse useEffect, prop drill, monolithic components, reinvent established patterns

## React & Performance
- `React.memo`/`useMemo`/`useCallback` to cut re-renders
- code splitting at route + component level; trim bundle sizes
- TanStack Query for caching; WebP + lazy-load images
- pick local vs global state consciously; normalize complex state; don't mutate state
- ARIA labels, keyboard nav, focus management; WCAG

## Cognitive Load
- extract complex conditionals into named variables; early returns over nested ifs
- composition > inheritance; deep modules (simple interface, rich impl) > shallow
- minimal language features; self-descriptive values; duplication is fine, bad abstractions aren't

## Security & Production
- sanitize inputs (client + server); auth/authz; HTTPS + CORS; escape XSS
- never expose/log/commit secrets
- env vars for config; Sentry; logging; CDN + cache headers
- unit tests for utils; integration tests for flows; test error states + edges; mock external deps

## Workflow
- plan before building; fragments not sentences; list open questions
- exact file/function names; file refs over copy-paste; clean git + meaningful commits
- clarify requirements before building
- don't ignore TS errors, lint errors, or skip planning

## Debugging
- find modified files; root cause; gather logs/traces; form hypotheses, test them

## Code Review
- check: security, N+1/re-renders, ARIA/contrast, edge cases, complexity
- check: separation of concerns, composition, abstraction levels, data flow

## Web UI

### Interactions
- full keyboard support (WAI-ARIA APG); `:focus-visible` rings; focus trap/return
- targets ≥24px (mobile ≥44px); mobile input font-size ≥16px; `touch-action: manipulation`
- don't disable zoom; don't block paste
- hydration-safe inputs; spinner on loading buttons (show-delay 150–300ms, min visible 300–500ms)
- Enter submits text input; ⌘/Ctrl+Enter submits textarea; validate after typing, not during
- submit enabled until request starts → disable + spinner + idempotency key
- inline errors; focus first error on submit; every control needs a `<label>`
- `autocomplete` + `name` + right `type`/`inputmode` on all inputs
- warn on unsaved changes; allow 2FA paste; trim whitespace
- URL = state (filters/tabs/pagination); Back/Forward restores scroll; navigation = `<a>`/`<Link>`
- confirm destructive actions or give Undo; `aria-live` for toasts

### Animation
- honor `prefers-reduced-motion`; only animate `transform`/`opacity` (no layout props)
- animations interruptible; right `transform-origin`; no `transition: all`; no autoplay

### Layout
- align to grid/baseline/optical on purpose; verify mobile + laptop + ultra-wide
- `env(safe-area-inset-*)`; fix overflows; `color-scheme: dark` on `<html>` for dark themes
- flex/grid > measuring in JS

### Content & Accessibility
- `…` not `...`; non-breaking spaces for units (`10&nbsp;MB`, `⌘&nbsp;+&nbsp;K`)
- locale-aware dates/numbers/currency; all states (empty/sparse/dense/error); no dead ends
- `aria-label` on icon-only buttons; `aria-hidden` on decorative; native semantics before ARIA
- no color-only status cues; skeletons mirror final layout; `<title>` = current context
- tabular numbers for comparisons; `scroll-margin-top` on headings; "Skip to content" link

### Performance
- batch layout reads/writes; mutations <500ms; virtualize large lists (`virtua`/`content-visibility: auto`)
- preload above-fold images; lazy-load rest; explicit image dimensions (no CLS)
- `<link rel="preconnect">` for CDN; preload critical fonts; Web Workers for expensive tasks

### Design
- APCA contrast over WCAG 2; increase contrast on `:hover`/`:active`/`:focus`
- `<meta name="theme-color">` = page background; color-blind-friendly palettes
- nested radii (child ≤ parent); layered shadows; hue-consistent borders/shadows/text

### Copywriting
- active voice; errors explain the fix, not just the problem; unambiguous labels
- placeholders: `YOUR_API_TOKEN_HERE` (strings), `0123456789` (numbers)
- numerals for counts; non-breaking space between number + unit

## Browser Automation
- `agent-browser open <url>` → `snapshot -i` → `click @e1`/`fill @e2 "text"` → re-snapshot
