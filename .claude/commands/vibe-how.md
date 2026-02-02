---
description: Create an implementation plan - define HOW to build it.
---

## User Input

```text
$ARGUMENTS
```

## Why

Plan before coding. Identify technical decisions, risks, and structure upfront.

## Purpose

Define HOW to build what's in the spec. Create a concrete implementation plan.

**Use `/plain-language` skill while writing.**

**Follow `specs/IMPLEMENTATION.md` rules if present.**

## Steps

1. **Get current branch** using `git branch --show-current`.
   - If on `main` or `master`: Ask user to create a feature branch first (suggest `vc branch <description>`).

2. **Read the spec** from `specs/<branch>/spec.md`.
   - If no spec: Run `/vibe-what` first.

3. **Create plan file** at `specs/<branch>/plan.md`:

```markdown
# Plan: [Feature Name]

**Spec**: specs/<branch>/spec.md

## Tech Stack

- Language: [e.g., TypeScript, Python]
- Framework: [e.g., Bun, FastAPI]
- Storage: [e.g., SQLite, PostgreSQL, none]
- Testing: [e.g., bun test, pytest]

## Structure

Where code will live:

```
src/
├── [folder]/
│   └── [file]
```

## Approach

How to implement each requirement:

1. **[Requirement from spec]**
   [How to implement it]

2. **[Requirement from spec]**
   [How to implement it]

## Risks

What could go wrong:

- [Risk]: [Mitigation]

## Open Questions

- [Technical decision that needs input]
```

4. **Validate the plan**:
   - Does it cover all spec requirements?
   - Is the structure clear?
   - Are risks identified?

5. **Report**: Show the file path and summary.

## Example

Branch: `003-password-reset`
Spec: `specs/003-password-reset/spec.md`

Output (`specs/003-password-reset/plan.md`):
```markdown
# Plan: Password Reset

**Spec**: specs/003-password-reset/spec.md

## Tech Stack

- Language: TypeScript
- Framework: Bun.serve
- Storage: SQLite (existing users table + new reset_tokens table)
- Testing: bun test

## Structure

```
src/
├── routes/
│   └── auth.ts        # reset request + set new password endpoints
├── services/
│   └── email.ts       # send reset email
└── db/
    └── tokens.ts      # create/validate/expire tokens
```

## Approach

1. **Reset link expires after 24 hours**
   Store token with created_at, check expiry on validation.

2. **Password must be at least 8 characters**
   Validate in route handler before updating.

3. **User gets confirmation email after reset**
   Call email service after successful password update.

4. **Old sessions log out after password change**
   Invalidate all sessions for user ID in session store.

## Risks

- Email delivery delay: Use queue, show "check spam" message
- Token guessing: Use crypto.randomUUID(), rate limit requests

## Open Questions

- Use existing email service or new one?
```
