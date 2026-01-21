# Beads Workflow (Optional)

> **This workflow is optional and requires the Beads CLI.** Use the [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Beads only when you need persistent memory across sessions, or when AI hallucinates mid-task.

## When to Use This Workflow

- Multi-day features spanning multiple sessions
- AI hallucinates or loses track mid-task
- Context keeps compacting and losing progress
- Need persistent memory that survives session boundaries

**Note:** The built-in `/beads-loop` works without RalphTUI. RalphTUI is only needed if you want the visual dashboard.

---

## Requirements

**Beads CLI is required for this workflow:**

```bash
brew tap steveyegge/beads && brew install bd
# Or: npm install -g @beads/bd
```

---

## Overview

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│ PLANNING                        │     │ EXECUTION (choose one)          │
│                                 │     │                                 │
│ /plan-creator <task>            │     │ /beads-loop                     │
│        ↓                        │────▶│   (built-in, requires bd CLI)   │
│ /beads-creator plan.md          │     │                                 │
│                                 │     │ ralph-tui run --tracker beads   │
│ Output: beads in local DB       │     │   (optional TUI dashboard)      │
└─────────────────────────────────┘     └─────────────────────────────────┘
```

---

## What are Beads?

Atomic, self-contained task units in a local graph database. Unlike plans (session-scoped), beads **persist** across sessions.

| Component | Purpose |
|-----------|---------|
| Requirements | Full requirements copied verbatim |
| Reference Implementation | 20-400+ lines based on complexity |
| Migration Pattern | Exact before/after for file edits |
| Exit Criteria | Specific verification commands |
| Dependencies | `depends_on`/`blocks` relationships |
| Labels | Link to source (`ralph` by default) |

**Key insight:** When context compacts, `bd ready` always shows what's next. Each bead has everything needed—no reading other files.

---

## Setup

### Step 1: Install Beads CLI

```bash
# macOS
brew tap steveyegge/beads && brew install bd

# Or via npm
npm install -g @anthropics/beads
```

### Step 2: Initialize Beads

| Mode | Command | When to Use |
|------|---------|-------------|
| Stealth | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected Branch | `bd init --branch beads-sync` | When main is protected |

**Stealth Mode:** Keeps `.beads/` local only — no git sync. Use for personal or brownfield projects.

### Step 3: Complete Setup with Doctor

After `bd init`, run the doctor to fix common issues:

```bash
bd doctor --fix
```

This fixes:
- Git hooks (for auto-sync)
- Claude integration
- Version tracking
- Sync branch config

### Step 4: (Optional) Install RalphTUI

Only needed if you want the visual TUI dashboard:

```bash
# Requires Bun runtime
bun install -g ralph-tui
ralph-tui setup
```

---

## Usage

### Stage 1: Create Plan
```bash
/plan-creator Add complete auth system
```

### Stage 2: Convert to Beads
```bash
/beads-creator .claude/plans/auth-system-3k7f2-plan.md
# Creates beads with 'ralph' label (RalphTUI compatible)
```

### Stage 3: Execute

**Option A: Built-in Loop (requires Beads CLI)**
```bash
/beads-loop                         # Run all beads with ralph label
/beads-loop --label custom-label    # Filter by custom label
/beads-loop --max-iterations 10     # Limit iterations
/cancel-beads                        # Stop gracefully
```

**Option B: RalphTUI Dashboard (optional)**
```bash
# Install RalphTUI first: bun install -g ralph-tui && ralph-tui setup
ralph-tui run --tracker beads --epic <epic-id>
```

---

## Essential Beads Commands

```bash
bd ready                             # List tasks with no blockers
bd blocked                           # Show tasks waiting on dependencies
bd list -l ralph                     # List tasks with ralph label
bd show <id>                         # Full task details
bd create "Title" -p 0               # Create P0 task
bd update <id> --status in_progress  # Start working
bd close <id> --reason "Done"        # Complete task
bd sync                              # Force immediate sync
```

---

## Execution Comparison

| Feature | `/beads-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Installation | Beads CLI only | Requires bun + ralph-tui |
| Interface | Terminal output | TUI dashboard |
| Dependencies | Beads CLI | Beads CLI + RalphTUI |
| Pause/Resume | `/cancel-beads` + restart | Keyboard shortcuts |
| Multi-agent | Claude Code only | Claude, OpenCode, Factory Droid |

---

## The Self-Contained Rule

Each bead must be implementable with ONLY its description.

| Bad | Good |
|-----|------|
| "See design.md" | FULL code (50-200+ lines) in bead |
| "Run tests" | `npm test -- stripe-price` |
| "Update entity" | File + line numbers + before/after |

**Example bead creation:**
```bash
bd create "Add fields to entity.ts" -t task -p 2 -l "ralph" -d "
## Requirements
<FULL requirements - not a reference>

## Reference Implementation
EDIT: path/to/file.ts
**BEFORE** (line 25): <code>
**AFTER**: <code>

## Exit Criteria
npm test -- stripe-price && npm run typecheck
"
```

---

## Context Recovery

If you lose track:

```bash
bd ready                        # See what's next
bd blocked                      # See what's waiting on dependencies
bd list --status in_progress    # Find current work
bd show <id>                    # Full task details
```

---

## Maintenance

Periodically check health:

```bash
bd doctor      # Check for orphaned issues, version mismatches
bd stale       # Find issues not updated recently
```

---

## Land the Plane Protocol

Work is NOT complete until `git push` succeeds:

```bash
bd close <id> --reason "Completed"
git pull --rebase && bd sync && git add -A && git commit -m "chore: session end" && git push
bd ready && git status    # Must be clean
```

---

## Configuration

```bash
bd setup claude    # Install hooks for Claude Code
bd setup cursor    # Cursor IDE rules
```

**Protected branches:** `bd init --branch beads-sync` + `bd daemon --start --auto-commit`

**Labels:** `ralph` (default, RalphTUI compatible), `discovered`, `tech-debt`, `blocked-external`

---

## RalphTUI (Optional)

[RalphTUI](https://github.com/subsy/ralph-tui) provides a visual TUI dashboard.

**Install:**
```bash
bun install -g ralph-tui
ralph-tui setup
```

**Run:**
```bash
ralph-tui run --tracker beads --epic <epic-id>
```

### Important: Task Hierarchy

Tasks must be **children** of the epic (using `--parent`) to appear when running with `--epic`:

```bash
# Create epic first
bd create --title "Feature Name" --type epic
# Output: beads-abc123

# Create tasks as children of the epic
bd create --title "Task 1" --type task --parent beads-abc123 -l ralph
bd create --title "Task 2" --type task --parent beads-abc123 -l ralph
```

**Note:** The `/beads-creator` command handles this automatically—it creates an epic and adds all tasks as children with the `ralph` label.

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
- [RalphTUI Beads Tracker](https://ralph-tui.com/docs/plugins/trackers/beads)
- [RalphTUI GitHub](https://github.com/subsy/ralph-tui)

---

## Beads Resources

- [Beads GitHub](https://github.com/steveyegge/beads)
- [Installing bd](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Protected Branches](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)

---

## Related

- [README.md](README.md) — Main guide
- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Optional: prd.json format, RalphTUI integration
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters
