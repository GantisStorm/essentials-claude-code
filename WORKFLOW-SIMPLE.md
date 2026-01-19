# Simple Workflow: Plan + Implement

> **This is the default workflow. 80% of tasks don't need tasks or beads conversion.** Start here. Escalate only when you hit problems—hallucinations, lost context, multi-day features, or want RalphTUI's dashboard.

Single-session features, bug fixes, and refactoring. For RalphTUI integration: [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md). For persistent memory: [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md).

## Overview

```
PLANNING                                EXECUTION
┌───────────────────────────────┐       ┌───────────────────────────────┐
│ 1. Analysis: "ultrathink..."  │       │ /implement-loop plan.md       │
│ 2. /plan-creator <task>       │──────▶│   • Create todos from plan    │
│    Output: .claude/plans/...  │       │   • Implement each todo       │
└───────────────────────────────┘       │   • Run exit criteria         │
                                        │   • Repeat until all pass     │
                                        └───────────────────────────────┘
```

**What is a Plan?** File in `.claude/plans/` with:
- **Reference Implementation** — Complete, copy-paste-ready code (50-200+ lines)
- **Migration Patterns** — Exact before/after code with line numbers
- **Exit Criteria** — Specific verification commands (`npm test -- auth`, not "run tests")

The plan is the **source of truth**. When context compacts, the loop re-reads it.

---

## Stage 1: Planning

Start with deep analysis:
```
ultrathink and traverse and analyse the code to thoroughly understand
the context before preparing a detailed plan. Ask clarifying questions before finalising.
```

Then create the plan:
```bash
/plan-creator Add user authentication with JWT tokens       # Feature
/bug-plan-creator "TypeError at auth.py:45" "Login fails"   # Bug
/code-quality-plan-creator src/auth.ts src/api.ts           # Quality
```

**Review before looping:**
- [ ] Architecture makes sense
- [ ] Reference code is correct
- [ ] Exit criteria are exact commands
- [ ] File paths match your code

Fixing a plan is cheap. Debugging bad generated code is expensive.

---

## Stage 2: Execution

```bash
/implement-loop .claude/plans/user-authentication-3k7f2-plan.md
```

**Options:**
| Option | Command | Behavior |
|--------|---------|----------|
| Default | `/implement-loop plan.md` | Runs until exit criteria pass |
| Limited | `/implement-loop plan.md --max-iterations 10` | Stops after N iterations |
| Cancel | `/cancel-implement` | Stops, preserves progress |

**Loop mechanism:** Stop hook checks transcript for completion signals (`exit criteria passed`). State tracked in `.claude/implement-loop.local.md`.

---

## Tips

1. **Invest in planning** — Quality prompts yield quality plans
2. **Be specific about done** — Exit criteria = exact commands, not descriptions
3. **Watch for hallucinations** — Sign the plan may exceed context (scale up to beads)

---

## Context Recovery

When context compacts mid-loop:
1. Re-read the plan file
2. Check todo list status to see completed/pending items
3. Continue with the next pending todo
