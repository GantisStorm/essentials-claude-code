# How Essentials Compares

> **Loops and swarms powered by Claude Code's built-in Task System.** Loop and swarm are interchangeable — swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync.

Plans define exit criteria. Loops run until tests pass. Done means actually done.

---

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
- No verification requirement — "done" means "I wrote code" not "code works"
- Optimistic completion — AI assumes success rather than proving it
- Context loss — long tasks exceed context windows, losing requirements
- No defined success — vague criteria like "tests pass" instead of exact commands

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

### Plan-First + Verification-Enforced (Essentials)

```
Request → Plan with Exit Criteria → Execute → Verify → Loop if Failed → Done
```

Verification-driven loops for brownfield development. Plans define exit criteria and a `## Dependency Graph` for execution ordering. Loops run until tests pass. Execute via loop (sequential) or swarm (parallel).

**Strengths:** Guaranteed completion. Automatic retry on failure. Context recovery from plan file. Structured dependency graph enables parallel execution. Integrates with Ralph TUI for dashboard visualization and Beads for persistent task tracking.

**Weaknesses:** Overhead for trivial tasks. Solo-focused.

**Best for:** Adding features to existing codebases, quality-critical code, multi-session work, when you've been burned by premature "done."

**Quick Start:**
```bash
# Generate codemap first (recommended — grounds plans in real codebase symbols)
/codemap-creator src/

# From conversation context (after discussing)
/implement-loop fix the auth bug       # Sequential
/implement-swarm refactor handlers     # Parallel

# Or with plan file (auto-uses codemap for better accuracy)
/plan-creator Add user authentication
/plan-loop plan.md    # Sequential
/plan-swarm plan.md   # Parallel
```

**Codemap tip:** Plans built with a codemap produce fewer hallucinations because the plan creator starts with real symbols and dependency relationships. Sub-agents spawned by swarm commands inherit this grounding — the plan they execute was built with accurate codebase knowledge.

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

## Still Ralph Wiggum, Now Native

The [Ralph Wiggum pattern](https://ghuntley.com/ralph/) pioneered autonomous Claude Code loops. The community built it with workarounds. Anthropic made it native.

### What The Community Built (Before)

- **Stop hooks**: Shell scripts (`.sh` files) configured in `hooks.json` that ran after each Claude response. They'd grep the output for keywords like "complete" or "EXIT_CRITERIA_PASSED" to decide whether to continue looping or stop.
- **External plan files**: Since Claude had no persistent storage, we tracked task state in markdown files that survived between sessions.
- **TodoWrite lists**: Flat task lists with no ordering — if task #3 depended on #1, you had to hope Claude did them in order.
- **Fresh sessions**: Starting new conversations to fight context rot, then manually re-reading plan files to restore state.
- **Single agent**: No way to coordinate multiple agents working on the same task list.

### What Claude Code Provides (Now)

Claude Code v2.1.19+ has a native Task Management System:

| Old Workaround | Native Tool | Why It's Better |
|----------------|-------------|-----------------|
| Stop hooks grepping for "complete" | `TaskUpdate({ status: "completed" })` | Structured status, no string matching |
| External plan.md tracking state | `~/.claude/tasks/` storage | Automatic persistence, survives compaction |
| TodoWrite flat lists | `TaskUpdate({ addBlockedBy: ["1"] })` | Dependencies enforced by system |
| Fresh sessions + re-read plan | `CLAUDE_CODE_TASK_LIST_ID` env var | Same task list across sessions |
| Single agent execution | `TaskList` shared by parallel workers | Multiple agents coordinate without conflicts |

### What Essentials Uses

**None of the old workarounds.** We use the native Task System exclusively:

```
TaskCreate  → Create task with subject, description, dependencies
TaskUpdate  → Claim task, mark complete, set blockedBy
TaskList    → See all tasks (workers use this to find available work)
TaskGet     → Get full task details when needed
```

**The core loop is unchanged:** Plan → Implement → Verify → Loop if fail → Done when pass.

**What's better:** Dependencies prevent wrong ordering. Swarms run parallel workers. Visual progress with `ctrl+t`. Multi-session persistence built-in.

---

## Why We Still Use Plan Files

Tasks track **status**. Plans hold **implementation details** and **dependency structure**.

`TaskList` shows ID, subject, status, blockedBy — but **not descriptions**. To see what was done, you'd call `TaskGet` for each task individually. There's no "show me all implementation notes at a glance."

```
Plan file (.claude/plans/)     →  Full code, Dependency Graph, exit criteria
Task System (~/.claude/tasks/) →  Status, dependencies, parallel coordination
```

**Use Tasks for:** Tracking progress, enforcing order, coordinating workers.
**Use Plans for:** Implementation details, reference code, dependency graph, exit criteria.

---

## The Dependency Pipeline

Plans now include a structured `## Dependency Graph` table that flows through the entire system:

```
Plan Creator                    Converter                      Executor
┌──────────────┐    ┌─────────────────────────┐    ┌──────────────────────┐
│ Dependency   │ →  │ dependsOn (prd.json)    │ →  │ addBlockedBy (task   │
│ Graph        │    │ depends_on (beads)      │    │ primitive)           │
│              │    │                         │    │                      │
│ Phase 1: A,B │    │ US-003: ["US-001","002"]│    │ taskId "3":          │
│ Phase 2: C   │    │                         │    │   blockedBy: ["1",   │
│              │    │                         │    │   "2"]               │
└──────────────┘    └─────────────────────────┘    └──────────────────────┘
```

**All three plan creators** (`/plan-creator`, `/bug-plan-creator`, `/code-quality-plan-creator`) produce plans with the same `## Dependency Graph` table. Both converters (`/tasks-converter`, `/beads-converter`) read the table to build dependency arrays. All eight executors translate those to `addBlockedBy`.

**Why this matters for swarms:** Tasks in the same dependency phase have no inter-dependencies and can execute simultaneously. If you chain every task to the previous one, swarm degrades to sequential. The Dependency Graph maximizes parallelism by only declaring real code dependencies.

---

## How Essentials Handles Common Problems

### Context Compaction

**The problem:** AI context windows fill up. Long tasks lose early requirements. AI contradicts itself or forgets edge cases.

**Other tools:** Start over, re-explain everything, or accept degraded quality.

**Essentials:** Task state persists in `~/.claude/tasks/` — outside the conversation. On compaction:
1. `TaskList` shows all tasks and their status
2. Re-read plan file for full context
3. Find next pending unblocked task
4. Continue where you left off

The old TodoWrite lists disappeared on compaction. The new Task System survives.

---

### Multi-Session Work

**The problem:** Close laptop, come back tomorrow. Where were we?

**Other tools:** Start fresh. Re-establish context. Hope you remember what was done.

**Essentials:**
- Simple tier: Plan file + Task System persist in `~/.claude/tasks/`
- Beads tier: `bd ready` shows exactly what's next, each bead has everything needed to implement it

---

### Getting Stuck

**The problem:** Same error 4 times in a row. Going in circles. Making things worse.

**Other tools:** Human notices eventually. Manually redirect.

**Essentials:** Detects stuck state (>3 iterations on same task, repeated errors). Triggers decomposition — break the stuck task into 2-3 smaller, more specific tasks with their own exit criteria.

---

### Error Recovery

**The problem:** Tests fail. Types don't match. Edge case breaks.

**Other tools:** User must explain the error, guide the fix.

**Essentials:** Loop automatically continues with error context. Previous attempts inform next attempt. Retries until verification passes.

---

## Verification: The Key Innovation

Most tools optimize for speed of first output. Essentials optimizes for time-to-actually-done.

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
- Want IDE integration (essentials is terminal-based)

---

## Parallel Execution with Dependencies

Swarms use a queue-based approach with background agents. The plan's `## Dependency Graph` determines which tasks can run in parallel:

```
Dependency Graph from Plan:
| Phase | File                    | Depends On        |
|-------|-------------------------|-------------------|
| 1     | src/db/schema.ts        | —                 |
| 1     | src/models/user.ts      | —                 |
| 2     | src/auth/middleware.ts  | schema, user      |
| 3     | src/routes/login.ts     | middleware        |
| 3     | src/routes/protected.ts | middleware        |
| 4     | tests/auth.test.ts      | login, protected  |

Task Graph (after converter + executor):
#1 Set up database           (Phase 1 — ready)
#2 Create user model         (Phase 1 — ready, parallel with #1)
#3 Auth middleware            (Phase 2 — blocked by #1, #2)
#4 Login routes              (Phase 3 — blocked by #3)
#5 Protected routes          (Phase 3 — blocked by #3, parallel with #4)
#6 Tests                     (Phase 4 — blocked by #4, #5)
```

**How the queue works:**
```
Main:     Mark #1, #2 in_progress → Spawn Agent-1, Agent-2  [--workers 2]
Main:     Stop and wait                        [agents notify on completion]
Agent-1:  Complete #1 → notify main → exit
Main:     Woken → Mark #1 completed → TaskList → #3 still blocked
Agent-2:  Complete #2 → notify main → exit
Main:     Woken → Mark #2 completed → TaskList → #3 unblocked → Mark #3 in_progress → Spawn Agent-3
Agent-3:  Complete #3 → notify main → exit
Main:     Woken → Mark #3 completed → TaskList → #4, #5 unblocked → Mark in_progress → Spawn Agent-4, Agent-5
...
```

Each agent does ONE task then exits. Main agent marks tasks in_progress on spawn, completed on return, checks TaskList for newly unblocked tasks (status=`pending`, empty `blockedBy`), and spawns new agents as tasks unblock. No racing, no stuck loops.

**Workers limit:** Use `--workers N` to control max concurrent agents (default: 3).

---

## What Essentials Doesn't Do

**No team features.** No dashboards, permissions, or multi-user sync. Essentials is for individual developers.

**No cloud infrastructure.** Runs locally. Your code never leaves your machine. No subscriptions.

**No IDE integration.** Terminal-based by design. Works alongside any editor.

**No auto-commit.** Exit criteria passing ≠ ready to merge. You decide when to commit.

If you need these things, excellent tools exist. Essentials solves a different problem.

---

## The Three Tiers

> **Start with Simple.** 80% of tasks don't need tasks or beads conversion. Escalate only when you hit problems — hallucinations, lost context, multi-day features, or want prd.json format.

Match workflow to task size:

### Simple: Implement Loop (Use This First)

```bash
# From conversation (after discussing a bug/feature)
/implement-loop fix the auth bug we discussed

# Or with plan file
/plan-creator Add JWT authentication
/plan-loop .claude/plans/jwt-auth-abc12-plan.md
```

Single session. Exit criteria enforced. Loop until pass. **This handles 80% of tasks.**

### Tasks: Plan → Tasks → Tasks Loop (prd.json Format)

```bash
/plan-creator Add JWT authentication
/tasks-converter .claude/plans/jwt-auth-abc12-plan.md

# Execute with Claude Code's Task System (recommended)
/tasks-loop ./prd.json
/tasks-swarm ./prd.json

# Or execute with Ralph TUI (classic Ralph loop)
ralph-tui run --prd ./prd.json
```

Creates prd.json file with self-contained tasks and `dependsOn` arrays (from plan's Dependency Graph). **Use when you want prd.json format.** Each task has full implementation code — no reading the original plan.

### Beads: Plan → Beads → Beads Loop (Persistent Memory)

```bash
/plan-creator Add complete auth system
/beads-converter .claude/plans/auth-system-xyz99-plan.md

# Execute with Claude Code's Task System (recommended)
/beads-loop --label plan:auth-system
/beads-swarm --epic beads-abc123

# Or execute with Ralph TUI (classic Ralph loop)
ralph-tui run --tracker beads --epic <id>
```

Full persistence. Each bead is self-contained with dependencies (from plan's Dependency Graph via `bd dep add`). Survives sessions, context compaction, interruptions. **Use when Simple tier fails — AI hallucinates mid-task, loses track, or feature spans multiple days.**

### Execution Options

| Executor | Style | Features |
|----------|-------|----------|
| Plugin loops/swarms | Claude Code's Task System | Native dependencies, `ctrl+t` progress, automatic persistence |
| Ralph TUI | Classic Ralph Wiggum loop | TUI dashboard, community approach before native tasks |

**Both work with the same plans, prd.json files, and beads.** This plugin creates the plans and converts them. You choose the executor.

---

## Trade-Offs

**Speed vs Correctness**

Code-first gives you code in seconds. But if it's wrong, you spend hours debugging. Essentials takes longer upfront but total time (including fixes) is lower.

**Freedom vs Structure**

Code-first lets you improvise. Essentials requires a plan. The structure is the feature — it's what prevents premature completion.

**Throughput vs Reliability**

Loop and swarm are interchangeable — swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync. The plan's Dependency Graph determines how much parallelism is possible.

**Simplicity vs Power**

Conversation tools have no learning curve. Essentials has three tiers to learn. The tiers exist because one size doesn't fit all tasks.

**Token Cost vs Context Recovery**

The tasks and beads workflows (plan → tasks/beads) copy implementation code into each task/bead. This is intentional — each must be self-contained for context recovery. But it's expensive. For simple tasks, use `/implement-loop` directly.

---

## The Bottom Line

Loops and swarms powered by Claude Code's built-in Task System. Plans define exit criteria and structured dependency graphs. Loops run until tests pass. Done means actually done.

The loop won't end until verification passes. That's the guarantee.

**Choose Essentials when:**
- Adding features to existing codebases
- Completion reliability matters
- You're tired of debugging AI's "done" code

**Choose something else when:**
- Task is trivial
- You need team or cloud features
- Exploration matters more than completion

**Optional integrations:**
- [Beads](https://github.com/steveyegge/beads) — Persistent memory across sessions
- [Ralph TUI](https://github.com/subsy/ralph-tui) — Classic Ralph loop executor with TUI dashboard
