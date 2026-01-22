# Tasks Workflow

> **Optional workflow.** Use [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Tasks when you want prd.json format or RalphTUI dashboard.

## When to Use

- You want JSON-based task tracking
- You want RalphTUI's visual dashboard
- You prefer prd.json over plain markdown plans

**Note:** Built-in `/tasks-loop` works without RalphTUI. RalphTUI is optional for the visual dashboard.

---

## Overview

```
/plan-creator <task>  →  /tasks-creator plan.md  →  /tasks-loop prd.json
                                                     (or ralph-tui run)
```

---

## Usage

### 1. Create Plan
```bash
/plan-creator Add user authentication with JWT
```

### 2. Convert to prd.json
```bash
/tasks-creator .claude/plans/user-auth-3k7f2-plan.md
# Output: .claude/prd/user-auth-3k7f2.json
```

### 3. Execute

**Built-in (no dependencies):**
```bash
/tasks-loop .claude/prd/user-auth-3k7f2.json
/cancel-tasks                                    # Stop gracefully
```

**RalphTUI (optional dashboard):**
```bash
ralph-tui run --prd .claude/prd/user-auth-3k7f2.json
```

---

## prd.json Schema

```json
{
  "name": "Feature Name",
  "userStories": [
    {
      "id": "US-001",
      "title": "Task title",
      "description": "FULL implementation (50-200+ lines)",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

### Required Fields

| Field | Type | Notes |
|-------|------|-------|
| `userStories` | array | NOT `tasks` or `items` |
| `passes` | boolean | NOT `status: "pending"` |
| `acceptanceCriteria` | string[] | NOT `criteria` |
| `dependsOn` | string[] | NOT `dependencies` |

Each task's `description` must contain EVERYTHING needed to implement—the executor never reads the original plan.

---

## Context Recovery

```bash
ls .claude/prd/                                           # List prd files
jq '.' .claude/prd/<name>.json                            # Read prd
jq '[.userStories[] | select(.passes == false)]' <file>   # Pending tasks
```

---

## RalphTUI (Optional)

Visual TUI dashboard for task execution. **For execution only**—use this plugin for planning.

### Install

```bash
# 1. Install Bun (required runtime)
curl -fsSL https://bun.sh/install | bash

# 2. Install RalphTUI
bun install -g ralph-tui

# 3. Setup (per project)
cd your-project && ralph-tui setup
```

### Run

```bash
ralph-tui run --prd .claude/prd/feature.json
ralph-tui run --prd ./prd.json --iterations 5
ralph-tui run --prd ./prd.json --headless
```

### Verify

```bash
ralph-tui --version
ralph-tui plugins agents
ralph-tui config show
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `s` | Start |
| `p` | Pause/Resume |
| `q` | Quit |
| `j/k` | Navigate |
| `o` | Cycle views |
| `T` | Subagent tree |
| `?` | All shortcuts |

### Troubleshooting

**"bun: command not found"** — Add to `~/.zshrc`:
```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

**"Agent not found"** — Run `which claude` and `ralph-tui plugins agents`

**Resources:** [RalphTUI Docs](https://ralph-tui.com/docs) · [GitHub](https://github.com/subsy/ralph-tui)

---

## Comparison

| Feature | `/tasks-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Install | None | bun + ralph-tui |
| Interface | Terminal | TUI dashboard |
| Multi-agent | Claude only | Claude, OpenCode, Droid |

---

## Related

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default, zero dependencies
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent memory
- [README.md](README.md) — Main guide
