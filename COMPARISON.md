# How Essentials Compares

## The Problem

```
Human: "Build user authentication"
AI: [writes code]
AI: "Done!"
Human: [runs tests] → 3 failing
Human: "Tests are failing"
AI: [fixes some] → "Fixed!"
Human: [runs tests] → 1 still failing
Human: [gives up, fixes manually]
```

The AI said "done" three times when it wasn't done. This pattern wastes more time than writing code yourself.

**Why it happens:**
- No verification requirement - "done" means "I wrote code" not "code works"
- Optimistic completion - AI assumes success rather than proving it
- Context loss - long tasks exceed context windows, losing requirements
- No defined success - vague criteria like "tests pass" instead of exact commands

**Essentials fixes this.** The loop cannot end until verification passes. "Done" means actually done.

---

## Four Approaches to AI Coding

### Code-First

```
Request → Generate → "Done"
```

Start coding immediately. Declare done when code is written.

**Strengths:** Fast initial output. Low overhead. Good for prototypes.

**Weaknesses:** High rework rate. No verification. Premature completion. Each fix attempt starts fresh without learning from previous failures.

**Best for:** Quick experiments, trivial changes, exploration.

---

### Conversation-First

```
Request ↔ Discuss ↔ Generate ↔ Review ↔ Repeat
```

Interactive back-and-forth. Human guides every step.

**Strengths:** Maximum control. Good for learning. Catches misunderstandings early.

**Weaknesses:** Slow. Human becomes the state machine. Context overflow on long sessions. No autonomous completion.

**Best for:** Pair programming, learning, small changes where you want to understand each step.

---

### Spec-First

```
Request → Specification → Approval → Generate → "Done"
```

Create detailed specs or PRDs before coding. Human approves design.

**Strengths:** Structured documentation. Team-oriented. Catches design issues before coding. Auditable.

**Weaknesses:** Process overhead for simple tasks. Specs can drift from implementation. May still lack runtime verification.

**Best for:** Teams, enterprise, compliance-heavy environments.

---

### Plan-First + Verification-Enforced (Essentials)

```
Request → Plan with Exit Criteria → Execute → Verify → Loop if Failed → Done
```

Create plan with exact verification commands. Loop until verification passes.

**Strengths:** Guaranteed completion. Automatic retry on failure. Context recovery from plan file. Multi-session persistence available.

**Weaknesses:** Overhead for trivial tasks. Sequential (no parallel execution). Solo-focused.

**Best for:** Complex features, quality-critical code, multi-session work, when you've been burned by premature "done."

---

## The Core Difference

Other tools let you declare "done" based on feelings. Essentials requires proof.

```
Other tools:
  AI finishes writing code → "Done"
  (hope it works)

Essentials:
  AI finishes writing code → Run exit criteria → FAIL → Keep working
  AI fixes issues → Run exit criteria → FAIL → Keep working
  AI fixes more → Run exit criteria → PASS → Done
```

The verification step is mandatory and automatic. You can't skip it. You can't override it. The loop continues until tests pass.

---

## How Essentials Handles Common Problems

### Context Compaction

**The problem:** AI context windows fill up. Long tasks lose early requirements. AI contradicts itself or forgets edge cases.

**Other tools:** Start over, re-explain everything, or accept degraded quality.

**Essentials:** Plan file is external source of truth. On compaction, re-read plan → check todo status → continue. Beads are fully self-contained (50-200+ lines of implementation detail each).

---

### Multi-Session Work

**The problem:** Close laptop, come back tomorrow. Where were we?

**Other tools:** Start fresh. Re-establish context. Hope you remember what was done.

**Essentials:**
- Simple tier: Plan file + todo list persist
- Beads tier: `bd ready` shows exactly what's next, each bead has everything needed to implement it

---

### Getting Stuck

**The problem:** Same error 4 times in a row. Going in circles. Making things worse.

**Other tools:** Human notices eventually. Manually redirect.

**Essentials:** Detects stuck state (>3 iterations on same task, repeated errors). Triggers decomposition - break the stuck task into 2-3 smaller, more specific tasks with their own exit criteria.

---

### Error Recovery

**The problem:** Tests fail. Types don't match. Edge case breaks.

**Other tools:** User must explain the error, guide the fix.

**Essentials:** Loop automatically continues with error context. Previous attempts inform next attempt. Retries until verification passes.

---

## Verification: The Key Innovation

Most tools optimize for speed of first output. Essentials optimizes for time-to-actually-done.

```
Traditional total time:
  Generation:     10 min
  "It's broken":  15 min
  "Still broken": 20 min
  Manual fix:     30 min
  Total:          75 min

Essentials total time:
  Planning:       10 min
  Loop iteration: 40 min
  (Exit criteria pass)
  Total:          50 min
```

The planning "overhead" pays for itself by eliminating debug cycles.

**Exit criteria examples:**

Bad: "Tests pass"
Good: `npm test -- --grep "auth" && npm run typecheck`

Bad: "It works"
Good: `curl -X POST localhost:3000/login -d '{"user":"test"}' | jq .token`

Specific, executable commands. The loop runs them automatically.

---

## When to Use Essentials

**Strong fit:**
- Complex features touching multiple files
- Quality-critical production code
- Multi-session projects (spanning days)
- You've been burned by premature "done"
- Completion reliability > speed of first output

**Weak fit:**
- Trivial 2-line fixes (overhead not justified)
- Learning/exploration (use conversation instead)
- Team collaboration needed (essentials is solo-focused)
- Need parallel execution (essentials is sequential)
- Want IDE integration (essentials is terminal-based)

---

## What Essentials Doesn't Do

**No parallel agents.** One task at a time, verified before moving on. Trade-off: lower throughput, higher reliability.

**No team features.** No dashboards, permissions, or multi-user sync. Essentials is for individual developers.

**No cloud infrastructure.** Runs locally. Your code never leaves your machine. No subscriptions.

**No IDE integration.** Terminal-based by design. Works alongside any editor.

**No auto-commit.** Exit criteria passing ≠ ready to merge. You decide when to commit.

**No multi-model orchestration.** Built on Claude Code. One model, consistent behavior.

If you need these things, excellent tools exist. Essentials solves a different problem.

---

## The Three Tiers

Match workflow to task size:

### Simple: Plan → Implement Loop

```bash
/plan-creator Add JWT authentication
/implement-loop .claude/plans/jwt-auth-abc12-plan.md
```

Single session. Exit criteria in plan. Loop until pass.

### Medium: Plan → Spec → Spec Loop

```bash
/plan-creator Add JWT authentication
/proposal-creator .claude/plans/jwt-auth-abc12-plan.md
# Review the spec, verify design.md code is correct
/spec-loop jwt-auth
```

Adds human review of spec before execution. Good when you want to verify the design.

### Large: Plan → Spec → Beads → Beads Loop

```bash
/plan-creator Add complete auth system
/proposal-creator .claude/plans/auth-system-xyz99-plan.md
/beads-creator openspec/changes/auth-system/
/beads-loop --label openspec:auth-system
```

Full persistence. Each bead is self-contained. Survives sessions, context compaction, interruptions. For multi-day features or when AI hallucinates on large tasks.

---

## Trade-Offs

**Speed vs Correctness**

Code-first gives you code in seconds. But if it's wrong, you spend hours debugging. Essentials takes longer upfront but total time (including fixes) is lower.

**Freedom vs Structure**

Code-first lets you improvise. Essentials requires a plan. The structure is the feature - it's what prevents premature completion.

**Throughput vs Reliability**

Parallel agents process more files simultaneously. Essentials does one thing at a time, verified. One verified task beats five broken ones.

**Simplicity vs Power**

Conversation tools have no learning curve. Essentials has three tiers to learn. The tiers exist because one size doesn't fit all tasks.

---

## The Bottom Line

Essentials does one thing exceptionally well: **ensures "done" means done.**

Not "probably done." Not "looks done." Not "the AI said done."

Actually done, with passing tests and verified exit criteria.

The loop won't end until verification passes. That's the guarantee.

**Choose Essentials when:**
- You want verification, not hope
- Completion reliability matters
- You're tired of debugging AI's "done" code

**Choose something else when:**
- Task is trivial
- You need team/parallel/cloud features
- Exploration matters more than completion
