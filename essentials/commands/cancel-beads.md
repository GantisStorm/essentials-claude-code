---
allowed-tools: Bash
argument-hint: ""
description: Cancel active beads loop
model: haiku
---

# Cancel Beads

Gracefully stop the active beads loop while preserving progress.

## Instructions

1. Check if `.claude/beads-loop.local.md` exists
2. If it exists:
   - Read iteration and label from the file
   - Remove the file: `rm .claude/beads-loop.local.md`
   - Report: "Cancelled beads loop at iteration N"
   - If label exists: "Label: [label]"
3. If it doesn't exist:
   - Say "No active beads loop found."

## After Cancellation

Your task progress is preserved in the beads database:
- Completed tasks remain closed
- In-progress tasks remain in_progress
- Pending tasks remain ready

To check current status:
```bash
bd ready                        # See what's next
bd list --status in_progress    # Find current work
```

To resume later:
```bash
/beads-loop [--label <label>]
```

The loop will pick up where you left off - beads persist across sessions.
