---
allowed-tools: ["TaskList", "TaskStop", "TaskOutput"]
argument-hint: ""
description: Cancel active swarm workers
model: haiku
---

# Cancel Swarm

Stop all running swarm workers and report final status.

## Instructions

1. Call TaskList to see all tasks and their status
2. For any tasks with status `in_progress`:
   - Note the owner (worker name)
   - The worker may still be running
3. Use TaskStop to halt any background workers still active
4. Report:
   - Completed tasks: N
   - In-progress (interrupted): N
   - Pending (not started): N

## After Cancellation

Task state is preserved in `~/.claude/tasks/<session-id>/`:
- Completed tasks remain `completed`
- In-progress tasks stay `in_progress` (manual cleanup needed)
- Pending tasks remain `pending`

To check status:
```
TaskList
```

To resume: Re-run `/swarm` with same plan - it will create fresh tasks.

## Note

Unlike loop cancellation, swarm workers are independent agents. If a worker completed its current task before cancellation, that work is saved.
