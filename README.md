<div align="center">

<img src="logo.png" alt="Essentials for Claude Code" width="450"/>

# Essentials for Claude Code

[![Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](https://unlicense.org/)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Loops and swarms powered by Claude Code's built-in Task System.**

Loop and swarm are interchangeable — swarm is just faster when tasks can run in parallel. Both enforce exit criteria, use Claude's native task dependencies, `ctrl+t` progress, and automatic persistence.

Plans define exit criteria. Loops run until tests pass. Done means actually done.

</div>

---

## The Problem

```
You: "Add authentication"
AI:  *writes code* "Done!"
You: *runs tests* — 3 failing
You: "Fix these"
AI:  "Fixed!"
You: *runs tests* — still failing
     [repeat until you give up]
```

## The Solution

```
# Option A: Discuss in chat, then execute from context
You: "I need to fix this auth bug..." [back and forth discussion]
You: /implement-loop fix the auth bug we discussed
AI:  *implements, tests fail, fixes, tests fail, fixes...*
AI:  "Exit criteria passed" ✓

# Option B: Create plan first, then execute
You: /plan-creator Add authentication
You: /plan-loop .claude/plans/auth-plan.md
AI:  "Exit criteria passed" ✓
```

---

## Quick Start

```bash
# Install
/plugin marketplace add GantisStorm/essentials-claude-code
/plugin install essentials@essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd

# Option A: From conversation (after discussing a bug/feature)
/implement-loop fix the auth bug we discussed    # Sequential
/implement-swarm refactor the API handlers       # Parallel

# Option B: With plan file
/plan-creator Add user authentication with JWT
/plan-loop .claude/plans/user-auth-3k7f2-plan.md   # Sequential
/plan-swarm .claude/plans/user-auth-3k7f2-plan.md  # Parallel

# Visual progress
ctrl+t   # Toggle task tree view
```

**Zero external dependencies.** Both loop and swarm enforce exit criteria. Swarm defaults to 3 concurrent workers.

---

## Powered by Claude Code's Task System

Our loop and swarm commands use Claude Code's **built-in Task Management System** (v2.1.19+).

> **Ralph TUI and Beads integrate seamlessly.** Use [Ralph TUI](https://github.com/subsy/ralph-tui) for dashboard visualization. Use [Beads](https://github.com/steveyegge/beads) for persistent task tracking across sessions.

### What We Used Before

The community built Ralph Wiggum loops with workarounds:

- **Stop hooks**: Shell scripts (`.sh` files) that ran after each Claude response, grepping output for keywords like "complete" or "done" to decide whether to continue the loop
- **External plan files**: Markdown files tracking task state since Claude had no built-in persistence
- **TodoWrite**: Flat task lists with no dependency ordering — tasks could run out of order
- **Fresh sessions**: Starting new conversations to fight context rot, manually re-establishing state each time

### What We Use Now

Claude Code v2.1.19+ provides native tools that replace all of this:

| Old Workaround | Native Replacement | Why It's Better |
|----------------|-------------------|-----------------|
| Stop hooks (shell scripts) | `TaskUpdate({ status: "completed" })` | No external scripts, status is structured data |
| External plan.md for state | `~/.claude/tasks/` storage | Survives context compaction automatically |
| TodoWrite flat lists | `TaskUpdate({ addBlockedBy: [...] })` | Dependencies enforced — tasks can't run out of order |
| Manual session coordination | `CLAUDE_CODE_TASK_LIST_ID` env var | Same task list across sessions |
| Single agent | `TaskList` + parallel workers | Multiple agents coordinate via shared state |

**The core loop is unchanged:** Plan → Implement → Verify → Loop if fail → Done when pass.

### What Tasks Do Well

- **Dependency management**: Task #3 blocked by #1 and #2 literally cannot start until both complete
- **Visual progress**: Press `ctrl+t` to see live task tree with status
- **Parallel coordination**: Multiple workers share one task list, no conflicts
- **Persistence**: Survives context compaction, stored in `~/.claude/tasks/`

### What Tasks Don't Do

`TaskList` shows ID, subject, status, and blockedBy — **but NOT description**. To see implementation details, you must call `TaskGet` for each task individually.

**This is why we still use plan files.** Tasks track status. Plans hold implementation details.

```
Plan file (.claude/plans/)     →  Full implementation code (50-200+ lines per task)
Task System (~/.claude/tasks/) →  Status tracking, dependencies, parallel coordination
```

### The Four Core Tools

| Tool | Purpose |
|------|---------|
| `TaskCreate` | Create task with subject, description, activeForm |
| `TaskUpdate` | Change status, set owner, add `blockedBy` dependencies |
| `TaskGet` | Get full details of ONE task (including description) |
| `TaskList` | See ALL tasks (but only subject, status, blockedBy) |

### How Dependencies Work

Dependencies flow through the entire pipeline:

```
Plan Creator                    Converter                      Executor
┌──────────────┐    ┌─────────────────────────┐    ┌──────────────────────┐
│ Dependency   │ →  │ dependsOn (prd.json)    │ →  │ addBlockedBy (task   │
│ Graph        │    │ depends_on (beads)      │    │ primitive)           │
│              │    │                         │    │                      │
│ Phase 1: A,B │    │ US-003: ["US-001","002"]│    │ taskId "3":          │
│ Phase 2: C   │    │                         │    │  blockedBy: ["1","2"]│
└──────────────┘    └─────────────────────────┘    └──────────────────────┘
```

Plan creators write a `## Dependency Graph` table. Converters read it to build `dependsOn` (prd.json) or `depends_on` (beads). Loop/swarm commands translate those to `addBlockedBy` using an ID map.

**Task lifecycle**: `pending` → (blocked until deps complete) → `in_progress` → `completed`

A task with non-empty `blockedBy` shows as **blocked** in `ctrl+t`. When a blocking task is marked `completed`, it's automatically removed from the blocked list. A task becomes **ready** (executable) when its `blockedBy` list is empty.

```
TaskCreate({ subject: "Set up database" })           // → task "1"
TaskCreate({ subject: "Create auth middleware" })     // → task "2"
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })      // #2 waits for #1
```

Task #2 **cannot start** until #1 completes. The system enforces this.

### Visual Progress (`ctrl+t`)

```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 Set up database schema
■ #2 Create auth middleware (Worker-1)
□ #3 Add login routes > blocked by #2
□ #4 Write tests > blocked by #3
```

### Queue-Based Swarm Coordination

Main agent controls a queue of background agents:

```
Main:    Mark #1-3 in_progress → Spawn Agent-1, Agent-2, Agent-3
         ↓
Main:    Stop and wait — background agents notify on completion
         ↓
Agent-1: Completes Task #1 → notifies main → exits
         ↓
Main:    Woken → Mark #1 completed → TaskList → #4 unblocked → Mark #4 in_progress → Spawn Agent-4
         ↓
Main:    Stop and wait — next notification
         ... repeat until all tasks complete ...
```

Each agent does ONE task then exits. No racing. No stuck loops.
Main agent marks tasks in_progress on spawn, completed on return, and refills queue as slots open.

### Multi-Session Persistence

Tasks persist across sessions with `CLAUDE_CODE_TASK_LIST_ID`:

```bash
# Per terminal session
CLAUDE_CODE_TASK_LIST_ID="my-project" claude

# Or in .claude/settings.json
{ "env": { "CLAUDE_CODE_TASK_LIST_ID": "my-project" } }
```

Start a new session tomorrow — your task list is still there.

---

## Workflows

| Workflow | Best For | Converter | Loop | Swarm |
|----------|----------|-----------|------|-------|
| **Simple** | 80% of tasks | — | `/implement-loop`, `/plan-loop` | `/implement-swarm`, `/plan-swarm` |
| **Tasks** | prd.json format | `/tasks-converter` | `/tasks-loop` | `/tasks-swarm` |
| **Beads** | Persistent memory | `/beads-converter` | `/beads-loop` | `/beads-swarm` |

**Converters** transform plans into executable formats. `/tasks-converter` creates prd.json files with `dependsOn` arrays. `/beads-converter` creates beads with epic→task hierarchy and `depends_on` via `bd dep add`. Both read the plan's `## Dependency Graph` table to build dependencies that maximize parallel execution.

**All use Claude Code's built-in Task System** for dependencies, `ctrl+t` progress, and persistence.

**Alternative executor:** [Ralph TUI](https://github.com/subsy/ralph-tui) runs Tasks/Beads with the classic Ralph Wiggum loop style (community approach before Claude Code had native tasks).

### Loop vs Swarm

| Aspect | Loop | Swarm |
|--------|------|-------|
| **Executor** | Main agent (foreground) | Background agents |
| **Concurrency** | 1 task at a time | Up to N tasks (`--workers`) |
| **Context** | Full conversation history | Each agent gets task description only |
| **Visibility** | See work live | Check with `ctrl+t` or TaskList |
| **Task system** | Same | Same |
| **Dependencies** | Same | Same |

**Both use the same task graph with dependencies.** Only difference is who executes and how many at once. Swarm is faster when tasks can run in parallel. Dependencies determine parallelism — tasks in the same dependency phase run simultaneously, later phases wait.

### Simple (Start Here)

```bash
# From conversation context (after discussing)
/implement-loop fix the auth bug       # Sequential
/implement-swarm refactor API handlers  # Parallel

# Or with plan file
/plan-creator Add JWT authentication
/plan-loop .claude/plans/jwt-auth-plan.md    # Sequential
/plan-swarm .claude/plans/jwt-auth-plan.md   # Parallel
```

### Tasks (prd.json Format)

```bash
/plan-creator Add JWT authentication
/tasks-converter .claude/plans/jwt-auth-plan.md

# Execute with Claude Code's Task System (recommended)
/tasks-loop .claude/prd/jwt-auth.json             # Sequential
/tasks-swarm .claude/prd/jwt-auth.json            # Parallel

# Or execute with Ralph TUI (classic Ralph loop)
ralph-tui run --prd .claude/prd/jwt-auth.json
```

### Beads (Persistent Memory)

```bash
bd init
/plan-creator Add JWT authentication
/beads-converter .claude/plans/jwt-auth-plan.md

# Execute with Claude Code's Task System (recommended)
/beads-loop                                        # Sequential
/beads-swarm                                       # Parallel

# Or execute with Ralph TUI (classic Ralph loop)
ralph-tui run --tracker beads --epic <epic-id>
```

---

## How Loops Work

```
                    ┌─────────────────┐
                    │  Read Source    │
                    │ (plan/context)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Create Tasks   │
                    │  + Dependencies │
                    │ (from Dep Graph)│
                    └────────┬────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │              MAIN AGENT                 │
        │                                         │
        │   ┌─────────────────┐                   │
        │   │    TaskList     │◄──────┐           │
        │   │ (find unblocked)│       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │            ▼                │           │
        │   ┌─────────────────┐       │           │
        │   │  Mark task      │       │           │
        │   │  in_progress    │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │            ▼                │           │
        │   ┌─────────────────┐       │           │
        │   │   Implement     │       │           │
        │   │   (read, edit)  │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │            ▼                │           │
        │   ┌─────────────────┐       │           │
        │   │  Mark task      │       │           │
        │   │   completed     │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │      ┌─────┴─────┐          │           │
        │      │           │          │           │
        │  More tasks   All done      │           │
        │      │           │          │           │
        │      └───────────┼──────────┘           │
        │                  │                      │
        └──────────────────┼──────────────────────┘
                           │
                           ▼
                    ┌─────────────────┐
                    │  Run Exit       │
                    │  Criteria       │
                    └────────┬────────┘
                             │
                       ┌─────┴─────┐
                       │           │
                     FAIL        PASS
                       │           │
                       │           ▼
                       │    ┌─────────────────┐
                       │    │ Loop complete ✓ │
                       │    └─────────────────┘
                       │
                       ▼
                ┌─────────────────┐
                │   Fix issues    │
                │   (loop back)   │
                └─────────────────┘
```

**Sequential execution.** Main agent works through tasks one at a time in dependency order. Blocked tasks wait until their dependencies complete. Exit criteria verified at end. Loops until all tests pass.

---

## How Swarms Work

```
                    ┌─────────────────┐
                    │  Read Source    │
                    │ (plan/context)  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Create Tasks   │
                    │  + Dependencies │
                    │ (from Dep Graph)│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Spawn up to N  │
                    │ background agents│
                    │ (ready tasks)   │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
  │  Agent 1    │     │  Agent 2    │     │  Agent N    │
  │─────────────│     │─────────────│     │─────────────│
  │ implement   │     │ implement   │     │ implement   │
  │ EXIT        │     │ EXIT        │     │ EXIT        │
  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │              MAIN AGENT                 │
        │                                         │
        │   ┌─────────────────┐                   │
        │   │  Stop & wait    │◄──────┐           │
        │   │  (notification) │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │            ▼                │           │
        │   ┌─────────────────┐       │           │
        │   │  Agent done     │       │           │
        │   │  Mark completed │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │            ▼                │           │
        │   ┌─────────────────┐       │           │
        │   │  Find ready     │       │           │
        │   │ (pending+empty  │       │           │
        │   │  blockedBy)     │       │           │
        │   │  Mark in_progress│      │           │
        │   │  Spawn workers  │       │           │
        │   └────────┬────────┘       │           │
        │            │                │           │
        │      ┌─────┴─────┐          │           │
        │      │           │          │           │
        │  More tasks   All done      │           │
        │      │           │          │           │
        │      └───────────┼──────────┘           │
        │                  │                      │
        └──────────────────┼──────────────────────┘
                           │
                           ▼
                    ┌─────────────────┐
                    │ Swarm complete ✓│
                    └─────────────────┘
```

**Queue-based parallel execution (default: 3 workers).** Main agent marks tasks in_progress and spawns up to N background agents. Each agent does ONE task then exits. On completion notification, main agent marks the task completed, checks TaskList for newly unblocked tasks (status=`pending`, empty `blockedBy`), marks them in_progress, and spawns workers. Dependencies enforced — blocked tasks wait until all their blockers complete.

---

## Commands

### Plan Creators

| Command | Use For |
|---------|---------|
| `/plan-creator <feature>` | New features (brownfield development) |
| `/bug-plan-creator <error> <desc>` | Bug fixes, root cause analysis |
| `/code-quality-plan-creator <files>` | Refactoring, dead code, security |

All three produce plans with the same structure: per-file implementation details, `## Dependency Graph` table, and exit criteria. Any plan can be fed to any converter or executed directly via `/plan-loop` or `/plan-swarm`.

### Execute Loops (Sequential)

| Command | Source |
|---------|--------|
| `/implement-loop <task>` | Conversation context |
| `/plan-loop <plan>` | Plan file (required) |
| `/tasks-loop [prd.json]` | prd.json |
| `/beads-loop [--label]` | Beads DB |

Cancel any loop: `/cancel-loop`

### Execute Swarms (Parallel)

| Command | Source |
|---------|--------|
| `/implement-swarm <task>` | Conversation context |
| `/plan-swarm <plan>` | Plan file (required) |
| `/tasks-swarm [prd.json]` | prd.json |
| `/beads-swarm [--epic]` | Beads DB |

Cancel any swarm: `/cancel-swarm`

### Convert Formats

| Command | Output | Dependency Source |
|---------|--------|-------------------|
| `/tasks-converter <plan>` | prd.json with `dependsOn` arrays | Plan's `## Dependency Graph` table |
| `/beads-converter <plan>` | Beads issues with `bd dep add` | Plan's `## Dependency Graph` table |

Converters read the plan's `## Dependency Graph` to build file→task/bead ID maps and translate file dependencies to task dependencies. Falls back to per-file `Dependencies`/`Provides` for older plans without a Dependency Graph.

### Utilities

| Command | Purpose |
|---------|---------|
| `/codemap-creator <dir>` | Create JSON code map via LSP |
| `/codemap-creator --update <map> [--diff\|--mr\|--pr]` | Update existing codemap with changed files |
| `/document-creator <dir>` | DEVGUIDE.md generation |
| `/prompt-creator <desc>` | Create prompts, feature requests, bug reports |
| `/mr-description-creator` | PR/MR descriptions via gh/glab |
| `/reset-prd <path>` | Reset prd.json to initial state |
| `/reset-beads <epic-id>` | Reopen all tasks in a beads epic |
| `/ralph-config <json\|beads>` | Write RalphTUI config for workflow |

---

## What's In A Plan?

Plans are markdown files in `.claude/plans/` with structured sections:

```markdown
## Implementation Plan

### src/types/auth.ts [create]
[Complete code — not pseudocode]
Dependencies: —
Provides: AuthToken type, validateToken() function

### src/services/auth.ts [create]
[Complete code]
Dependencies: src/types/auth.ts
Provides: AuthService class

## Dependency Graph

| Phase | File                    | Action | Depends On              |
|-------|-------------------------|--------|-------------------------|
| 1     | `src/types/auth.ts`     | create | —                       |
| 2     | `src/services/auth.ts`  | create | `src/types/auth.ts`     |

## Exit Criteria
npm test -- auth && npm run typecheck
```

**Self-Contained Rule:** Each task must be implementable with ONLY its description. No "see design.md" allowed.

**Dependency Graph Rule:** The `## Dependency Graph` table is the source of truth for execution order. Converters read it to build `dependsOn`/`depends_on`. Files in the same phase can execute in parallel. Only real code dependencies should create phase boundaries.

---

## Code Maps (Optional)

Code maps give plan creators a head start by providing file→symbol mappings, signatures, dependencies, and export status via LSP.

```bash
# Create a codemap
/codemap-creator src/

# Update after changes (instead of recreating)
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --diff      # git diff
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --mr 123   # GitLab MR
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --pr 456   # GitHub PR
```

**All plan creators check for codemaps automatically.** When `.claude/maps/code-map-*.json` exists, plan-creator, bug-plan-creator, and code-quality-plan-creator use it for faster codebase orientation instead of exploring from scratch.

---

## Project Structure

```
your-project/
├── .claude/
│   ├── plans/          # Source of truth (plan files with Dependency Graphs)
│   ├── prd/            # prd.json files (from /tasks-converter)
│   ├── maps/           # Code maps (consumed by plan creators)
│   └── prompts/        # Generated prompts
├── .ralph-tui/         # RalphTUI config (if using)
│   └── config.toml     # Tracker, agent settings
└── .beads/             # Beads DB (if using)
```

**RalphTUI setup:** Run `ralph-tui setup` per project. See [Managing .ralph-tui/](WORKFLOW-TASKS.md#managing-ralph-tui-folder) for config details and switching trackers.

---

## Requirements

| Tool | Required? | Purpose |
|------|-----------|---------|
| None | — | Simple workflow works out of the box |
| [Beads CLI](https://github.com/steveyegge/beads) | For Beads workflow | Persistent memory across sessions |
| [Ralph TUI](https://github.com/subsy/ralph-tui) | Optional | Classic Ralph loop executor with TUI dashboard |

**Simple workflow has zero dependencies.** Add Beads for persistent memory. Add Ralph TUI if you prefer the classic Ralph Wiggum loop style over Claude Code's native Task System.

---

## Model Configuration

Edit YAML frontmatter in `essentials/commands/*.md` or `essentials/agents/*.md`:

```yaml
---
model: opus    # opus | sonnet | haiku
---
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Loop won't stop | Exit criteria must return exit code 0 |
| Wrong exit criteria | Edit plan directly, re-run loop |
| Context filling up | Plans persist outside conversation |
| prd.json not found | Use `userStories` and `passes` fields |
| Beads CLI missing | `brew tap steveyegge/beads && brew install bd` |
| Swarm runs sequentially | Check plan's Dependency Graph — every task chained to previous degrades swarm to sequential. Only declare real code dependencies. |

---

## Documentation

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Dashboard visualization with Ralph TUI
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent task tracking with Beads
- [COMPARISON.md](COMPARISON.md) — Why verification-driven loops matter

---

## Contributing

1. Fork it
2. Create your branch (`git checkout -b feature/thing`)
3. Commit changes
4. Push and open a PR

---

## Credits

- [Ralph Wiggum pattern](https://ghuntley.com/ralph/) by Geoffrey Huntley
- [Beads](https://github.com/steveyegge/beads) by Steve Yegge — Persistent memory
- [Ralph TUI](https://github.com/subsy/ralph-tui) by subsy — Classic Ralph loop executor
- Built for [Claude Code](https://claude.ai/code)

---

<div align="center">

*Plans define exit criteria. Loops run until tests pass. Done means actually done.*

</div>
