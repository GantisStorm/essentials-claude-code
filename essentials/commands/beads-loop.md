---
description: "Execute beads iteratively until all tasks complete"
argument-hint: "[--label <label>]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh)", "Read", "TodoWrite", "Bash", "Edit"]
hide-from-slash-command-tool: "true"
model: haiku
---

# Beads Loop Command

Execute beads iteratively until all ready tasks are complete.

## Arguments

- `--label <label>` (optional): Filter beads by label (e.g., `--label plan:my-feature`)
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh" $ARGUMENTS
```

### Step 1: Find Ready Work

```bash
bd ready
```

Shows tasks with no blockers, sorted by priority.

### Step 2: Pick a Task

Select the highest priority ready task. Note its ID.

### Step 3: Read Task Details

```bash
bd show <id>
```

The task description is self-contained with requirements, acceptance criteria, and files to modify.

### Step 4: Start Working

```bash
bd update <id> --status in_progress
```

### Step 5: Implement the Task

Follow the task description:
1. Read the files mentioned
2. Make the required changes
3. Run any tests/verification in acceptance criteria

### Step 6: Complete the Task

```bash
bd close <id> --reason "Done: <brief summary>"
```

### Step 7: Loop Until Done

The stop hook checks `bd ready` for remaining tasks:
- If ready tasks exist → loop continues
- If no ready tasks → loop ends

### Step 8: Finalize Session

After all beads complete:

```bash
bd sync  # Force immediate sync (flushes changes to disk/git)
```

Say **"All beads complete"** when done.

## Context Recovery

If you lose track:

```bash
bd ready                        # See what's next
bd blocked                      # See what's waiting on dependencies
bd list --status in_progress    # Find current work
bd show <id>                    # Full task details
```

## Maintenance Commands

Periodically check health:

```bash
bd doctor      # Check for orphaned issues, version mismatches
bd stale       # Find issues not updated recently
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No ready tasks found | Check if all complete or blocked; run `bd list` |
| Lost track of current work | Run `bd list --status in_progress` |
| Task has unmet dependencies | Complete blocking tasks first |

## Stopping

- Say "All beads complete" when done
- Run `/cancel-beads` to stop early

## Example Usage

```bash
/beads-loop
/beads-loop --label plan:add-auth
/beads-loop --max-iterations 5
```
