# Beads Workflow

> **Optional workflow requiring Beads CLI.** Use [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Beads when you need persistent memory across sessions or multi-day features.

## When to Use

- Multi-day features spanning multiple sessions
- AI loses track mid-task or hallucinates
- Context keeps compacting and losing progress
- Need memory that survives session boundaries

---

## Requirements

```bash
brew tap steveyegge/beads && brew install bd
```

---

## Overview

```
/plan-creator <task>  →  /beads-creator plan.md  →  /beads-loop
                                                     (or ralph-tui run)
```

---

## Setup

### 1. Install Beads CLI

```bash
# macOS
brew tap steveyegge/beads && brew install bd

# Or npm
npm install -g @anthropics/beads
```

### 2. Initialize

| Mode | Command | Use Case |
|------|---------|----------|
| Stealth | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected | `bd init --branch beads-sync` | When main is protected |

### 3. Fix Common Issues

```bash
bd doctor --fix
```

---

## Usage

### 1. Create Plan
```bash
/plan-creator Add complete auth system
```

### 2. Convert to Beads
```bash
/beads-creator .claude/plans/auth-system-3k7f2-plan.md
# Creates epic + child tasks with 'ralph' label
```

### 3. Execute

**Built-in (requires Beads CLI):**
```bash
/beads-loop                         # All beads with ralph label
/beads-loop --label custom-label    # Filter by label
/cancel-beads                       # Stop gracefully
```

**RalphTUI (optional dashboard):**
```bash
ralph-tui run --tracker beads --epic <epic-id>
```

---

## Essential Commands

```bash
bd ready                             # Tasks with no blockers
bd blocked                           # Tasks waiting on dependencies
bd list -l ralph                     # Tasks with ralph label
bd show <id>                         # Full task details
bd close <id> --reason "Done"        # Complete task
bd sync                              # Force sync
```

---

## Context Recovery

```bash
bd ready                        # What's next
bd blocked                      # What's waiting
bd list --status in_progress    # Current work
bd show <id>                    # Full details
```

---

## Land the Plane

Work is NOT complete until `git push` succeeds:

```bash
bd close <id> --reason "Completed"
git pull --rebase && bd sync && git add -A && git commit -m "chore: session end" && git push
```

---

## RalphTUI (Optional)

For installation, see [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md#ralphtui-optional).

### Setup for Beads

```bash
ralph-tui setup    # Select beads-bv tracker when prompted
```

Or edit `.ralph-tui/config.toml`:
```toml
tracker = "beads-bv"
agent = "claude"
```

**Switching workflows?** If you use both Tasks and Beads in the same repo, see [Managing .ralph-tui/ Folder](WORKFLOW-TASKS.md#managing-ralph-tui-folder) for how to switch trackers.

### Beads-Specific Usage

```bash
ralph-tui run --tracker beads-bv --epic <epic-id>
```

**Task Hierarchy:** Tasks must be children of the epic to appear:

```bash
bd create --title "Feature" --type epic     # → beads-abc123
bd create --title "Task 1" --type task --parent beads-abc123 -l ralph
```

The `/beads-creator` command handles this automatically.

---

## Comparison

| Feature | `/beads-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Install | Beads CLI | Beads CLI + bun + ralph-tui |
| Interface | Terminal | TUI dashboard |
| Multi-agent | Claude only | Claude, OpenCode, Droid |

---

## Resources

- [Beads GitHub](https://github.com/steveyegge/beads)
- [Installing bd](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Protected Branches](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)

---

## Related

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default, zero dependencies
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — prd.json format
- [README.md](README.md) — Main guide
