---
allowed-tools: ["TaskList", "TaskStop", "TaskOutput"]
argument-hint: ""
description: Cancel any active swarm
model: haiku
---

# Cancel Swarm

Stop any active swarm workers.

Works with all swarm commands: `/implement-swarm`, `/plan-swarm`, `/tasks-swarm`, `/beads-swarm`.

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

If no in-progress tasks found:
- Say "No active swarm found."

## After Cancellation

Task progress is preserved:
- Completed tasks remain completed
- In-progress tasks may complete if worker finishes
- Pending tasks remain pending

To check task status:
```bash
TaskList
```

## Note

Unlike loop cancellation, swarm workers are independent agents. If a worker completed its current task before cancellation, that work is saved.
