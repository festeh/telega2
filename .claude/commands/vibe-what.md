---
description: Create a feature specification - define WHAT to build in plain language.
---

## User Input

```text
$ARGUMENTS
```

## Why

Clarify what we're building before writing code. Catches misunderstandings early. Saves time.

## Purpose

Define WHAT to build. Skip implementation details (no specific frameworks, databases, APIs), but don't oversimplify.

**Use `/plain-language` skill while writing.**

## Steps

1. **Read the feature description** above.
   - If empty: Ask what they want to build.

2. **Get current branch** using `git branch --show-current`.
   - If on `main` or `master`: Ask user to create a feature branch first (suggest `vc branch <description>`).

3. **Create spec file** at `specs/<branch>/spec.md`:

```markdown
# [Feature Name]

## What Users Can Do

1. **[Action Name]**

   - **Scenario: Successful Action**
     - **Given:** [Precondition]
     - **When:** [Action]
     - **Then:** [Result]

   - **Scenario: Failure Case** (optional)
     - **When:** [Bad Input]
     - **Then:** [Specific Error]

## Requirements

- [ ] [Requirement in plain language]

## Open Questions

- [Question]
```

4. **Validate the spec**:
   - Is every requirement testable?
   - No implementation details (no specific frameworks, databases, libraries)?

5. **Report**: Show the file path and summary.

## Example

Branch: `003-password-reset`
Input: "Users should be able to reset their password"

Output (`specs/003-password-reset/spec.md`):
```markdown
# Password Reset

## What Users Can Do

1. **Request password reset**

   - **Scenario: Successful request**
     - **Given:** User has an account
     - **When:** User enters their email
     - **Then:** Reset link sent within 1 minute

   - **Scenario: Unknown email**
     - **When:** User enters unregistered email
     - **Then:** Show helpful "email not found" message

2. **Set new password**

   - **Scenario: Successful reset**
     - **Given:** User has valid reset link
     - **When:** User enters new password meeting rules
     - **Then:** Password updated, user logged in

   - **Scenario: Expired link**
     - **Given:** Reset link is older than 24 hours
     - **When:** User clicks the link
     - **Then:** Show "request new link" message

## Requirements

- [ ] Reset link expires after 24 hours
- [ ] Password must be at least 8 characters
- [ ] User gets confirmation email after reset
- [ ] Old sessions log out after password change

## Open Questions

- Should we require the old password if user is logged in?
```
