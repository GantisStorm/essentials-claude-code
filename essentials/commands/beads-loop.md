---
description: "Execute beads iteratively until all tasks complete"
argument-hint: "[--label <label>]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit"]
hide-from-slash-command-tool: "true"
model: opus
---

# Beads Loop Command

Execute beads iteratively until all ready tasks are complete.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `--label <label>` (optional): Filter beads by label (default: `ralph`)
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Step 1: Load Beads

```bash
bd list --status open --json
# Or with filters:
bd list -l <label> --status open --json
```

Parse the output to get all beads.

### Step 2: Create Task Graph

For each bead, create a built-in task:

```json
TaskCreate({
  "subject": "beads-abc123: Implement login form",
  "description": "<full bead description - self-contained>",
  "activeForm": "Implementing login form",
  "metadata": { "beadId": "beads-abc123" }
})
```

Set dependencies based on parent/child relationships:

```json
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

### Step 3: Execute Tasks Sequentially

For each task (in dependency order):

1. **Claim**: `TaskUpdate({ taskId: "N", status: "in_progress" })`
2. **Also update bead**: `bd update <beadId> --status in_progress`
3. **Read**: Task description contains full implementation details
4. **Implement**: Make changes as described
5. **Verify**: Run acceptance criteria
6. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
7. **Close bead**: `bd close <beadId> --reason "Done: <summary>"`
8. **Next**: Find next unblocked task via TaskList

### Step 4: Loop Until Done

Use TaskList and `bd ready` to check progress:
- If ready tasks exist → continue with next unblocked task
- If no ready tasks → proceed to finalize

### Step 5: Finalize Session

After all beads complete:

```bash
bd sync  # Force immediate sync (flushes changes to disk/git)
```

Say **"All beads complete"** when done.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 beads-abc123: Setup database
■ #2 beads-def456: Implement auth
□ #3 beads-ghi789: Add routes > blocked by #2
```

## Context Recovery

If you lose track:

```bash
# Check built-in tasks
TaskList

# Or check beads directly
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
| Lost track of current work | TaskList or `bd list --status in_progress` |
| Task has unmet dependencies | Complete blocking tasks first |

## Stopping

- Say "All beads complete" when done
- Run `/cancel-loop` to stop early

## Example Usage

```bash
/beads-loop                           # Run beads with ralph label (default)
/beads-loop --label my-custom-label   # Filter by custom label
/beads-loop --max-iterations 5        # Limit iterations
```
