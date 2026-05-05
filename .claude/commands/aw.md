---
description: Ensure what you implement Always Works™ with comprehensive testing
---

# How to ensure Always Works™ implementation

Ensure implementation Always Works™ for: $ARGUMENTS.

Follow systematic approach:

## Core Philosophy

- "Should work" ≠ "does work" - pattern matching not enough
- Not paid to write code, paid to solve problems
- Untested code = guess, not solution

# The 30-Second Reality Check - Must answer YES to ALL:

- Ran/built code?
- Triggered exact feature changed?
- Saw expected result via own observation (incl. GUI)?
- Checked error messages?
- Bet $100 works?

# Phrases to Avoid:

- "This should work now"
- "I've fixed the issue" (especially 2nd+ time)
- "Try it now" (without trying myself)
- "The logic is correct so..."

# Specific Test Requirements:

- UI Changes: actually click button/link/form
- API Changes: make actual API call
- Data Changes: query DB
- Logic Changes: run specific scenario
- Config Changes: restart + verify loads

# The Embarrassment Test:

"If user records trying this + it fails, will I feel embarrassed seeing his face?"

# Time Reality:

- Time saved skipping tests: 30 sec
- Time wasted when broken: 30 min
- User trust lost: immeasurable

User describing bug 3rd time not thinking "this AI trying hard" — thinking "why wasting time with incompetent tool?"