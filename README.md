<div align="center">

<img src="logo.png" alt="Essentials for Claude Code" width="450"/>

# Essentials for Claude Code

[![Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](https://unlicense.org/)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Verification-driven loops for brownfield development.**

A Claude Code plugin for adding features to existing codebases. Plans define exit criteria. Loops run until tests pass. Done means actually done.

Integrates with [Ralph TUI](https://github.com/subsy/ralph-tui) and [Beads](https://github.com/steveyegge/beads) for dashboard visualization and persistent task tracking.

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

**Zero external dependencies.** Loop runs until exit criteria pass. Swarm auto-detects workers.

---

## Powered by Claude Code's Task System

Our loop and swarm commands use Claude Code's **built-in Task Management System** (v2.1.19+).

**This is still Ralph Wiggum** - same verification-driven loops, same "done means actually done" philosophy. Anthropic just made the plumbing native. What the community built with stop hooks and external files now has first-class support.

> **RalphTUI still works.** For Tasks/Beads workflows, you can use [RalphTUI](https://github.com/subsy/ralph-tui) as an alternative executor if you want a TUI dashboard.

### Same Concept, Better Tooling

| Before (Workarounds) | Now (Native) |
|----------------------|--------------|
| External plan.md for tracking | Built-in `~/.claude/tasks/` storage |
| Stop hooks to check completion | Status lifecycle: `pending` → `in_progress` → `completed` |
| Fresh sessions to fight context rot | Tasks persist across context compaction |
| Flat TodoWrite lists | Dependency graph with `blockedBy` |
| Manual multi-session coordination | `CLAUDE_CODE_TASK_LIST_ID` env var |

**The core loop is unchanged:** Plan → Implement → Verify → Loop if fail → Done when pass.

### What Tasks Do Well

- **Dependency management**: Task #3 blocked by #1 and #2 literally cannot start until both complete
- **Visual progress**: Press `ctrl+t` to see live task tree with status
- **Parallel coordination**: Multiple workers share one task list, no conflicts
- **Persistence**: Survives context compaction, stored in `~/.claude/tasks/`

### What Tasks Don't Do

`TaskList` shows ID, subject, status, and blockedBy - **but NOT description**. To see implementation details, you must call `TaskGet` for each task individually.

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

```
TaskCreate({ subject: "Set up database" })           // #1
TaskCreate({ subject: "Create auth middleware" })    // #2
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })     // #2 waits for #1
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

### Parallel Swarm Coordination

Workers spawn simultaneously and self-coordinate via shared task list:

```
Worker-1: TaskList → Claim #1 → Execute → Complete → Claim #3 (now unblocked)
Worker-2: TaskList → Claim #2 → Execute → Complete → Claim #4 (now unblocked)
Worker-3: TaskList → All blocked → Wait → Claim next available...

All workers read/write same TaskList. No central coordinator.
Dependencies automatically respected.
```

### Multi-Session Persistence

Tasks persist across sessions with `CLAUDE_CODE_TASK_LIST_ID`:

```bash
# Per terminal session
CLAUDE_CODE_TASK_LIST_ID="my-project" claude

# Or in .claude/settings.json
{ "env": { "CLAUDE_CODE_TASK_LIST_ID": "my-project" } }
```

Start a new session tomorrow - your task list is still there.

---

## Workflows

| Workflow | Best For | Loop | Swarm | Alt Executor |
|----------|----------|------|-------|--------------|
| **Simple (context)** | Quick tasks | `/implement-loop` | `/implement-swarm` | — |
| **Simple (plan)** | 80% of tasks | `/plan-loop` | `/plan-swarm` | — |
| **Tasks** | prd.json format | `/tasks-loop` | `/tasks-swarm` | RalphTUI |
| **Beads** | Multi-session | `/beads-loop` | `/beads-swarm` | RalphTUI |

**Our commands use Claude Code's Task System** for dependency tracking and `ctrl+t` progress.
**RalphTUI is an alternative executor** for Tasks/Beads workflows if you want a TUI dashboard.

**Choose Loop:** Sequential, verification-enforced, one task at a time.
**Choose Swarm:** Parallel workers, auto-scales, faster for independent tasks.

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

### Tasks (prd.json)

```bash
/plan-creator Add JWT authentication
/tasks-converter .claude/plans/jwt-auth-plan.md
/tasks-loop .claude/prd/jwt-auth.json             # Sequential
/tasks-swarm .claude/prd/jwt-auth.json            # Parallel
# Or: ralph-tui run --prd .claude/prd/jwt-auth.json
```

### Beads (Persistent Memory)

```bash
bd init
/plan-creator Add JWT authentication
/beads-converter .claude/plans/jwt-auth-plan.md
/beads-loop                                        # Sequential
/beads-swarm                                       # Parallel (auto workers)
# Or: ralph-tui run --tracker beads --epic <epic-id>
```

---

## How Loops Work

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Plan ──→ Implement ──→ Run Exit Criteria          │
│                              │                      │
│                         Pass? ───→ DONE ✓           │
│                              │                      │
│                         Fail? ───→ Fix ──┐          │
│                              ▲           │          │
│                              └───────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

The loop **cannot** end until verification passes. No exceptions.

---

## Commands

### Plan Creators

| Command | Use For |
|---------|---------|
| `/plan-creator <feature>` | New features (brownfield development) |
| `/bug-plan-creator <error> <desc>` | Bug fixes, root cause analysis |
| `/code-quality-plan-creator <files>` | Refactoring, dead code, security |

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

| Command | Output |
|---------|--------|
| `/tasks-converter <plan>` | prd.json for RalphTUI |
| `/beads-converter <plan>` | Beads issues |

### Utilities

| Command | Purpose |
|---------|---------|
| `/codemap-creator [dir]` | JSON code map via LSP |
| `/document-creator <dir>` | DEVGUIDE.md generation |
| `/prompt-creator <desc>` | Create prompts, feature requests, bug reports |
| `/mr-description-creator` | PR/MR descriptions via gh/glab |
| `/reset-prd <path>` | Reset prd.json to initial state |
| `/reset-beads <epic-id>` | Reopen all tasks in a beads epic |
| `/ralph-config <json\|beads>` | Write RalphTUI config for workflow |

---

## What's In A Plan?

Plans are markdown files in `.claude/plans/`:

```markdown
## Reference Implementation
[Complete code, 50-200+ lines — not pseudocode]

## Migration Patterns
[Exact before/after with file:line references]

## Exit Criteria
npm test -- auth && npm run typecheck
[Specific commands, not "run tests"]
```

**Self-Contained Rule:** Each task must be implementable with ONLY its description. No "see design.md" allowed.

---

## Project Structure

```
your-project/
├── .claude/
│   ├── plans/          # Source of truth
│   ├── prd/            # prd.json files
│   ├── maps/           # Code maps
│   └── prompts/        # Generated prompts
├── .ralph-tui/         # RalphTUI config (if using)
│   └── config.toml     # Tracker, agent settings
└── .beads/             # Beads DB (if using)
```

**RalphTUI setup:** Run `ralph-tui setup` per project. See [Managing .ralph-tui/](WORKFLOW-TASKS.md#managing-ralph-tui-folder) for config details and switching trackers.

---

## Requirements

| Tool | Required? | Install |
|------|-----------|---------|
| None | — | Simple workflow works out of the box |
| [Beads CLI](https://github.com/steveyegge/beads) | For Beads workflow | `brew tap steveyegge/beads && brew install bd` |
| [RalphTUI](https://github.com/subsy/ralph-tui) | For TUI dashboard | See [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md#ralphtui-optional) |

**Note:** RalphTUI is for **execution only**. This plugin provides planning and task conversion.

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

---

## Documentation

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Zero-dependency default (loop + swarm)
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — prd.json + RalphTUI (loop + swarm)
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent multi-session (loop + swarm)
- [COMPARISON.md](COMPARISON.md) — Why verification matters

---

## Contributing

1. Fork it
2. Create your branch (`git checkout -b feature/thing`)
3. Commit changes
4. Push and open a PR

---

## Credits

- [Ralph Wiggum pattern](https://ghuntley.com/ralph/) by Geoffrey Huntley
- [RalphTUI](https://github.com/subsy/ralph-tui) by subsy
- [Beads](https://github.com/steveyegge/beads) by Steve Yegge
- Built for [Claude Code](https://claude.ai/code)

---

<div align="center">

*"Done" means tests pass. No exceptions.*

</div>
