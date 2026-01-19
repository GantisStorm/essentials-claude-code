# Simple Workflow: Plan + Implement

> **This is the default workflow with zero external dependencies.** Handles 80% of tasks. Only escalate to Tasks or Beads when you hit specific problems (multi-session work, persistent context loss, or want RalphTUI dashboard).

## Overview

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│ PLANNING                        │     │ EXECUTION                       │
│                                 │     │                                 │
│ /plan-creator <task>            │────▶│ /implement-loop plan.md         │
│                                 │     │   • Create todos from plan      │
│ Output: .claude/plans/...       │     │   • Implement each todo         │
│                                 │     │   • Run exit criteria           │
│                                 │     │   • Loop until PASS             │
└─────────────────────────────────┘     └─────────────────────────────────┘
```

**No external tools required.** The loop is built into the plugin.

---

## What is a Plan?

A markdown file in `.claude/plans/` containing:

| Section | Purpose |
|---------|---------|
| **Reference Implementation** | Complete, copy-paste-ready code (50-200+ lines) |
| **Migration Patterns** | Exact before/after code with line numbers |
| **Exit Criteria** | Specific verification commands (`npm test -- auth`, not "run tests") |

The plan is the **source of truth**. When context compacts, the loop re-reads it.

---

## Stage 1: Planning

### Option A: Feature Development
```bash
/plan-creator Add user authentication with JWT tokens
```

### Option B: Bug Fix
```bash
/bug-plan-creator "TypeError at auth.py:45" "Login fails when user has no profile"
```

### Option C: Code Quality
```bash
/code-quality-plan-creator src/auth.ts src/api.ts
```

### Review Before Executing

**Always review the plan before looping:**
- [ ] Architecture makes sense for your codebase
- [ ] Reference code is correct and complete
- [ ] Exit criteria are exact commands (not descriptions)
- [ ] File paths match your project structure

Fixing a plan is cheap. Debugging bad generated code is expensive.

---

## Stage 2: Execution

```bash
/implement-loop .claude/plans/user-authentication-3k7f2-plan.md
```

The loop:
1. Reads the plan file
2. Creates todos using TodoWrite
3. Implements each todo following plan instructions
4. Runs exit criteria verification command
5. **Loops until exit criteria pass (exit code 0)**

### Options

| Option | Command | Behavior |
|--------|---------|----------|
| Default | `/implement-loop plan.md` | Runs until exit criteria pass |
| Limited | `/implement-loop plan.md --max-iterations 10` | Stops after N iterations |
| Cancel | `/cancel-implement` | Stops gracefully, preserves progress |

### Loop Mechanism

The stop hook checks the transcript for completion signals (`exit criteria passed`). State is tracked in `.claude/implement-loop.local.md`.

---

## Context Recovery

When context compacts mid-loop:
1. The loop re-reads the plan file
2. Checks todo list status for completed/pending items
3. Continues with the next pending todo

The plan file persists outside the conversation, so context compaction doesn't lose your progress.

---

## Tips

1. **Invest in planning** — Quality prompts yield quality plans
2. **Be specific about "done"** — Exit criteria = exact commands, not descriptions
3. **Watch for hallucinations** — If AI hallucinates mid-task, consider the Beads workflow

---

## When to Escalate

| Problem | Solution |
|---------|----------|
| Works fine | Stay with Simple workflow |
| Want RalphTUI dashboard | Use [Tasks workflow](WORKFLOW-TASKS.md) |
| Multi-day feature | Use [Beads workflow](WORKFLOW-BEADS.md) |
| AI hallucinates mid-task | Use [Beads workflow](WORKFLOW-BEADS.md) |
| Context keeps compacting | Use [Beads workflow](WORKFLOW-BEADS.md) |

---

## Related

- [README.md](README.md) — Main guide
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Optional: prd.json format, RalphTUI integration
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Optional: Persistent memory across sessions
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters
