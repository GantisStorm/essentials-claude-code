---
allowed-tools: Bash
argument-hint: ""
description: Cancel active tasks loop
model: opus
---

# Cancel Tasks

Gracefully stop the active tasks loop while preserving progress.

## Instructions

1. Check if `.claude/tasks-loop-active` exists
2. If it exists:
   - Read prd path and iteration from the file
   - Remove the file: `rm .claude/tasks-loop-active`
   - Report: "Cancelled tasks loop at iteration N"
   - Report: "File: [prd-path]"
3. If it doesn't exist:
   - Say "No active tasks loop found."

## After Cancellation

Your task progress is preserved in prd.json:
- Completed tasks remain `passes: true`
- Pending tasks remain `passes: false`

To check current status:
```bash
# See all tasks
cat <prd-path>

# Count completed vs pending
jq '{completed: [.userStories[] | select(.passes == true)] | length, pending: [.userStories[] | select(.passes == false)] | length}' <prd-path>
```

To resume later:
```bash
/tasks-loop <prd-path>
```

The loop will pick up where you left off - progress is saved in the JSON file.
