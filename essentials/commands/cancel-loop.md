---
allowed-tools: ["Bash", "TaskList"]
argument-hint: ""
description: Cancel any active loop
model: opus
context: fork
---

# Cancel Loop

Gracefully stop any active loop while preserving progress.

Works with all loop commands: `/implement-loop`, `/plan-loop`, `/tasks-loop`, `/beads-loop`.

## Instructions

Check for any active loop state file and cancel it:

1. Check for `.claude/implement-loop.local.md`
2. Check for `.claude/plan-loop.local.md`
3. Check for `.claude/tasks-loop.local.md`
4. Check for `.claude/beads-loop.local.md`

For each found:
- Read iteration info from the file
- Remove the file
- Report: "Cancelled [type] loop at iteration N"

If none found:
- Say "No active loop found."

## After Cancellation

Task progress is preserved:
- Completed tasks remain completed
- In-progress/pending tasks remain in their current state

To check task status:
```bash
TaskList
```
