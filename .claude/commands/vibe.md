---
description: Analyze user query and codebase to pick the best approach.
---

## User Input

```text
$ARGUMENTS
```

## Purpose

Help the user pick the right approach: write a spec, create a plan, or start coding.

## Steps

1. **Read the user's query** above.
   - If empty: Ask what they want to build.

2. **Create a feature branch**:
   Run: `vc branch "<feature description>"`
   Creates a numbered branch like `001-add-user-auth`.

3. **Classify the request**:
   - New feature or enhancement?
   - Bug fix or small change?
   - Refactor or architecture change?

3. **Explore the codebase**:
   - Find related code and patterns
   - Check dependencies
   - Count affected files
   - Look for tests

4. **Pick a strategy**:

   ### `/vibe-what` (Spec First)
   **When:** Requirements are unclear.
   Define WHAT to build.

   ### `/vibe-how` (Plan First)
   **When:** Requirements are clear but the work is complex.
   Define HOW to build it.

   ### Implementation
   **When:** Clear and simple.
   Start coding.

5. **Share your recommendation**:

   ```
   ## Analysis

   [What the user wants + what you found in the code]

   ## Assessment

   - Clarity: [Clear / Unclear]
   - Simple: [Yes / No]

   ## Recommendation: [/vibe-what / /vibe-how / Implementation]

   [Why this approach fits best]

   ## Next Steps

   [What to do now]
   ```

## Decision Matrix

| Clarity | Simple? | Recommendation   |
|---------|---------|------------------|
| Unclear | -       | `/vibe-what`     |
| Clear   | No      | `/vibe-how`      |
| Clear   | Yes     | Implementation   |
