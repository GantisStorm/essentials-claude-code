# Tasks Workflow (Optional)

> **This workflow is optional.** Use the [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Tasks when you want the prd.json format or RalphTUI's visual dashboard.

## When to Use This Workflow

- You want the prd.json format for task tracking
- You want RalphTUI's TUI dashboard (optional)
- You prefer JSON-based task management

**Note:** The built-in `/tasks-loop` works without RalphTUI. RalphTUI is only needed if you want the visual dashboard.

---

## Overview

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│ PLANNING                        │     │ EXECUTION (choose one)          │
│                                 │     │                                 │
│ /plan-creator <task>            │     │ /tasks-loop prd.json            │
│        ↓                        │────▶│   (built-in, no dependencies)   │
│ /tasks-creator plan.md          │     │                                 │
│                                 │     │ ralph-tui run --prd prd.json    │
│ Output: .claude/prd/*.json      │     │   (optional TUI dashboard)      │
└─────────────────────────────────┘     └─────────────────────────────────┘
```

---

## What is prd.json?

A JSON file containing self-contained tasks:

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

---

## Usage

### Stage 1: Create Plan
```bash
/plan-creator Add user authentication with JWT
```

### Stage 2: Convert to prd.json
```bash
/tasks-creator .claude/plans/user-auth-3k7f2-plan.md
# Output: .claude/prd/user-auth-3k7f2.json
```

### Stage 3: Execute

**Option A: Built-in Loop (no dependencies)**
```bash
/tasks-loop .claude/prd/user-auth-3k7f2.json
/tasks-loop .claude/prd/user-auth-3k7f2.json --max-iterations 5  # Limit iterations
/cancel-tasks                                                     # Stop gracefully
```

**Option B: RalphTUI Dashboard (optional)**
```bash
# Install RalphTUI first: bun install -g ralph-tui && ralph-tui setup
ralph-tui run --prd .claude/prd/user-auth-3k7f2.json
```

---

## Execution Comparison

| Feature | `/tasks-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Installation | None (built-in) | Requires bun + ralph-tui |
| Interface | Terminal output | TUI dashboard |
| Dependencies | Zero | RalphTUI |
| Pause/Resume | `/cancel-tasks` + restart | Keyboard shortcuts |
| Multi-agent | Claude Code only | Claude, OpenCode, Factory Droid |

---

## prd.json Schema

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Feature name |
| `description` | string | No | Brief description |
| `branchName` | string | No | Git branch |
| `userStories` | array | Yes | Task list |
| `metadata` | object | No | Optional metadata |

### User Story Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique ID (US-001, US-002...) |
| `title` | string | Yes | Short title |
| `description` | string | Yes | FULL implementation details |
| `acceptanceCriteria` | string[] | Yes | Verification criteria |
| `priority` | number | No | 1=highest (default: 2) |
| `passes` | boolean | Yes | Always `false` initially |
| `dependsOn` | string[] | No | IDs of blocking tasks |

### Critical Schema Rules

- Use `userStories` — NOT `tasks` or `items`
- Use `passes: false` — NOT `status: "pending"`
- Use `acceptanceCriteria` — NOT `criteria` or `tests`
- Use `dependsOn` — NOT `dependencies` or `blockedBy`

---

## The Self-Contained Rule

Each task must be implementable with ONLY its description.

| Bad | Good |
|-----|------|
| "See plan for details" | FULL code (50-200+ lines) in description |
| "Run tests" | `npm test -- auth-middleware` |
| "Update the file" | File + line numbers + BEFORE/AFTER code |

**Litmus test:** Could someone implement this with ONLY the task description?

---

## Context Recovery

If you lose track:

```bash
# List prd files
ls .claude/prd/

# Read a prd file
cat .claude/prd/<name>.json | jq '.'

# Find pending tasks
jq '[.userStories[] | select(.passes == false)]' .claude/prd/<name>.json

# Count completed vs pending
jq '{completed: [.userStories[] | select(.passes == true)] | length, pending: [.userStories[] | select(.passes == false)] | length}' .claude/prd/<name>.json
```

---

## RalphTUI (Optional)

[RalphTUI](https://github.com/subsy/ralph-tui) is an AI Agent Loop Orchestrator with a terminal UI.

**Note:** RalphTUI is for **execution only**. Use this plugin's `/plan-creator` → `/tasks-creator` workflow to create tasks. RalphTUI then runs them.

### Prerequisites

**Bun Runtime (Required)**

RalphTUI requires Bun >= 1.0.0 as its runtime. While you can install the package using npm, Bun must be installed to run ralph-tui.

```bash
# macOS/Linux
curl -fsSL https://bun.sh/install | bash

# macOS (Homebrew)
brew install oven-sh/bun/bun

# Verify
bun --version   # Should be 1.0.0 or higher
```

**AI Coding Agent**

RalphTUI orchestrates AI coding agents. You need at least one:
- **Claude Code** — Anthropic's official CLI (you have this)
- **OpenCode** — Open-source alternative
- **Factory Droid** — Factory Droid CLI

### Installation

```bash
# Install globally with Bun (recommended)
bun install -g ralph-tui

# Or with npm
npm install -g ralph-tui

# Or run without installing
bunx ralph-tui@latest

# Verify
ralph-tui --version
```

### Setup

After installing, initialize in your project:

```bash
cd your-project
ralph-tui setup
```

The setup wizard will:
- **Detect agents** — Find installed AI coding agents
- **Create configuration** — Generate `.ralph-tui/config.toml`
- **Install skills** — Add bundled skills for PRD creation (optional, this plugin provides better alternatives)
- **Detect trackers** — Find existing prd.json or Beads setups

**Re-run setup anytime:** `ralph-tui setup --force`

### Verify Installation

```bash
ralph-tui --version       # Check version
ralph-tui plugins agents  # List detected agents
ralph-tui plugins trackers # List detected trackers
ralph-tui config show      # View configuration
```

### Run

```bash
ralph-tui run --prd .claude/prd/feature.json
ralph-tui run --prd ./prd.json --iterations 5    # Limit iterations
ralph-tui run --prd ./prd.json --headless        # No TUI, just output
```

### Keyboard Shortcuts

**Execution Control**

| Key | Action |
|-----|--------|
| `s` | Start execution |
| `p` | Pause/Resume |
| `+ / =` | Add 10 iterations |
| `- / _` | Remove 10 iterations |
| `q` | Quit |
| `?` | Show all shortcuts |

**Navigation**

| Key | Action |
|-----|--------|
| `j / ↓` | Navigate down |
| `k / ↑` | Navigate up |
| `Tab` | Switch focus between panels |
| `Enter` | Drill into selected item |
| `Esc` | Go back / close dialog |

**View Controls**

| Key | Action |
|-----|--------|
| `o` | Cycle right panel views (details → output → prompt) |
| `O` | Jump directly to prompt preview |
| `d` | Toggle progress dashboard |
| `h` | Toggle show/hide closed tasks |
| `r` | Refresh task list |
| `T` | Toggle subagent tree panel |
| `t` | Cycle subagent detail level |

### Troubleshooting

**"Agent not found"**
```bash
which claude              # Verify agent CLI is installed
ralph-tui plugins agents  # See detected agents
```

**"bun: command not found"**

Add to your shell profile (`.bashrc`, `.zshrc`):
```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

Then restart terminal or `source ~/.bashrc`.

**Resources:**
- [RalphTUI Documentation](https://ralph-tui.com/docs)
- [RalphTUI Quick Start](https://ralph-tui.com/docs/getting-started/quick-start)
- [RalphTUI GitHub](https://github.com/subsy/ralph-tui)

---

## Related

- [README.md](README.md) — Main guide
- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Optional: Persistent memory across sessions
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters
