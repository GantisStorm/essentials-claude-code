---
allowed-tools: Bash
argument-hint: ""
description: Cancel active implement loop
model: haiku
---

# Cancel Implement

Gracefully stop the active implement loop while preserving progress.

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

Your todo progress is preserved:
- Completed todos remain marked as completed
- In-progress/pending todos remain in their current state

To resume later:
```bash
/implement-loop <plan-path>
```

The loop will re-read the plan and you can continue from where you left off.
