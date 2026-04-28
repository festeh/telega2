---
description: Maintain architecture docs and decision records for the project.
---

## User Input

```text
$ARGUMENTS
```

## Why

Codebases evolve faster than docs. This command keeps architecture documentation in sync with reality, and captures decisions before they're forgotten.

## Purpose

Maintain the `arch/` directory: architecture docs, decision records, and the index. Interpret what the user wants and act accordingly.

**Use `/plain-language` skill while writing.**

## Interpreting the request

Read the user input above and pick the right action:

| Input | Action |
|-------|--------|
| Empty or "sync" | Full sync — create missing docs, update stale ones |
| A decision (e.g., "We chose Postgres over SQLite") | Create an ADR capturing the decision |
| A doc topic (e.g., "Update the database docs") | Refresh that specific doc |
| A new topic (e.g., "Add a doc for our caching layer") | Create a new numbered doc |
| A question (e.g., "What's out of date?") | Compare docs against code, report drift |

## Steps

### 1. Set up `arch/` if missing

Create the directory structure if it doesn't exist:

```
arch/
├── 00_MAP.md
├── adr/
└── specs/
```

### 2. Check branch scope

Run `git branch --show-current`.

- **On `main` or `master`**: Do a full sync across the whole codebase.
- **On a feature branch**: Run `git diff main...HEAD --name-only` (or `master` if that's the default). Focus the sync on changed areas only — update affected docs, suggest ADRs for significant architectural changes in the diff.

### 3. Add CLAUDE.md reference (once)

Check the root `CLAUDE.md`. If it doesn't already mention `arch/`, append:

```
Design docs are in arch/. See arch/00_MAP.md for an index.
```

Skip if the reference is already present.

### 4. Create or update architecture docs

Scan the codebase and decide which docs to create or update. Each doc gets a numbered file in `arch/`.

| File | Create when |
|------|-------------|
| `01_system_arch.md` | Always |
| `02_database.md` | Database/ORM/schema files found |
| `03_api.md` | HTTP routes or endpoints found |
| `04_auth_flow.md` | Auth logic found |
| `05_data_flow.md` | Pipelines, queues, or event systems found |
| `06_deployment.md` | Docker/CI/CD/infra-as-code found |
| `07_testing.md` | Significant test infrastructure found |

Use your judgment — skip docs that don't apply, add unlisted ones if the codebase warrants them.

**Doc template:**

```markdown
# [Topic Name]

## Overview

[What this component/subsystem does and why it exists.]

## How It Works

[Key concepts, data flow, or architecture. Use diagrams in ASCII if helpful.]

## Key Files

| File | Purpose |
|------|---------|
| `path/to/file` | [What it does] |

## Design Decisions

[Why things are the way they are. Link to ADRs if relevant.]

<!-- manual -->
<!-- Content between these tags is preserved during updates. -->
<!-- Add notes, diagrams, or context that shouldn't be overwritten. -->
<!-- /manual -->
```

**Rules for updating existing docs:**

- Preserve everything between `<!-- manual -->` and `<!-- /manual -->` tags exactly as-is.
- Update auto-generated sections to reflect current code.
- Don't remove information — update it or mark it as deprecated.

### 5. Create ADRs when needed

If the user states a decision, or if you find a significant architectural change on a feature branch, create an ADR.

ADRs live in `arch/adr/` and are **immutable** — never edit an existing ADR. To reverse a decision, create a new ADR with a `Supersedes` line.

**ADR naming:** `NNN_slug.md` where NNN is the next available number (001, 002, ...).

**ADR template:**

```markdown
# ADR-NNN: [Decision Title]

**Date:** YYYY-MM-DD
**Status:** Accepted

## Context

[What situation or problem prompted this decision.]

## Decision

[What was decided and why.]

## Consequences

[What changes as a result — good and bad.]
```

**To supersede an earlier ADR:**

```markdown
# ADR-NNN: [New Decision Title]

**Date:** YYYY-MM-DD
**Status:** Accepted
**Supersedes:** ADR-XXX

## Context

[Why the earlier decision is being reversed or changed.]

## Decision

[The new decision.]

## Consequences

[What changes now.]
```

### 6. Update `00_MAP.md`

After every change, regenerate the map. This is the index of everything in `arch/`.

**00_MAP.md template:**

```markdown
# Architecture Map

## Docs

| # | Doc | Summary |
|---|-----|---------|
| 01 | [System Architecture](01_system_arch.md) | [One-line summary] |

## Decision Records

| # | ADR | Status | Date |
|---|-----|--------|------|
| 001 | [Decision title](adr/001_slug.md) | Accepted | YYYY-MM-DD |

## Specs

| Branch | Spec | Plan |
|--------|------|------|
| [branch-name](specs/branch-name/spec.md) | Yes | [Yes/No](specs/branch-name/plan.md) |
```

### 7. Report what changed

Show a summary of what was created, updated, or flagged as stale.
