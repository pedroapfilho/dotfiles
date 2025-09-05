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
