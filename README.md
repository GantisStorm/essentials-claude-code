# Essentials for Claude Code

**Verification-enforced completion for Claude Code.** Plans define exit criteria. Loops run until those criteria pass. The AI cannot declare "done" — only passing tests can.

## Quick Start

```bash
# Install
/plugin marketplace add GantisStorm/essentials-claude-code
/plugin install essentials@essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd

# Use (zero dependencies required)
/plan-creator Add user authentication with JWT
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
# Loop continues until exit criteria PASS
```

That's it. No external tools required. The loop runs until your tests pass.

---

## Why This Exists

```
Without Essentials:                          With Essentials:
  AI writes code → "Done!"                     /plan-creator Add auth
  You run tests → 3 failing                    /implement-loop plan.md
  "Fix these" → "Fixed!"                       [loop runs, fails, fixes, retries]
  You run tests → 1 still failing              "Exit criteria passed" → Done
  [repeat until you give up]
```

The loop cannot end until verification passes. "Done" means actually done.

---

## How It Works

**15 commands** following one pattern:

```
1. CREATE PLAN     →  Architectural plan with full code + exit criteria
2. EXECUTE LOOP    →  Implement until exit criteria PASS
3. VERIFIED DONE   →  Loop ends only when tests pass
```

### The Simple Workflow (Start Here)

Handles **80% of tasks** with zero external dependencies:

```bash
# Stage 1: Create plan with exit criteria
/plan-creator Add user authentication with JWT

# Stage 2: Review the plan
cat .claude/plans/user-auth-3k7f2-plan.md

# Stage 3: Execute until done
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
```

**What's in a plan?**
- **Reference Implementation** — Complete code (50-200+ lines)
- **Migration Patterns** — Exact before/after with line numbers
- **Exit Criteria** — Specific commands (`npm test -- auth`, not "run tests")

**Loop options:**
```bash
/implement-loop plan.md                    # Run until exit criteria pass
/implement-loop plan.md --max-iterations 5 # Limit iterations
/cancel-implement                           # Stop gracefully
```

---

## Commands

### Planning

| Command | Purpose | Output |
|---------|---------|--------|
| `/plan-creator <task>` | Create implementation plan | `.claude/plans/{task}-{hash}-plan.md` |
| `/bug-plan-creator <error> <desc>` | Bug investigation plan | `.claude/plans/bug-fix-{desc}-{hash}-plan.md` |
| `/code-quality-plan-creator <files>` | Code quality analysis | `.claude/plans/code-quality-{file}-{hash}-plan.md` |

### Execution

| Command | Completes When | Cancel |
|---------|----------------|--------|
| `/implement-loop <plan>` | Exit criteria pass | `/cancel-implement` |
| `/tasks-loop [prd-path]` | All tasks `passes: true` | `/cancel-tasks` |
| `/beads-loop [--label X]` | No ready beads | `/cancel-beads` |

### Utilities

| Command | Purpose |
|---------|---------|
| `/codemap-creator [dir]` | Generate JSON code map |
| `/document-creator <dir>` | Generate DEVGUIDE.md |
| `/prompt-creator <desc>` | Create quality prompts |
| `/mr-description-creator` | Create PR/MR description |

---

## How Loops Work

All loops use the [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) stop-hook pattern. **No external tools required** — the loops are built into this plugin.

### `/implement-loop` (Recommended)

```
Plan → TodoWrite → Implement → Run Exit Criteria → Pass? → Done
                                      ↓ Fail
                              Fix → Run Exit Criteria → ...
```

1. Read plan file, create todos
2. Implement each todo following plan
3. Run exit criteria verification command
4. **Loop continues until exit criteria pass (exit code 0)**

State: `.claude/implement-loop.local.md`

### `/tasks-loop` (Optional — for prd.json format)

Works without RalphTUI. The internal loop handles everything.

1. Read prd.json, find pending tasks (`passes: false`)
2. Pick highest priority task with no blocking dependencies
3. Implement using self-contained task description
4. Update `passes: true` in prd.json
5. **Loop continues until all tasks pass**

State: `.claude/tasks-loop-active`, `prd.json`

### `/beads-loop` (Optional — requires Beads CLI)

Works without RalphTUI. The internal loop handles everything.

1. Run `bd ready` to find tasks with no blockers
2. Pick highest priority ready task
3. Implement using self-contained bead description
4. Run `bd close <id>` when complete
5. **Loop continues until no ready beads remain**

State: `.claude/beads-loop-active`, beads DB

---

## Optional: Advanced Workflows

> **Most users only need the Simple workflow above.** The following are optional for specific use cases.

### Tasks Workflow (Optional)

For prd.json format or RalphTUI dashboard integration.

```bash
/plan-creator Add user authentication with JWT
/tasks-creator .claude/plans/user-auth-3k7f2-plan.md   # Convert to prd.json
/tasks-loop .claude/prd/user-auth-3k7f2.json           # Built-in loop (no external tools)
# OR: ralph-tui run --prd .claude/prd/user-auth.json   # Optional: RalphTUI dashboard
```

**prd.json schema:**
```json
{
  "name": "Feature Name",
  "userStories": [
    {
      "id": "US-001",
      "title": "Task title",
      "description": "FULL implementation details (50-200+ lines)",
      "acceptanceCriteria": ["Specific criterion"],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

**Key fields:** Use `userStories` (not `tasks`), use `passes` (not `status`).

See [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) for full schema reference.

### Beads Workflow (Optional)

For multi-session work, context recovery, or when AI hallucinates mid-task.

**Requires:** [Beads CLI](https://github.com/steveyegge/beads) (`brew tap steveyegge/beads && brew install bd`)

```bash
bd init                                                  # Initialize beads DB
/plan-creator Add complete auth system
/beads-creator .claude/plans/auth-system-3k7f2-plan.md   # Convert to beads
/beads-loop                                              # Built-in loop (no external tools)
# OR: ralph-tui run --tracker beads --epic <id>          # Optional: RalphTUI dashboard
```

**When to use Beads:**
- Multi-day features spanning sessions
- AI hallucinates or loses track mid-task
- Context keeps compacting
- Need persistent memory across sessions

See [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) for full documentation.

---

## The Self-Contained Rule

Each task/bead must be implementable with ONLY its description.

| Bad | Good |
|-----|------|
| "See design.md" | FULL code (50-200+ lines) in description |
| "Run tests" | `npm test -- stripe-price` |
| "Update entity" | File + line numbers + before/after code |

**Why?** When context compacts, the executor only has the task description.

---

## Project Structure

| Directory | Contents |
|-----------|----------|
| `.claude/plans/` | Architectural plans (source of truth) |
| `.claude/prd/` | prd.json files (Tasks workflow) |
| `.claude/maps/` | Code maps |
| `.claude/prompts/` | Generated prompts |
| `.beads/` | Beads database (if using Beads workflow) |

---

## Requirements

| Tool | Required? | For | Install |
|------|-----------|-----|---------|
| **None** | — | Simple workflow | Just install the plugin |
| Beads CLI | Optional | `/beads-creator`, `/beads-loop` | [steveyegge/beads](https://github.com/steveyegge/beads) |
| RalphTUI | Optional | TUI dashboard | [subsy/ralph-tui](https://github.com/subsy/ralph-tui) |
| Context7 | Optional | Enhanced docs in plans | MCP server |
| SearXNG | Optional | Web search in plans | MCP server |
| Built-in LSP | Included | `/code-quality-plan-creator`, `/codemap-creator` | Already in Claude Code |

**The Simple workflow has zero dependencies.** Everything else is optional.

---

## Model Configuration

All commands default to `opus`. Change by editing YAML frontmatter:

```yaml
---
model: opus   # Options: opus, sonnet, haiku
---
```

**Files:** `essentials/commands/*.md` and `essentials/agents/*.md`

| Model | Best For |
|-------|----------|
| `opus` | Complex reasoning (default) |
| `sonnet` | Balanced quality/cost |
| `haiku` | Fast, cheap, simple tasks |

---

## Best Practices

1. **Start with Simple** — 80% of tasks need only `/plan-creator` → `/implement-loop`
2. **Exit criteria are exact commands** — `npm test -- auth`, not "run tests"
3. **Review before looping** — Fixing plans is cheap; debugging bad code is expensive
4. **Escalate when needed** — Use Tasks/Beads only for multi-session or context issues

---

## Guides

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Optional: prd.json format, RalphTUI integration
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Optional: Persistent memory across sessions
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters

---

## License

MIT
