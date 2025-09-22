# Guidelines (MUST FOLLOW)

This document contains comprehensive guidelines for software development. All sections are now inlined for better accessibility.

## Important Instruction Reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## JavaScript/TypeScript Standards

### Core Principles

- Always add exports at the end of the file, not inline
- Always use arrow functions, instead of function expressions
- Don't use dynamic imports (unless necessary for lazy loading)
- NEVER add unnecessary comments, about process or implementation details
- NEVER use `as any` - fix the type instead
- Don't use type assertions (`as` keyword), try always to use type guards or type narrowing, with tools like `zod`
- Always prefer `const` over `let`
- Always prefer `types` over `interfaces`
- Don't use `Promise.all` - use `Promise.allSettled` instead
- NEVER leave TypeScript errors, neither linting errors behind, ALWAYS check them

### Senior-Level Practices

- Use descriptive names for variables and functions
- Prefix event handler functions with "handle" (e.g., `handleClick`, `handleSubmit`)
- Use JSDoc comments for complex functions and types
- Leverage TypeScript's strict mode for enhanced type checking
- Use camelCase for variables and functions, PascalCase for types/classes, kebab-case for file names, and MACRO_CASE for "real" constants
- Focus on simplicity, readability, performance, maintainability, and testability. You're writing code that will be maintained by others, so make it easy for them to understand and modify. Use meaningful variable and function names, and follow consistent coding conventions.

### Error Handling

- Use explicit error handling - no silent failures
- Implement proper error boundaries in React components
- Use Result patterns or custom error types for better error management
- Always handle async operation failures gracefully

### Anti-Patterns to Avoid

- Overusing useEffect and creating dependency hell
- Implementing prop drilling instead of proper state management
- Creating monolithic components instead of composable ones
- Ignoring proper error boundaries and error handling
- Not considering mobile responsiveness from the start
- Implementing custom solutions for well-established patterns

## Frontend Development

### React Best Practices

- Optimize component rendering using React.memo, useMemo, useCallback
- Avoid unnecessary re-renders through proper dependency arrays
- Lazy load components and routes when appropriate
- Use compound components pattern for complex UI components
- Implement proper prop drilling solutions (Context, state management)

### Performance Optimization

- Implement code splitting at route and component levels
- Optimize bundle sizes - analyze and eliminate unused dependencies
- Use efficient data structures and algorithms
- Implement proper caching strategies (Tanstack Query)
- Optimize images and assets (WebP, lazy loading, proper sizing)

### State Management

- Choose appropriate state management solutions (local state vs global state)
- Implement proper data normalization for complex state
- Use proper loading and error states for async operations
- Avoid state mutations - always return new objects/arrays

### Accessibility

- Ensure proper ARIA labels, keyboard navigation, color contrast
- Test with screen readers and keyboard navigation
- Implement proper focus management
- Follow WCAG guidelines for accessibility compliance

## Cognitive Load Management

You are an engineer who writes code for **human brains, not machines**. You favour code that is simple to understand and maintain. Remember at all times that the code will be processed by human brain. The brain has a very limited capacity. People can only hold ~4 chunks in their working memory at once. If there are more than four things to think about, it feels mentally taxing.

### Example: Hard to Understand

```ts
if (val > someConstant) // (one fact in human memory)
    && (condition2 || condition3) // (three facts in human memory), prev cond should be true, one of c2 or c3 has be true
    && (condition4 && !condition5) { // (human memory overload), we are messed up by this point
    ...
}
```

### Example: Good Practice

Introducing intermediate variables with meaningful names:

```ts
const isValid = val > someConstant;
const isAllowed = condition2 || condition3;
const isSecure = condition4 && !condition5;
// (human working memory is clean), we don't need to remember the conditions, there are descriptive variables
if (isValid && isAllowed && isSecure) {
    ...
}
```

### Good Practices

- No useless "WHAT" comments, don't write a comment if it duplicates the code. Only "WHY" comments, explaining the motivation behind the code, explaining an especially complex part of the code or giving a bird's eye overview of the code
- Make conditionals readable, extract complex expressions into intermediate variables with meaningful names
- Prefer early returns over nested ifs, free working memory by letting the reader focus only on the happy path
- Prefer composition over deep inheritance, don't force readers to chase behavior across multiple classes
- Don't write shallow methods/classes/modules (complex interface, simple functionality). An example of shallow class: `MetricsProviderFactoryFactory`. The names and interfaces of such classes tend to be more mentally taxing than their entire implementations
- Prefer deep method/classes/modules (simple interface, complex functionality) over many shallow ones
- Don't overuse language features, stick to the minimal subset. Readers shouldn't need an in-depth knowledge of the language to understand the code
- Use self-descriptive values, avoid custom mappings that require memorization
- Don't abuse DRY, a little duplication is better than unnecessary dependencies
- Avoid unnecessary layers of abstractions, jumping between layers of abstractions is mentally exhausting, linear thinking is more natural to humans

## Security & Production

### Security Practices

- Sanitize all user inputs and validate on both client and server
- Implement proper authentication and authorization checks
- Use HTTPS everywhere and implement proper CORS policies
- Avoid XSS vulnerabilities through proper data escaping
- Implement proper error handling that doesn't leak sensitive information
- Never introduce code that exposes or logs secrets and keys
- Never commit secrets or keys to the repository
- Always follow security best practices

### Production Considerations

- Implement proper logging and monitoring
- Use environment variables for configuration
- Implement proper error tracking (Sentry, etc.)
- Use proper build optimization and minification
- Implement proper caching headers and CDN usage

### Testing Strategy

- Write comprehensive unit tests for utility functions
- Implement integration tests for complex user flows
- Use visual regression testing for UI components
- Test error states and edge cases thoroughly
- Use proper mocking strategies for external dependencies

## Workflow & Project Management

### Planning & Architecture

- **Always start with a written plan**: Ask me to draft a Markdown plan for any feature. Have me critique it for gaps, then regenerate an improved version
- **Break down complex features** into smaller, testable components

### Context Management & Workflow

#### Prompt Engineering

- Keep prompts laser-focused and specific
- Use exact identifiers from the codebase, not generic terms
- Ask for step-by-step reasoning before implementation
- Reference specific files/functions using exact names

#### File Organization

- Use file references (@src/components/Button.tsx) instead of copy-pasting
- Maintain clean git state with frequent, meaningful commits
- Re-index project context after major refactoring
- Use descriptive commit messages that explain the "why"

### Development Process

1. **Plan**: Write a detailed plan with acceptance criteria
2. **Implement**: Build the feature
3. **Review**: Conduct thorough code review with security/performance lens

### Continuous Improvement

- Refactor code regularly to maintain quality
- Stay current with frontend ecosystem changes and best practices

### Communication & Collaboration

#### Requirements Gathering

- Always clarify ambiguous requirements before implementation
- Ask specific questions about user experience expectations

#### Documentation Standards

- Document complex business logic and algorithms
- Maintain up-to-date README files with setup instructions

### Anti-Patterns to Avoid

#### Don't Do This

- Don't expect me to read minds about implicit requirements
- Don't implement features without proper planning
- Don't ignore TypeScript errors or warnings
- Don't ignore linting errors or warnings

## Debugging & Diagnostics

### Systematic Debugging

- When stuck, ask for a diagnostic report covering:
  1. Files modified in the current session
  2. Role of each file in the feature
  3. Root cause analysis of current issues
  4. Multiple debugging approaches

### Development Tools

- Use proper debugging tools (React DevTools, Redux DevTools)
- Implement proper development vs production builds
- Use proper source maps for debugging
- Implement comprehensive logging in development

### Debugging Workflow

1. Identify the issue precisely
2. Gather all relevant information
3. Form hypotheses about the cause
4. Test each hypothesis systematically
5. Document the solution for future reference

## Code Review Standards

### Review Checklist

- **Security**: Check for vulnerabilities, input validation, proper authentication
- **Performance**: Look for N+1 problems, unnecessary re-renders, algorithm complexity
- **Accessibility**: Ensure proper ARIA labels, keyboard navigation, color contrast
- **Correctness**: Test edge cases, verify error handling, check business logic
- **Maintainability**: Assess code complexity, documentation, and testability

### Architecture Review

- Ensure proper separation of concerns
- Verify component composition and reusability
- Check for proper abstraction levels
- Validate data flow and state management decisions

### Code Review Process

1. Understand the context and requirements
2. Check for functional correctness
3. Evaluate code quality and maintainability
4. Verify security and performance considerations
5. Provide constructive feedback with specific examples

### What to Look For

- Consistent code style and conventions
- Proper error handling and edge cases
- Efficient algorithms and data structures
- Clear variable and function names
- Appropriate use of design patterns
- Test coverage and quality

# Web Interface Guidelines

## Interactions

- Keyboard
  - MUST: Full keyboard support per [WAI-ARIA APG](https://wwww3org/WAI/ARIA/apg/patterns/)
  - MUST: Visible focus rings (`:focus-visible`; group with `:focus-within`)
  - MUST: Manage focus (trap, move, and return) per APG patterns
- Targets & input
  - MUST: Hit target ≥24px (mobile ≥44px) If visual <24px, expand hit area
  - MUST: Mobile `<input>` font-size ≥16px or set:
    ```html
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
    ```
  - NEVER: Disable browser zoom
  - MUST: `touch-action: manipulation` to prevent double-tap zoom; set `-webkit-tap-highlight-color` to match design
- Inputs & forms (behavior)
  - MUST: Hydration-safe inputs (no lost focus/value)
  - NEVER: Block paste in `<input>/<textarea>`
  - MUST: Loading buttons show spinner and keep original label
  - MUST: Enter submits focused text input In `<textarea>`, ⌘/Ctrl+Enter submits; Enter adds newline
  - MUST: Keep submit enabled until request starts; then disable, show spinner, use idempotency key
  - MUST: Don’t block typing; accept free text and validate after
  - MUST: Allow submitting incomplete forms to surface validation
  - MUST: Errors inline next to fields; on submit, focus first error
  - MUST: `autocomplete` + meaningful `name`; correct `type` and `inputmode`
  - SHOULD: Disable spellcheck for emails/codes/usernames
  - SHOULD: Placeholders end with ellipsis and show example pattern (eg, `+1 (123) 456-7890`, `sk-012345…`)
  - MUST: Warn on unsaved changes before navigation
  - MUST: Compatible with password managers & 2FA; allow pasting one-time codes
  - MUST: Trim values to handle text expansion trailing spaces
  - MUST: No dead zones on checkboxes/radios; label+control share one generous hit target
- State & navigation
  - MUST: URL reflects state (deep-link filters/tabs/pagination/expanded panels) Prefer libs like [nuqs](https://nuqs47ngcom/)
  - MUST: Back/Forward restores scroll
  - MUST: Links are links—use `<a>/<Link>` for navigation (support Cmd/Ctrl/middle-click)
- Feedback
  - SHOULD: Optimistic UI; reconcile on response; on failure show error and rollback or offer Undo
  - MUST: Confirm destructive actions or provide Undo window
  - MUST: Use polite `aria-live` for toasts/inline validation
  - SHOULD: Ellipsis (`…`) for options that open follow-ups (eg, “Rename…”)
- Touch/drag/scroll
  - MUST: Design forgiving interactions (generous targets, clear affordances; avoid finickiness)
  - MUST: Delay first tooltip in a group; subsequent peers no delay
  - MUST: Intentional `overscroll-behavior: contain` in modals/drawers
  - MUST: During drag, disable text selection and set `inert` on dragged element/containers
  - MUST: No “dead-looking” interactive zones—if it looks clickable, it is
- Autofocus
  - SHOULD: Autofocus on desktop when there’s a single primary input; rarely on mobile (to avoid layout shift)

## Animation

- MUST: Honor `prefers-reduced-motion` (provide reduced variant)
- SHOULD: Prefer CSS > Web Animations API > JS libraries
- MUST: Animate compositor-friendly props (`transform`, `opacity`); avoid layout/repaint props (`top/left/width/height`)
- SHOULD: Animate only to clarify cause/effect or add deliberate delight
- SHOULD: Choose easing to match the change (size/distance/trigger)
- MUST: Animations are interruptible and input-driven (avoid autoplay)
- MUST: Correct `transform-origin` (motion starts where it “physically” should)

## Layout

- SHOULD: Optical alignment; adjust by ±1px when perception beats geometry
- MUST: Deliberate alignment to grid/baseline/edges/optical centers—no accidental placement
- SHOULD: Balance icon/text lockups (stroke/weight/size/spacing/color)
- MUST: Verify mobile, laptop, ultra-wide (simulate ultra-wide at 50% zoom)
- MUST: Respect safe areas (use env(safe-area-inset-*))
- MUST: Avoid unwanted scrollbars; fix overflows

## Content & Accessibility

- SHOULD: Inline help first; tooltips last resort
- MUST: Skeletons mirror final content to avoid layout shift
- MUST: `<title>` matches current context
- MUST: No dead ends; always offer next step/recovery
- MUST: Design empty/sparse/dense/error states
- SHOULD: Curly quotes (“ ”); avoid widows/orphans
- MUST: Tabular numbers for comparisons (`font-variant-numeric: tabular-nums` or a mono like Geist Mono)
- MUST: Redundant status cues (not color-only); icons have text labels
- MUST: Don’t ship the schema—visuals may omit labels but accessible names still exist
- MUST: Use the ellipsis character `…` (not ``)
- MUST: `scroll-margin-top` on headings for anchored links; include a “Skip to content” link; hierarchical `<h1–h6>`
- MUST: Resilient to user-generated content (short/avg/very long)
- MUST: Locale-aware dates/times/numbers/currency
- MUST: Accurate names (`aria-label`), decorative elements `aria-hidden`, verify in the Accessibility Tree
- MUST: Icon-only buttons have descriptive `aria-label`
- MUST: Prefer native semantics (`button`, `a`, `label`, `table`) before ARIA
- SHOULD: Right-clicking the nav logo surfaces brand assets
- MUST: Use non-breaking spaces to glue terms: `10&nbsp;MB`, `⌘&nbsp;+&nbsp;K`, `Vercel&nbsp;SDK`

## Performance

- SHOULD: Test iOS Low Power Mode and macOS Safari
- MUST: Measure reliably (disable extensions that skew runtime)
- MUST: Track and minimize re-renders (React DevTools/React Scan)
- MUST: Profile with CPU/network throttling
- MUST: Batch layout reads/writes; avoid unnecessary reflows/repaints
- MUST: Mutations (`POST/PATCH/DELETE`) target <500 ms
- SHOULD: Prefer uncontrolled inputs; make controlled loops cheap (keystroke cost)
- MUST: Virtualize large lists (eg, `virtua`)
- MUST: Preload only above-the-fold images; lazy-load the rest
- MUST: Prevent CLS from images (explicit dimensions or reserved space)

## Design

- SHOULD: Layered shadows (ambient + direct)
- SHOULD: Crisp edges via semi-transparent borders + shadows
- SHOULD: Nested radii: child ≤ parent; concentric
- SHOULD: Hue consistency: tint borders/shadows/text toward bg hue
- MUST: Accessible charts (color-blind-friendly palettes)
- MUST: Meet contrast—prefer [APCA](https://apcacontrastcom/) over WCAG 2
- MUST: Increase contrast on `:hover/:active/:focus`
- SHOULD: Match browser UI to bg
- SHOULD: Avoid gradient banding (use masks when needed)
