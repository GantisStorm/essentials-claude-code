---
allowed-tools: ["Bash", "TaskList"]
argument-hint: ""
description: Cancel active implement or plan loop
model: haiku
context: fork
---

# Cancel Implement

Gracefully stop the active implement loop or plan loop while preserving progress.

Works with both `/implement-loop` and `/plan-loop`.

## Instructions

1. Check if `.claude/implement-loop.local.md` exists
2. If it exists:
   - Read iteration and plan path from the file
   - Remove the file: `rm .claude/implement-loop.local.md`
   - Report: "Cancelled implement loop at iteration N for plan: [plan path]"
   - Note: "Todos remain in their current state for reference"
3. If it doesn't exist:
   - Say "No active implement loop found."

## After Cancellation

Your task progress is preserved:
- Completed tasks remain completed
- In-progress/pending tasks remain in their current state

To check task status:
```bash
TaskList
```

To resume later:
```bash
/implement-loop           # From context
/implement-loop <plan>    # From plan file
/plan-loop <plan>         # Plan file only
```
