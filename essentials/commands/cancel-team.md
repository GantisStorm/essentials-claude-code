---
allowed-tools: ["Bash", "TaskList"]
argument-hint: ""
description: Cancel any active agent team
model: opus
---

# Cancel Team

Stop any active agent team and terminate tmux panes.

Works with all team commands: `/implement-team`, `/plan-team`.

Note: Use `/cancel-team` for teams, `/cancel-swarm` for swarms, and `/cancel-loop` for loops.

## Instructions

1. Call TaskList to see all tasks and their status
2. For any tasks with status `in_progress`:
   - Note the task subjects (agent assignments)
   - Agents may still be running in tmux panes
3. Terminate agent tmux panes by running: `tmux kill-session -t claude-team 2>/dev/null || true`
4. Report:
   - Completed tasks: N
   - In-progress (interrupted): N
   - Pending (not started): N

If no in-progress tasks found:
- Say "No active team found."

## After Cancellation

Task progress is preserved:
- Completed tasks remain completed
- In-progress agent work may be partially saved (agents are full Claude Code instances)
- Pending tasks remain pending

To check task status:
```bash
TaskList
```

## Note

Unlike swarm cancellation (which stops lightweight subagents), team cancellation terminates full Claude Code instances running in tmux panes. Work completed by agents before cancellation is saved to disk.
