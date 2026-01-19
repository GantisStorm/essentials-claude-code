# Essentials for Claude Code

**Plan first. Implement until done.** No more "it's complete" when tests are failing.

## The Problem

Claude Code is powerful, but without structure it can:
- Start coding before understanding the full picture
- Lose track of what's done when context gets long
- Say "done" when tests are still failing
- Hallucinate on large features that exceed context

**Why this happens:** AI declares "done" when code is written, not when code works. There's no verification requirement, so "done" means "I finished typing" not "tests pass."

**The Solution:** Plan first, then loop until exit criteria pass.

```bash
/plan-creator Add user authentication with JWT
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
# Loop continues until exit criteria PASS - not until AI says "done"
```

The loop cannot end until verification passes. "Done" means actually done.

---

## Install

```bash
/plugin marketplace add GantisStorm/essentials-claude-code
/plugin install essentials@essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd
```

---

## Three Workflows

> **80% of tasks need only Simple.** Start there. Escalate only when you hit problems.

| Workflow | Commands | When to Use |
|----------|----------|-------------|
| **Simple** | `/plan-creator` → `/implement-loop` | Most tasks, single session |
| **Tasks** | Plan → `/tasks-creator` → `/tasks-loop` | RalphTUI dashboard, prd.json format |
| **Beads** | Plan → `/beads-creator` → `/beads-loop` | Multi-session, context loss, hallucinations |

```
PLANNING                              EXECUTION
┌────────────────────────────────┐    ┌────────────────────────────────────┐
│ /plan-creator                  │    │ /implement-loop (most tasks)       │
│ /bug-plan-creator              │───▶│ /tasks-loop (RalphTUI/prd.json)    │
│ /code-quality-plan-creator     │    │ /beads-loop (persistent memory)    │
└────────────────────────────────┘    └────────────────────────────────────┘
         ▲                                        │
         │                                        ▼
    Plans persist                         Loops until PASS
    in .claude/plans/                     (not until "done")
```

### When to Use Each

| Situation | Workflow |
|-----------|----------|
| Bug fix, feature, refactoring | **Simple** (start here) |
| Want RalphTUI TUI dashboard | **Tasks** |
| Want prd.json format | **Tasks** |
| AI hallucinates mid-task | **Beads** |
| Multi-day feature | **Beads** |
| Context keeps compacting | **Beads** |

---

## Simple Workflow

The default. Handles 80% of tasks.

```bash
# Stage 1: Plan
/plan-creator Add user authentication with JWT

# Review the plan - verify code is correct, exit criteria are exact commands
cat .claude/plans/user-auth-3k7f2-plan.md

# Stage 2: Execute
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
# Loop runs until exit criteria PASS
```

**What's in a plan?**
- Reference Implementation — Complete code (50-200+ lines)
- Migration Patterns — Exact before/after with line numbers
- Exit Criteria — Specific commands (`npm test -- auth`, not "run tests")

**Options:**
```bash
/implement-loop plan.md                    # Run until pass
/implement-loop plan.md --max-iterations 5 # Limit iterations
/cancel-implement                           # Stop gracefully
```

---

## Tasks Workflow (RalphTUI + prd.json)

For RalphTUI integration or when you prefer the prd.json format.

### What is prd.json?

A JSON file containing self-contained tasks following RalphTUI's schema:

```json
{
  "name": "User Authentication",
  "description": "JWT-based auth system",
  "branchName": "feature/user-auth",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add JWT validation middleware",
      "description": "## Requirements\n...\n## Reference Implementation\n```typescript\n// FULL 80+ lines of code\n```\n## Exit Criteria\nnpm test -- auth",
      "acceptanceCriteria": ["Validates tokens", "Returns 401 on invalid"],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

**Key rule:** Each task's `description` contains EVERYTHING needed to implement. The executor never reads the original plan.

### prd.json Schema

**Root Object:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Feature name |
| `description` | string | No | Brief description |
| `branchName` | string | No | Git branch |
| `userStories` | array | Yes | Task list |

**User Story Object:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique ID (US-001, US-002...) |
| `title` | string | Yes | Short title |
| `description` | string | Yes | FULL implementation details |
| `acceptanceCriteria` | string[] | Yes | Verification criteria |
| `priority` | number | No | 1=highest (default: 2) |
| `passes` | boolean | Yes | Always `false` initially |
| `dependsOn` | string[] | No | IDs of blocking tasks |

**Critical:** Use `userStories` not `tasks`, use `passes` not `status`.

### Tasks Usage

```bash
# Stage 1: Create plan
/plan-creator Add user authentication with JWT

# Stage 2: Convert to prd.json
/tasks-creator .claude/plans/user-auth-3k7f2-plan.md
# Output: .claude/prd/user-auth-3k7f2.json

# Stage 3: Execute (choose one)
/tasks-loop .claude/prd/user-auth-3k7f2.json           # Internal loop
ralph-tui run --prd .claude/prd/user-auth-3k7f2.json   # RalphTUI dashboard
```

**Options:**
```bash
/tasks-loop prd.json                    # Run until all pass
/tasks-loop prd.json --max-iterations 5 # Limit iterations
/cancel-tasks                            # Stop gracefully
```

### RalphTUI Integration

[RalphTUI](https://github.com/subsy/ralph-tui) is an AI Agent Loop Orchestrator with a terminal UI.

**Install:**
```bash
bun install -g ralph-tui
ralph-tui setup
```

**Execute with TUI dashboard:**
```bash
ralph-tui run --prd .claude/prd/feature.json
```

**Features:**
| Feature | `/tasks-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Installation | None (built-in) | Requires bun + ralph-tui |
| Interface | Terminal output | TUI dashboard |
| Multi-agent | Claude Code only | Claude, OpenCode, Factory Droid |

---

## Beads Workflow (Persistent Memory)

For multi-session work, when context compacts mid-task, or when AI hallucinates.

### What are Beads?

[Beads](https://github.com/steveyegge/beads) provides persistent, structured memory that survives session boundaries. Each bead is an atomic, self-contained task unit in a local graph database.

| Component | Purpose |
|-----------|---------|
| Requirements | Full requirements copied verbatim |
| Reference Implementation | 20-400+ lines based on complexity |
| Migration Pattern | Exact before/after for file edits |
| Exit Criteria | Specific verification commands |
| Dependencies | `depends_on`/`blocks` relationships |

**Key insight:** When context compacts, `bd ready` always shows what's next. Each bead has everything needed—no reading other files.

### Beads Setup

**Install:**
```bash
brew tap steveyegge/beads && brew install bd
# Or: npm install -g @beads/bd
```

**Initialize (choose one):**
| Mode | Command | When to Use |
|------|---------|-------------|
| Stealth | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected Branch | `bd init --branch beads-sync` | When main is protected |

### Essential Beads Commands

```bash
bd ready                        # List tasks with no blockers
bd blocked                      # Show tasks waiting on dependencies
bd list -l ralph                # List tasks with ralph label
bd show <id>                    # Full task details
bd create "Title" -p 0          # Create P0 task
bd update <id> --status in_progress  # Start working
bd close <id> --reason "Done"   # Complete task
bd sync                         # Force immediate sync
```

### Beads Usage

```bash
# Stage 1: Create plan
/plan-creator Add complete auth system

# Stage 2: Convert to beads
/beads-creator .claude/plans/auth-system-3k7f2-plan.md
# Creates beads with 'ralph' label (RalphTUI compatible)

# Stage 3: Execute (choose one)
/beads-loop                                      # Internal loop
/beads-loop --label custom-label                 # Filter by label
ralph-tui run --tracker beads --epic <epic-id>   # RalphTUI dashboard
```

**Options:**
```bash
/beads-loop                         # Run until no ready beads
/beads-loop --max-iterations 5      # Limit iterations
/beads-loop --label my-feature      # Filter by label
/cancel-beads                        # Stop gracefully
```

### RalphTUI + Beads

Beads are created with `ralph` label by default for RalphTUI compatibility.

```bash
ralph-tui run --tracker beads --epic <epic-id>
```

---

## Commands Reference

### Planning Commands

| Command | Purpose | Output |
|---------|---------|--------|
| `/plan-creator <task>` | Create implementation plan | `.claude/plans/{task}-{hash}-plan.md` |
| `/bug-plan-creator <error> <desc>` | Bug investigation plan | `.claude/plans/bug-fix-{desc}-{hash}-plan.md` |
| `/code-quality-plan-creator <files>` | Code quality analysis | `.claude/plans/code-quality-{file}-{hash}-plan.md` |
| `/tasks-creator <plan>` | Convert plan → prd.json | `.claude/prd/{name}.json` |
| `/beads-creator <plan>` | Convert plan → Beads | Beads database |

### Loop Commands

All loops run until complete. Optional: `--max-iterations N` to limit.

| Command | Completes When | Cancel |
|---------|----------------|--------|
| `/implement-loop <plan>` | Exit criteria pass | `/cancel-implement` |
| `/tasks-loop [prd-path]` | All tasks `passes: true` | `/cancel-tasks` |
| `/beads-loop [--label X]` | No ready beads | `/cancel-beads` |

### Utility Commands

| Command | Purpose |
|---------|---------|
| `/codemap-creator [dir]` | Generate JSON code map |
| `/document-creator <dir>` | Generate DEVGUIDE.md |
| `/prompt-creator <desc>` | Create quality prompts |
| `/mr-description-creator` | Create PR/MR description |

---

## How Loops Work

All loops use the [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) stop-hook pattern: setup creates a marker file, stop hooks intercept exit attempts, and the loop continues until completion criteria pass.

### `/implement-loop`

1. Read plan file and create todos with TodoWrite
2. Implement each todo following plan instructions
3. Run exit criteria verification command from plan
4. **Completion:** Exit criteria command passes (exit code 0)

State: `.claude/implement-loop.local.md`

### `/tasks-loop`

1. Read prd.json and find pending tasks (`passes: false`)
2. Pick highest priority task with no blocking dependencies
3. Implement using self-contained task description
4. Update `passes: true` in prd.json
5. **Completion:** All tasks have `passes: true`

State: `.claude/tasks-loop-active` (marker), prd.json (task state)

### `/beads-loop`

1. Run `bd ready` to find tasks with no blockers
2. Pick highest priority ready task
3. Run `bd update <id> --status in_progress`
4. Implement using self-contained bead description
5. Run `bd close <id>` when complete
6. **Completion:** `bd ready` returns no tasks

State: `.claude/beads-loop-active` (marker), beads DB (task state)

---

## The Self-Contained Rule

Each task/bead must be implementable with ONLY its description. No reading other files.

| Bad | Good |
|-----|------|
| "See design.md" | FULL code (50-200+ lines) in description |
| "Run tests" | `npm test -- stripe-price` |
| "Update entity" | File + line numbers + before/after code |

**Why?** When context compacts, the executor only has the task description. If it says "see plan," the executor is lost.

---

## Project Structure

| Directory | Contents |
|-----------|----------|
| `.claude/plans/` | Architectural plans (source of truth) |
| `.claude/prd/` | prd.json files (Tasks workflow) |
| `.claude/maps/` | Code maps |
| `.claude/prompts/` | Generated prompts |
| `.beads/` | Beads database (created by `bd init`) |

---

## Model Configuration

All commands and agents default to `opus` for maximum quality. You can customize the model by editing the YAML frontmatter.

### Changing the Model

Commands are in `essentials/commands/*.md`, agents in `essentials/agents/*.md`. Both use the same `model` field:

```yaml
---
description: "Execute beads iteratively..."
argument-hint: "[--label <label>]"
model: opus   # Change to: opus, sonnet, or haiku
---
```

**Available models:**
- `opus` — Best quality, complex reasoning (default)
- `sonnet` — Balanced quality/cost
- `haiku` — Fast and cheap, simple tasks

### Files to Modify

**Commands** (`essentials/commands/`):

| Command | File | Line |
|---------|------|------|
| `/implement-loop` | `implement-loop.md` | 6 |
| `/tasks-loop` | `tasks-loop.md` | 6 |
| `/beads-loop` | `beads-loop.md` | 6 |
| `/cancel-implement` | `cancel-implement.md` | 5 |
| `/cancel-tasks` | `cancel-tasks.md` | 5 |
| `/cancel-beads` | `cancel-beads.md` | 5 |
| `/plan-creator` | `plan-creator.md` | 6 |
| Other creators | `<name>.md` | 5-6 |

**Agents** (`essentials/agents/`):

| Agent | File | Line |
|-------|------|------|
| plan-creator | `plan-creator-default.md` | 15 |
| bug-plan-creator | `bug-plan-creator-default.md` | 15 |
| code-quality-plan-creator | `code-quality-plan-creator-default.md` | 15 |
| beads-creator | `beads-creator-default.md` | 6 |
| tasks-creator | `tasks-creator-default.md` | 6 |
| codemap-creator | `codemap-creator-default.md` | 15 |
| document-creator | `document-creator-default.md` | 11 |
| prompt-creator | `prompt-creator-default.md` | 11 |
| mr-description-creator | `mr-description-creator-default.md` | 9 |

### Cost Optimization Example

To reduce costs for iterative execution, change loops and cancels to `haiku`:

```bash
# In essentials/commands/implement-loop.md, change:
model: opus
# to:
model: haiku
```

---

## Best Practices

1. **Start simple** — 80% of tasks need only `/plan-creator` → `/implement-loop`
2. **Exit criteria are exact commands** — Not "tests pass" but `npm test -- auth`
3. **Review before looping** — Loops execute autonomously. Fixing plans is cheap; debugging bad code is expensive.
4. **Token cost is a tradeoff** — Tasks/Beads workflows copy code into each task for context recovery. Expensive but intentional.

---

## Requirements

| Tool | For | Install |
|------|-----|---------|
| Beads | `/beads-creator`, `/beads-loop` | [steveyegge/beads](https://github.com/steveyegge/beads) |
| RalphTUI | TUI dashboard for Tasks/Beads | [subsy/ralph-tui](https://github.com/subsy/ralph-tui) (optional) |
| Built-in LSP | `/code-quality-plan-creator`, `/codemap-creator`, `/document-creator` | Already in Claude Code |

---

## Guides

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Single-session features, bug fixes, refactoring
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — RalphTUI integration with prd.json format
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent memory that survives sessions
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters

---

## License

MIT
