# 3-Stage Workflow: Self-Contained with /implement-loop

The simplest workflow for features that fit in a single session. No external tools needed - everything stays within Claude Code.

**Best for:** Small to medium features, bug fixes, refactoring tasks that won't exceed context limits.

---

## Why Self-Contained?

| Approach | Benefit |
|----------|---------|
| **Direct coding** | Fast but no structure or verification |
| **With /implement-loop** | Structured iteration with automatic verification |
| **Exit criteria** | Ensures tests, lint, and typecheck pass before completion |

---

## The 3-Stage Workflow

```
┌───────────────────────────────────────────────────────────────────────────┐
│                            PLANNING PHASE                                 │
│                                                                           │
│  ┌─────────────────────────┐      ┌─────────────────────────────────────┐ │
│  │ STAGE 1: ANALYSIS       │      │ STAGE 2: PLAN CREATION              │ │
│  │                         │      │                                     │ │
│  │ "ultrathink and         │  →   │ /plan-creator <task>                │ │
│  │  traverse and analyse   │      │                                     │ │
│  │  the code..."           │      │ Agent: plan-creator-default         │ │
│  │                         │      │ Output: .claude/plans/*-plan.md     │ │
│  └─────────────────────────┘      └─────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌───────────────────────────────────────────────────────────────────────────┐
│                           EXECUTION PHASE                                 │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ STAGE 3: IMPLEMENT WITH /implement-loop                             │  │
│  │                                                                     │  │
│  │ /implement-loop .claude/plans/*-plan.md                             │  │
│  │                                                                     │  │
│  │ ┌─────────────────────────────────────────────────────────────────┐ │  │
│  │ │ Loop (via stop hook):                                           │ │  │
│  │ │  1. Read plan → Create todos with TodoWrite                     │ │  │
│  │ │  2. Implement next todo                                         │ │  │
│  │ │  3. Run Exit Criteria (tests, lint, typecheck)                  │ │  │
│  │ │  4. If FAIL → Fix and retry                                     │ │  │
│  │ │  5. If PASS → "Exit criteria passed"                            │ │  │
│  │ └─────────────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## Stage 1: Analysis

Force deep understanding before planning:

```
ultrathink and traverse and analyse the code to thoroughly understand
the context before preparing a detailed plan to implement the requirement

Before finalising the plan you can ask me any question to clarify the requirement
```

---

## Stage 2: Plan Creation

Create an architectural plan with `/plan-creator`:

```
/plan-creator Add user authentication with JWT tokens
```

Review the generated plan in `.claude/plans/` - verify it matches your mental model.

---

## Stage 3: Execution

Execute with `/implement-loop`:

```
/implement-loop .claude/plans/user-authentication-3k7f2-plan.md
```

The loop iterates until all Exit Criteria pass.

---

## How /implement-loop Works

The `/implement-loop` command:

1. **Reads the plan** - Parses your architectural plan from `.claude/plans/`
2. **Executes steps** - Works through Implementation Steps in order
3. **Runs verification** - After each significant change, runs Exit Criteria commands
4. **Iterates on failures** - If tests/lint/typecheck fail, fixes and retries
5. **Completes when green** - Only finishes when all Exit Criteria pass

**Plan as Source of Truth:** The plan contains full implementation code, exit criteria, and migration patterns. When context is compacted, the loop re-reads the plan to recover.

---

## Exit Criteria

Every plan includes Exit Criteria - verification commands that must pass:

```markdown
## Exit Criteria

- [ ] `npm test` - All tests pass
- [ ] `npm run lint` - No linting errors
- [ ] `npm run typecheck` - No type errors
- [ ] `npm run build` - Build succeeds
```

The loop will not complete until ALL criteria pass.

---

## Canceling the Loop

If you need to stop mid-implementation:

```
/cancel-implement
```

This gracefully stops the loop while preserving your progress.

---

## When to Use This Workflow

| Situation | Use /implement-loop? |
|-----------|---------------------|
| Small feature (< 1 hour) | Yes |
| Bug fix with clear scope | Yes |
| Refactoring task | Yes |
| Medium feature (fits in context) | Yes |
| Large feature (multiple sessions) | No - Use [Beads workflow](WORKFLOW-BEADS.md) |
| Needs stakeholder review | No - Use [Spec workflow](WORKFLOW-SPEC.md) |
| Team collaboration | No - Use [Spec workflow](WORKFLOW-SPEC.md) |

---

## Tips for Success

1. **Good plans = good results** - Spend time on `/plan-creator` prompts
2. **Clear exit criteria** - Be specific about what "done" means
3. **Watch context** - If you see hallucinations, the plan may be too large
4. **Use for iteration** - Great for "make it work, then make it right" cycles

---

## Next Steps

- Need stakeholder review? See [WORKFLOW-SPEC.md](WORKFLOW-SPEC.md)
- Plan too large for one session? See [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md)
- Back to main guide: [GUIDE.md](GUIDE.md)
