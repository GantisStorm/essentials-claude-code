# Simple Workflow

> **Default workflow with zero dependencies.** Handles 80% of tasks. Only escalate to Tasks or Beads when you hit specific problems.

## Overview

```
/plan-creator <task>  →  /implement-loop plan.md  →  Exit criteria pass ✓
```

**No external tools required.**

---

## Usage

### 1. Create Plan

```bash
# New features
/plan-creator Add user authentication with JWT

# Bug fixes
/bug-plan-creator "TypeError at auth.py:45" "Login fails when user has no profile"

# Code quality
/code-quality-plan-creator src/auth.ts src/api.ts
```

### 2. Review Plan

Check `.claude/plans/` before executing:
- Architecture makes sense
- Reference code is complete
- Exit criteria are exact commands

Fixing a plan is cheap. Debugging bad code is expensive.

### 3. Execute Loop

```bash
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
```

The loop:
1. Reads the plan
2. Implements each section
3. Runs exit criteria
4. **Loops until exit criteria pass (exit code 0)**

### Options

```bash
/implement-loop plan.md                    # Run until done
/implement-loop plan.md --max-iterations 10 # Limit iterations
/cancel-implement                           # Stop gracefully
```

---

## What's In A Plan?

| Section | Purpose |
|---------|---------|
| Reference Implementation | Complete code (50-200+ lines) |
| Migration Patterns | Before/after with line numbers |
| Exit Criteria | Exact commands (`npm test -- auth`) |

The plan is the **source of truth**. When context compacts, the loop re-reads it.

---

## Context Recovery

When context compacts:
1. Loop re-reads the plan file
2. Checks todo status
3. Continues with next pending item

Plans persist outside the conversation.

---

## When to Escalate

| Problem | Solution |
|---------|----------|
| Works fine | Stay here |
| Want visual dashboard | [Tasks workflow](WORKFLOW-TASKS.md) |
| Multi-day feature | [Beads workflow](WORKFLOW-BEADS.md) |
| AI hallucinates | [Beads workflow](WORKFLOW-BEADS.md) |

---

## Related

- [README.md](README.md) — All commands and plan creators
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — prd.json + RalphTUI
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent memory
