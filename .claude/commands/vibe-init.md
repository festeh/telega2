---
description: Initialize project implementation rules from global config.
---

## User Input

```text
$ARGUMENTS
```

## Purpose

Set up project-level implementation rules by selecting from global config.

## Steps

1. **Read global implementation rules** from `~/.config/vibecheck/implementation.md`.
   - If missing: Tell the user to create it first.

2. **List each rule** and ask the user which to include:
   - Show each rule with a number
   - Ask: "Which rules do you want for this project? (e.g., 1,3,5 or all)"

3. **For rules that say "If included:"**, scan the repo to fill in project-specific details.

4. **Write `arch/specs/IMPLEMENTATION.md`** with selected rules. Overwrite if exists.
