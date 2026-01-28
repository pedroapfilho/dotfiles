# Comprehensive Development Guidelines

This document contains mandatory and recommended guidelines for software development. All team members MUST follow these standards.

---

## 1. Fundamental Instructions

**Scope & Execution**
- MUST: Do what has been asked; nothing more, nothing less
- MUST: Always prefer editing an existing file over creating a new one
- NEVER: Create files unless absolutely necessary for achieving the goal
- NEVER: Proactively create documentation files (`*.md`, `README`, etc.) unless explicitly requested
- MUST: Use context7 when I need code generation, setup or configuration steps, or library/api documentation. This means you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to explicitly ask.

---

## 2. JavaScript/TypeScript Standards

### 2.1 Core Principles

**Code Organization**
- MUST: Add exports at the end of the file, not inline
- MUST: Use arrow functions instead of function expressions
- MUST: Prefer `const` over `let`
- MUST: Prefer `types` over `interfaces`
- MUST: Use camelCase for variables/functions, PascalCase for types/classes, kebab-case for file names, MACRO_CASE for constants
- SHOULD: Use dynamic imports only when necessary for lazy loading

**Type Safety**
- MUST: Fix type issues instead of using `as any`
- MUST: Use type guards or type narrowing (e.g., `zod`) instead of type assertions (`as` keyword)
- MUST: Leverage TypeScript's strict mode for enhanced type checking
- NEVER: Leave TypeScript errors or linting errors unresolved

**Comments & Documentation**
- MUST: Use JSDoc comments for complex functions and types
- MUST: Write only "WHY" comments explaining motivation, not "WHAT" comments that duplicate code
- NEVER: Add unnecessary comments about process or implementation details

**Async Operations**
- MUST: Use `Promise.allSettled` instead of `Promise.all`

### 2.2 Naming Conventions

- MUST: Use descriptive names for variables and functions
- MUST: Prefix event handler functions with "handle" (e.g., `handleClick`, `handleSubmit`)
- MUST: Focus on simplicity, readability, performance, maintainability, and testability

### 2.3 Error Handling

- MUST: Use explicit error handling—no silent failures
- MUST: Implement proper error boundaries in React components
- MUST: Handle async operation failures gracefully
- SHOULD: Use Result patterns or custom error types for better error management

### 2.4 Anti-Patterns to Avoid

- NEVER: Overuse `useEffect` or create dependency hell
- NEVER: Implement prop drilling instead of proper state management
- NEVER: Create monolithic components instead of composable ones
- NEVER: Ignore proper error boundaries and error handling
- NEVER: Implement custom solutions for well-established patterns
- MUST: Consider mobile responsiveness from the start

---

## 3. Frontend Development

### 3.1 React Best Practices

**Performance Optimization**
- MUST: Optimize component rendering using `React.memo`, `useMemo`, `useCallback`
- MUST: Avoid unnecessary re-renders through proper dependency arrays
- MUST: Use compound components pattern for complex UI components
- SHOULD: Lazy load components and routes when appropriate
- SHOULD: Implement proper prop drilling solutions (Context, state management)

### 3.2 Performance Optimization

**Code & Bundle**
- MUST: Implement code splitting at route and component levels
- MUST: Optimize bundle sizes—analyze and eliminate unused dependencies
- MUST: Use efficient data structures and algorithms

**Assets & Caching**
- MUST: Implement proper caching strategies (e.g., Tanstack Query)
- MUST: Optimize images and assets (WebP, lazy loading, proper sizing)

### 3.3 State Management

- MUST: Choose appropriate state management solutions (local vs global state)
- MUST: Implement proper data normalization for complex state
- MUST: Use proper loading and error states for async operations
- NEVER: Mutate state—always return new objects/arrays

### 3.4 Accessibility

- MUST: Ensure proper ARIA labels, keyboard navigation, color contrast
- MUST: Test with screen readers and keyboard navigation
- MUST: Implement proper focus management
- MUST: Follow WCAG guidelines for accessibility compliance

---

## 4. Cognitive Load Management

**Philosophy**: Write code for human brains, not machines. The brain can only hold ~4 chunks in working memory at once.

### 4.1 Readability Principles

**Conditionals & Logic**
- MUST: Extract complex expressions into intermediate variables with meaningful names
- MUST: Prefer early returns over nested ifs to reduce cognitive load
- MUST: Make conditionals readable

**Example: Poor**
```ts
if (val > someConstant && (condition2 || condition3) && (condition4 && !condition5)) {
    // Human memory overload
}
```

**Example: Good**
```ts
const isValid = val > someConstant;
const isAllowed = condition2 || condition3;
const isSecure = condition4 && !condition5;

if (isValid && isAllowed && isSecure) {
    // Clean working memory
}
```

### 4.2 Architecture Principles

**Composition & Abstraction**
- MUST: Prefer composition over deep inheritance
- MUST: Prefer deep methods/classes/modules (simple interface, complex functionality) over shallow ones
- NEVER: Write shallow methods/classes/modules (complex interface, simple functionality)
- NEVER: Force readers to chase behavior across multiple classes

**Language & Dependencies**
- MUST: Stick to minimal language feature subset
- MUST: Use self-descriptive values; avoid custom mappings requiring memorization
- SHOULD: Accept small duplication over unnecessary dependencies (don't abuse DRY)
- SHOULD: Avoid unnecessary layers of abstraction

---

## 5. Security & Production

### 5.1 Security Practices

**Input & Validation**
- MUST: Sanitize all user inputs and validate on both client and server
- MUST: Implement proper authentication and authorization checks
- MUST: Use HTTPS everywhere and implement proper CORS policies
- MUST: Avoid XSS vulnerabilities through proper data escaping

**Secrets & Keys**
- NEVER: Introduce code that exposes or logs secrets and keys
- NEVER: Commit secrets or keys to the repository
- MUST: Follow security best practices

**Error Handling**
- MUST: Implement proper error handling that doesn't leak sensitive information

### 5.2 Production Considerations

- MUST: Implement proper logging and monitoring
- MUST: Use environment variables for configuration
- MUST: Implement proper error tracking (e.g., Sentry)
- MUST: Use proper build optimization and minification
- MUST: Implement proper caching headers and CDN usage

### 5.3 Testing Strategy

- MUST: Write comprehensive unit tests for utility functions
- MUST: Implement integration tests for complex user flows
- MUST: Test error states and edge cases thoroughly
- MUST: Use proper mocking strategies for external dependencies
- SHOULD: Use visual regression testing for UI components

---

## 6. Workflow & Project Management

### 6.1 Planning & Architecture

- MUST: Always start with a written plan for any feature
- MUST: Break down complex features into smaller, testable components
- SHOULD: Draft a Markdown plan, critique it for gaps, then regenerate an improved version

### 6.2 Context Management

**Prompt Engineering**
- MUST: Keep prompts laser-focused and specific
- MUST: Use exact identifiers from the codebase, not generic terms
- MUST: Reference specific files/functions using exact names
- SHOULD: Ask for step-by-step reasoning before implementation

**File Organization**
- MUST: Use file references (e.g., `@src/components/Button.tsx`) instead of copy-pasting
- MUST: Maintain clean git state with frequent, meaningful commits
- MUST: Use descriptive commit messages that explain the "why"
- SHOULD: Re-index project context after major refactoring

### 6.3 Development Process

- MUST: Write a detailed plan with acceptance criteria before implementation
- MUST: Build features incrementally and test at each step
- MUST: Conduct thorough code review with security/performance lens

### 6.4 Communication & Collaboration

**Requirements**
- MUST: Clarify ambiguous requirements before implementation
- MUST: Ask specific questions about user experience expectations

**Documentation**
- MUST: Document complex business logic and algorithms
- MUST: Maintain up-to-date README files with setup instructions

### 6.5 Continuous Improvement

- MUST: Refactor code regularly to maintain quality
- SHOULD: Stay current with frontend ecosystem changes and best practices

### 6.6 Anti-Patterns

- NEVER: Expect mind-reading about implicit requirements
- NEVER: Implement features without proper planning
- NEVER: Ignore TypeScript errors or warnings
- NEVER: Ignore linting errors or warnings

---

## 7. Debugging & Diagnostics

### 7.1 Systematic Debugging

**When Stuck:**
- MUST: Identify files modified in the current session
- MUST: Understand the role of each file in the feature
- MUST: Perform root cause analysis of current issues
- MUST: Consider multiple debugging approaches before proceeding

### 7.2 Development Tools

- MUST: Use proper debugging tools (React DevTools, Redux DevTools)
- MUST: Implement proper development vs production builds
- MUST: Use proper source maps for debugging
- SHOULD: Implement comprehensive logging in development

### 7.3 Debugging Workflow

- MUST: Identify the issue precisely before attempting fixes
- MUST: Gather all relevant information (logs, stack traces, reproduction steps)
- MUST: Form hypotheses about the cause based on evidence
- MUST: Test each hypothesis systematically
- SHOULD: Document the solution for future reference

---

## 8. Code Review Standards

### 8.1 Review Checklist

- MUST: **Security** — Check for vulnerabilities, input validation, proper authentication
- MUST: **Performance** — Look for N+1 problems, unnecessary re-renders, algorithm complexity
- MUST: **Accessibility** — Ensure proper ARIA labels, keyboard navigation, color contrast
- MUST: **Correctness** — Test edge cases, verify error handling, check business logic
- MUST: **Maintainability** — Assess code complexity, documentation, and testability

### 8.2 Architecture Review

- MUST: Ensure proper separation of concerns
- MUST: Verify component composition and reusability
- MUST: Check for proper abstraction levels
- MUST: Validate data flow and state management decisions

### 8.3 Review Process

- MUST: Understand the context and requirements before reviewing
- MUST: Check for functional correctness
- MUST: Evaluate code quality and maintainability
- MUST: Verify security and performance considerations
- MUST: Provide constructive feedback with specific examples

### 8.4 What to Look For

- MUST: Consistent code style and conventions
- MUST: Proper error handling and edge cases
- MUST: Efficient algorithms and data structures
- MUST: Clear variable and function names
- MUST: Appropriate use of design patterns
- MUST: Test coverage and quality

---

## 9. Web Interface Guidelines

### 9.1 Interactions

**Keyboard**
- MUST: Provide full keyboard support per [WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/)
- MUST: Show visible focus rings (`:focus-visible`; group with `:focus-within`)
- MUST: Manage focus (trap, move, return) per APG patterns
- SHOULD: Internationalize keyboard shortcuts for non-QWERTY layouts; show platform-specific symbols

**Targets & Input**
- MUST: Hit targets ≥24px (mobile ≥44px); if visual <24px, expand hit area
- MUST: Mobile `<input>` font-size ≥16px or set:
  ```html
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
  ```
- MUST: Use `touch-action: manipulation` to prevent double-tap zoom
- MUST: Set `-webkit-tap-highlight-color` to match design
- NEVER: Disable browser zoom

**Inputs & Forms (Behavior)**
- MUST: Use hydration-safe inputs (no lost focus/value)
- MUST: Show spinner on loading buttons and keep original label
- MUST: Add show-delay (~150–300ms) and minimum visible time (~300–500ms) for spinners/skeletons to avoid flicker
- MUST: Enter submits focused text input; in `<textarea>`, ⌘/Ctrl+Enter submits, Enter adds newline
- MUST: Keep submit enabled until request starts; then disable, show spinner, use idempotency key
- MUST: Accept free text and validate after—don't block typing
- MUST: Allow submitting incomplete forms to surface validation
- MUST: Show errors inline next to fields; on submit, focus first error
- MUST: Use `autocomplete` + meaningful `name`; correct `type` and `inputmode`
- MUST: Every control has a `<label>` or is associated with one for assistive tech
- MUST: Clicking a `<label>` focuses the associated control
- MUST: Warn on unsaved changes before navigation
- MUST: Be compatible with password managers & 2FA; allow pasting one-time codes
- MUST: Trim values to handle text expansion trailing spaces
- MUST: No dead zones on checkboxes/radios—label+control share one generous hit target
- MUST: On Windows, explicitly set `background-color` and `color` on native `<select>` for dark-mode
- NEVER: Block paste in `<input>`/`<textarea>`
- NEVER: Trigger password managers for non-auth fields—use `autocomplete="off"` for search, etc.
- SHOULD: Disable spellcheck for emails/codes/usernames
- SHOULD: Placeholders end with ellipsis and show example pattern (e.g., `+1 (123) 456-7890`, `sk-012345…`)

**State & Navigation**
- MUST: URL reflects state (deep-link filters/tabs/pagination/expanded panels); prefer libs like [nuqs](https://nuqs.47ng.com/)
- MUST: Back/Forward restores scroll
- MUST: Links are links—use `<a>`/`<Link>` for navigation (support Cmd/Ctrl/middle-click)

**Feedback**
- MUST: Confirm destructive actions or provide Undo window
- MUST: Use polite `aria-live` for toasts/inline validation
- SHOULD: Optimistic UI; reconcile on response; on failure show error and rollback or offer Undo
- SHOULD: Ellipsis (`…`) for options that open follow-ups (e.g., "Rename…")

**Touch/Drag/Scroll**
- MUST: Design forgiving interactions (generous targets, clear affordances)
- MUST: Delay first tooltip in a group; subsequent peers have no delay
- MUST: Use intentional `overscroll-behavior: contain` in modals/drawers
- MUST: During drag, disable text selection and set `inert` on dragged element/containers
- MUST: No "dead-looking" interactive zones—if it looks clickable, it is

**Autofocus**
- SHOULD: Autofocus on desktop when there's a single primary input
- SHOULD: Rarely autofocus on mobile (to avoid layout shift)

### 9.2 Animation

- MUST: Honor `prefers-reduced-motion` (provide reduced variant)
- MUST: Animate compositor-friendly props (`transform`, `opacity`); avoid layout/repaint props (`top`/`left`/`width`/`height`)
- MUST: Animations are interruptible and input-driven
- MUST: Use correct `transform-origin` (motion starts where it "physically" should)
- MUST: Apply CSS transforms/animations to `<g>` wrappers for SVG; set `transform-box: fill-box; transform-origin: center;`
- SHOULD: Prefer CSS > Web Animations API > JS libraries
- SHOULD: Animate only to clarify cause/effect or add deliberate delight
- SHOULD: Choose easing to match the change (size/distance/trigger)
- SHOULD: Animate wrappers instead of text nodes to avoid anti-aliasing artifacts; use `translateZ(0)` if needed
- NEVER: Use autoplay animations
- NEVER: Use `transition: all`—explicitly list only intended properties (`opacity`, `transform`)

### 9.3 Layout

- MUST: Use deliberate alignment to grid/baseline/edges/optical centers—no accidental placement
- MUST: Verify layouts on mobile, laptop, and ultra-wide (simulate ultra-wide at 50% zoom)
- MUST: Respect safe areas (use `env(safe-area-inset-*)`)
- MUST: Avoid unwanted scrollbars; fix overflows (on macOS, set "Show scroll bars" to "Always" to test Windows behavior)
- MUST: Set `color-scheme: dark` on `<html>` in dark themes for proper scrollbar/device UI contrast
- MUST: Let the browser size things—prefer flex/grid/intrinsic layout over measuring in JS
- SHOULD: Use optical alignment; adjust by ±1px when perception beats geometry
- SHOULD: Balance icon/text lockups (stroke/weight/size/spacing/color)

### 9.4 Content & Accessibility

**Content**
- MUST: Use the ellipsis character `…` (not `...`)
- MUST: Use non-breaking spaces to glue terms: `10&nbsp;MB`, `⌘&nbsp;+&nbsp;K`, `Vercel&nbsp;SDK`; use `&#x2060;` for no space
- MUST: Make content resilient to user-generated content (short/avg/very long)
- MUST: Use locale-aware dates/times/numbers/currency
- MUST: Prefer language settings over location—detect via `Accept-Language` header and `navigator.languages`, not IP/GPS
- MUST: Design empty/sparse/dense/error states
- MUST: No dead ends—always offer next step/recovery
- SHOULD: Inline help first; tooltips last resort
- SHOULD: Use curly quotes (" "); avoid widows/orphans
- SHOULD: Right-clicking the nav logo surfaces brand assets

**Accessibility**
- MUST: Use accurate names (`aria-label`); set decorative elements to `aria-hidden`
- MUST: Verify in the Accessibility Tree
- MUST: Icon-only buttons have descriptive `aria-label`
- MUST: Prefer native semantics (`button`, `a`, `label`, `table`) before ARIA
- MUST: Use redundant status cues (not color-only); icons have text labels
- MUST: Skeletons mirror final content to avoid layout shift
- MUST: `<title>` matches current context
- MUST: Use tabular numbers for comparisons (`font-variant-numeric: tabular-nums` or mono font like Geist Mono)
- MUST: Use `scroll-margin-top` on headings for anchored links
- MUST: Include a "Skip to content" link
- MUST: Use hierarchical `<h1–h6>`
- NEVER: Ship the schema—visuals may omit labels but accessible names still exist

### 9.5 Performance

**Monitoring & Profiling**
- MUST: Test iOS Low Power Mode and macOS Safari
- MUST: Measure reliably (disable extensions that skew runtime)
- MUST: Track and minimize re-renders (React DevTools/React Scan)
- MUST: Profile with CPU/network throttling
- SHOULD: Test reliably across different environments

**Optimization**
- MUST: Batch layout reads/writes; avoid unnecessary reflows/repaints
- MUST: Mutations (`POST`/`PATCH`/`DELETE`) target <500ms
- MUST: Virtualize large lists (e.g., `virtua`) or use `content-visibility: auto`
- MUST: Preload only above-the-fold images; lazy-load the rest
- MUST: Prevent CLS from images (explicit dimensions or reserved space)
- MUST: Use `<link rel="preconnect">` for CDN/asset domains (with `crossorigin` when needed)
- MUST: Preload critical fonts to avoid flash and layout shift
- MUST: Move expensive/long tasks to Web Workers to avoid blocking the main thread
- SHOULD: Prefer uncontrolled inputs; make controlled loops cheap (keystroke cost)
- SHOULD: Subset fonts—ship only needed code points via `unicode-range`; limit variable axes

### 9.6 Design

**Visual Polish**
- MUST: Meet contrast requirements—prefer [APCA](https://apcacontrast.com/) over WCAG 2
- MUST: Increase contrast on `:hover`/`:active`/`:focus`
- MUST: Use accessible charts (color-blind-friendly palettes)
- MUST: Set `<meta name="theme-color" content="#...">` to match page background
- SHOULD: Use layered shadows (ambient + direct)
- SHOULD: Use crisp edges via semi-transparent borders + shadows
- SHOULD: Use nested radii: child ≤ parent; concentric
- SHOULD: Maintain hue consistency: tint borders/shadows/text toward bg hue
- SHOULD: Match browser UI to background
- SHOULD: Avoid gradient banding (use masks when needed)

---

### 9.7 Copywriting

- MUST: Use active voice ("Install the CLI" not "The CLI will be installed")
- MUST: Error messages guide the exit—don't just state what's wrong, tell users how to fix it
- MUST: Avoid ambiguous labels ("Save API Key" not "Continue")
- MUST: Use consistent placeholders—strings: `YOUR_API_TOKEN_HERE`, numbers: `0123456789`
- SHOULD: Use numerals for counts ("8 deployments" not "eight deployments")
- SHOULD: Separate numbers and units with non-breaking space (`10&nbsp;MB`)
- SHOULD: Be clear and concise—use as few words as possible
- SHOULD: Use action-oriented language ("Install the CLI…" not "You will need the CLI…")
- SHOULD: Frame messages positively, even for errors ("Something went wrong—try again or contact support")

---

## Summary of Terminology

- **MUST**: Mandatory requirement that cannot be violated
- **SHOULD**: Strongly recommended; exceptions require justification
- **NEVER**: Prohibited practice that must be avoided at all costs
