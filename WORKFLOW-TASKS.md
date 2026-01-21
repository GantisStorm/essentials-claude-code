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

### Install

```bash
# Requires Bun runtime (https://bun.sh)
curl -fsSL https://bun.sh/install | bash

# Install RalphTUI
bun install -g ralph-tui

# Setup (creates config, detects agents)
ralph-tui setup
```

### Run

```bash
ralph-tui run --prd .claude/prd/feature.json
ralph-tui run --prd ./prd.json --iterations 5    # Limit iterations
ralph-tui run --prd ./prd.json --headless        # No TUI, just output
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `s` | Start execution |
| `p` | Pause/Resume |
| `q` | Quit |
| `j/k` | Navigate tasks |
| `o` | Cycle views (details → output → prompt) |
| `T` | Toggle subagent tree |
| `?` | Show all shortcuts |

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
