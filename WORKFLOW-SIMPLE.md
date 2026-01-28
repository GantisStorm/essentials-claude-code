# Simple Workflow

> **Loops and swarms powered by Claude Code's built-in Task System.** Both enforce exit criteria and sync. Swarm is just faster when tasks can run in parallel.

**Default workflow with zero dependencies.** Handles 80% of tasks. Plans define exit criteria. Loops run until tests pass. Done means actually done.

**Requires:** Claude Code v2.1.19+ (native task dependencies, `ctrl+t` progress, automatic persistence)

## Overview

```
# From conversation context (no plan file needed)
[discuss bug/feature]  →  /implement-loop <task>   →  Exit criteria pass ✓
                       →  /implement-swarm <task>  →  All tasks complete ✓

# With plan file
/plan-creator <task>  →  /plan-loop plan.md   →  Exit criteria pass ✓
                      →  /plan-swarm plan.md  →  All tasks complete ✓
```

**No external tools required.** Uses Claude Code's built-in Task system for dependency tracking and `ctrl+t` visual progress.

---

## Usage

### 1. Create Plan

**Recommended:** Generate a codemap first. Plans built with a codemap are more accurate because the plan creator starts with real symbols and real dependency relationships instead of exploring from scratch. Sub-agents spawned by swarm commands also benefit — the plan they receive was built with grounded codebase knowledge.

```bash
# Generate codemap once (recommended — better plans, fewer hallucinations)
/codemap-creator src/

# Then create a plan (auto-uses codemap if present in .claude/maps/)
/plan-creator Add user authentication with JWT

# Bug fixes
/bug-plan-creator "TypeError at auth.py:45" "Login fails when user has no profile"

# Code quality
/code-quality-plan-creator src/auth.ts src/api.ts
```

All three plan creators produce plans with the same structure: per-file implementation code, a `## Dependency Graph` table, and exit criteria. All three auto-detect codemaps in `.claude/maps/` for faster, more accurate codebase orientation.

**Tip:** Use `/prompt-creator` to create better inputs:
```bash
/prompt-creator "feature: add OAuth login with Google"  # Creates detailed feature request
/prompt-creator "bug: ./logs/error.log API timeout"     # Analyzes logs, creates bug description
# Then use the generated prompt with /plan-creator or /bug-plan-creator
```

### 2. Review Plan

Check `.claude/plans/` before executing:
- Architecture makes sense
- Reference code is complete
- Dependency Graph reflects real code dependencies (not unnecessary chains)
- Exit criteria are exact commands

Fixing a plan is cheap. Debugging bad code is expensive.

### 3. Execute: Loop or Swarm

#### From Conversation Context

After discussing a bug or feature in chat:

```bash
/implement-loop fix the auth bug we discussed    # Sequential
/implement-swarm refactor the API handlers       # Parallel
```

The commands extract goals, requirements, and exit criteria from your discussion.

#### From Plan File

```bash
/plan-loop .claude/plans/user-auth-3k7f2-plan.md   # Sequential
/plan-swarm .claude/plans/user-auth-3k7f2-plan.md  # Parallel
```

#### How They Work

Both use Claude Code's **Task System** — a dependency graph, not a flat list. The plan's `## Dependency Graph` table determines execution order.

**Loop (sequential):**
```
Read plan → Create tasks → Set addBlockedBy from Dependency Graph → Execute in order → Verify → Loop if fail
```
1. Creates task graph with `TaskCreate`
2. Reads plan's `## Dependency Graph` table to set `addBlockedBy` dependencies
3. Executes tasks in dependency order (blocked tasks wait)
4. Runs exit criteria
5. **Loops until exit criteria pass**

**Swarm (parallel, queue-based):**
```
Read plan → Create tasks → Set addBlockedBy from Dependency Graph → Spawn ready tasks → Wait → Refill
```
1. Creates task graph with dependencies from Dependency Graph
2. Identifies **ready tasks** (status=`pending`, empty `blockedBy`) and marks them `in_progress`
3. Spawns up to N background agents (default: 3, or `--workers N`)
4. Each agent does ONE task then exits
5. Main agent stops and waits — background agents notify on completion
6. When notified → mark task `completed` → check TaskList for newly unblocked tasks → spawn next agents
7. **Completes when all tasks done**

**Task lifecycle**: `pending` → (blocked until deps complete) → `in_progress` → `completed`

**Why the Dependency Graph matters:**
```
Plan's Dependency Graph:
| Phase | File                    | Depends On              |
|-------|-------------------------|-------------------------|
| 1     | src/types/auth.ts       | —                       |
| 1     | src/config/oauth.ts     | —                       |
| 2     | src/services/auth.ts    | src/types/auth.ts       |

Phase 1 tasks run in parallel. Phase 2 waits for Phase 1.
If every task chains to the previous, swarm degrades to sequential.
```

### Options

```bash
# Loop (from context)
/implement-loop fix the bug we discussed    # From conversation context

# Loop (from plan file)
/plan-loop plan.md                          # Plan file required

# Cancel any loop
/cancel-loop

# Swarm (from context)
/implement-swarm refactor these handlers    # From conversation context
/implement-swarm update errors --workers 5  # Override workers
/implement-swarm simple task --model haiku  # Use cheaper model

# Swarm (from plan file)
/plan-swarm plan.md                         # Plan file required
/plan-swarm plan.md --workers 5             # Override workers

# Cancel any swarm
/cancel-swarm
```

---

## Loop vs Swarm

| Aspect | Loop | Swarm |
|--------|------|-------|
| **Executor** | Main agent (foreground) | Background agents |
| **Concurrency** | 1 task at a time | Up to N tasks (`--workers`) |
| **Context** | Full conversation history | Each agent gets task description only |
| **Visibility** | See work live | Check with `ctrl+t` or TaskList |
| **Task system** | Same | Same |
| **Dependencies** | Same | Same |
| **Exit criteria** | Enforced | Enforced |

**Both use the same task graph with dependencies.** Only difference is who executes and how many at once. Swarm is faster when tasks can run in parallel — parallelism depends on the plan's Dependency Graph structure.

---

## What's In A Plan?

| Section | Purpose |
|---------|---------|
| Implementation Plan | Complete code per file (50-200+ lines) |
| Dependencies / Provides | Per-file exact file path dependencies |
| Dependency Graph | Phase table for execution ordering |
| Exit Criteria | Exact commands (`npm test -- auth`) |

The plan is the **source of truth**. The `## Dependency Graph` table tells executors which tasks can run in parallel and which must wait. When context compacts, re-read the plan.

**Full schema:** Run `/plan-schema` for the complete section reference, or `/plan-schema validate <path>` to check a plan file.

---

## Visual Progress

Press `ctrl+t` to see task progress (both loop and swarm):
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 Setup database schema
■ #2 Implement auth middleware
□ #3 Add login route > blocked by #2
```

---

## Context Recovery

When context compacts:
1. Call TaskList to see all tasks
2. Re-read the plan file
3. Continue with next pending task

Plans persist outside the conversation.

---

## When to Escalate

| Problem | Solution |
|---------|----------|
| Works fine | Stay here |
| Want prd.json format | [Tasks workflow](WORKFLOW-TASKS.md) |
| Want classic Ralph TUI dashboard | [Tasks workflow](WORKFLOW-TASKS.md) or [Beads workflow](WORKFLOW-BEADS.md) + Ralph TUI |
| Multi-day feature | [Beads workflow](WORKFLOW-BEADS.md) |
| Need persistent memory | [Beads workflow](WORKFLOW-BEADS.md) |

---

## Related

- [README.md](README.md) — All commands and plan creators
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Dashboard visualization with Ralph TUI
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent task tracking with Beads
