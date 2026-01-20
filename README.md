<div align="center">

<img src="https://www.freelogovectors.net/wp-content/uploads/2023/05/essentials_logo_freelogovectors.net_.png" alt="Essentials" width="400"/>

# Essentials for Claude Code

### *"The loop cannot end until verification passes."*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Verification-driven loops for Claude Code. Plans define exit criteria. Loops run until tests pass.**

With Ralph TUI dashboard and Beads persistence support.

[Quick Start](#-quick-start) | [Commands](#-commands) | [How It Works](#-how-it-works) | [Workflows](#-optional-advanced-workflows) | [Troubleshooting](#-troubleshooting)

</div>

---

## What is this?

Essentials is a Claude Code plugin that enforces verification-driven completion. The AI cannot declare "done" — only passing tests can.

```
Without Essentials:                          With Essentials:
  AI writes code → "Done!"                     /plan-creator Add auth
  You run tests → 3 failing                    /implement-loop plan.md
  "Fix these" → "Fixed!"                       [loop runs, fails, fixes, retries]
  You run tests → 1 still failing              "Exit criteria passed" → Actually done
  [repeat until you give up]
```

## Why "Essentials"?

Because verification-enforced completion is essential. Plans include exact exit criteria. Loops retry until those criteria pass. "Done" means objectively done with passing tests, not "I wrote code."

---

## Requirements

**Zero dependencies for the Simple workflow.** Just install and go.

Optional integrations:

| Tool | Required? | For | Install |
|------|-----------|-----|---------|
| **None** | — | Simple workflow | Just install the plugin |
| Beads CLI | Optional | `/beads-creator`, `/beads-loop` | [steveyegge/beads](https://github.com/steveyegge/beads) |
| RalphTUI | Optional | TUI dashboard | [subsy/ralph-tui](https://github.com/subsy/ralph-tui) |
| Context7 | Optional | Enhanced docs in plans | MCP server |
| SearXNG | Optional | Web search in plans | MCP server |
| Built-in LSP | Included | `/code-quality-plan-creator`, `/codemap-creator` | Already in Claude Code |

---

## Installation

### From Marketplace

```bash
# Add the marketplace
/plugin marketplace add GantisStorm/essentials-claude-code

# Install the plugin
/plugin install essentials@essentials-claude-code

# Create directories
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd

# Restart Claude Code
```

### From GitHub

```bash
/plugin install https://github.com/GantisStorm/essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd
```

### Local Development

```bash
git clone https://github.com/GantisStorm/essentials-claude-code.git
cd essentials-claude-code
claude --plugin-dir $(pwd)
```

---

## Quick Start

```bash
# Create a plan with exit criteria
/plan-creator Add user authentication with JWT

# Review the plan
cat .claude/plans/user-auth-3k7f2-plan.md

# Execute until tests pass
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
# Loop continues until exit criteria PASS
```

That's it. No external tools required. The loop runs until your tests pass.

---

## Commands

### Planning

| Command | What it does | Output |
|---------|--------------|--------|
| `/plan-creator <task>` | Create implementation plan with exit criteria | `.claude/plans/{task}-{hash}-plan.md` |
| `/bug-plan-creator <error> <desc>` | Deep bug investigation plan | `.claude/plans/bug-fix-{desc}-{hash}-plan.md` |
| `/code-quality-plan-creator <files>` | LSP-powered code quality analysis | `.claude/plans/code-quality-{file}-{hash}-plan.md` |

### Execution Loops

| Command | Completes When | Cancel |
|---------|----------------|--------|
| `/implement-loop <plan>` | Exit criteria pass | `/cancel-implement` |
| `/tasks-loop [prd-path]` | All tasks `passes: true` | `/cancel-tasks` |
| `/beads-loop [--label X]` | No ready beads remain | `/cancel-beads` |

### Utilities

| Command | What it does |
|---------|--------------|
| `/codemap-creator [dir]` | Generate JSON code map with LSP |
| `/document-creator <dir>` | Generate DEVGUIDE.md documentation |
| `/prompt-creator <desc>` | Create quality prompts |
| `/mr-description-creator` | Create PR/MR description via gh/glab CLI |

### Converters

| Command | What it does |
|---------|--------------|
| `/tasks-creator <plan>` | Convert plan to prd.json format |
| `/beads-creator <plan>` | Convert plan to beads format |

---

## How It Works

```
         "Add user authentication"
                   |
                   v
        +--------------------+
        |    Plan Creator    |  <- Full code + exit criteria
        +--------------------+
                   |
                   v
        +--------------------+
        |   Implement Loop   |  <- Execute todos from plan
        +--------------------+
                   |
                   v
        +--------------------+
        |  Run Exit Criteria |  <- npm test -- auth
        +--------------------+
                   |
          Pass?   |   Fail?
           ↓             ↓
        +------+    +--------+
        | Done |    | Fix it |──→ Run Exit Criteria again
        +------+    +--------+
```

### The Loops

All loops use the [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) stop-hook pattern. **No external tools required** — the loops are built into this plugin.

| Loop | How it works |
|------|--------------|
| **implement-loop** | Read plan → Create todos → Implement → Run exit criteria → Pass? Done. Fail? Fix and retry. |
| **tasks-loop** | Read prd.json → Find pending tasks → Implement → Mark `passes: true` → Repeat until all pass. |
| **beads-loop** | Run `bd ready` → Pick task → Implement → `bd close` → Repeat until no ready beads. |

### What's in a Plan?

Plans are the source of truth. Each plan contains:

- **Reference Implementation** — Complete code (50-200+ lines)
- **Migration Patterns** — Exact before/after with line numbers
- **Exit Criteria** — Specific commands (`npm test -- auth`, not "run tests")
- **Architecture** — Current system understanding
- **Testing Strategy** — What tests to add

---

## The Self-Contained Rule

Each task/bead must be implementable with ONLY its description.

| Bad | Good |
|-----|------|
| "See design.md" | FULL code (50-200+ lines) in description |
| "Run tests" | `npm test -- stripe-price` |
| "Update entity" | File + line numbers + before/after code |

**Why?** When context compacts, the executor only has the task description. No lookups allowed.

---

## Optional: Advanced Workflows

> **Most users only need the Simple workflow above.** The following are optional for specific use cases.

### Tasks Workflow

For prd.json format or RalphTUI dashboard integration.

```bash
/plan-creator Add user authentication with JWT
/tasks-creator .claude/plans/user-auth-3k7f2-plan.md   # Convert to prd.json
/tasks-loop .claude/prd/user-auth-3k7f2.json           # Built-in loop
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

### Beads Workflow

For multi-session work, context recovery, or when AI hallucinates mid-task.

**Requires:** [Beads CLI](https://github.com/steveyegge/beads) (`brew tap steveyegge/beads && brew install bd`)

```bash
bd init                                                  # Initialize beads DB
/plan-creator Add complete auth system
/beads-creator .claude/plans/auth-system-3k7f2-plan.md   # Convert to beads
/beads-loop                                              # Built-in loop
# OR: ralph-tui run --tracker beads --epic <id>          # Optional: RalphTUI dashboard
```

**When to use Beads:**
- Multi-day features spanning sessions
- AI hallucinates or loses track mid-task
- Context keeps compacting
- Need persistent memory across sessions

See [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) for full documentation.

---

## Project Structure

```
.claude/
├── plans/              # Architectural plans (source of truth)
├── prd/                # prd.json files (Tasks workflow)
├── maps/               # Code maps from codemap-creator
└── prompts/            # Generated prompts

.beads/                 # Beads database (if using Beads workflow)

essentials/
├── commands/           # 15 slash commands
├── agents/             # Backing agents for commands
├── hooks/              # Stop hook implementations
├── scripts/            # Setup scripts for loops
└── skills/             # github-cli and gitlab-cli skills
```

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

## Troubleshooting

**Loop not stopping?**
Check that your exit criteria command returns exit code 0 on success. The loop only stops when the command passes.

**Exit criteria wrong?**
Edit the plan file directly. Plans are markdown — just fix the exit criteria section and re-run the loop.

**Want to start over?**
Use the cancel command (`/cancel-implement`, `/cancel-tasks`, or `/cancel-beads`) then start fresh.

**Context filling up?**
Plans live in `.claude/plans/` (external files). When context compacts, the loop re-reads the plan and continues from the todo list.

**Tasks not found in prd.json?**
Use `userStories` (not `tasks`) and `passes` (not `status`). See the schema above.

**Beads CLI not found?**
Install with: `brew tap steveyegge/beads && brew install bd`

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

## Contributing

PRs welcome! This project is friendly to first-time contributors.

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes
4. Push to the branch
5. Open a PR

---

## Credits

- [Ralph Wiggum loop pattern](https://ghuntley.com/ralph/) by Geoffrey Huntley
- Built for [Claude Code](https://claude.ai/code)
- Inspired by every developer tired of AI saying "done" when tests still fail

---

<div align="center">

**Made with verification and determination**

*"Done means actually done."*

MIT License

</div>
