---
description: "Cancel active beads loop"
allowed-tools: ["Bash"]
hide-from-slash-command-tool: "true"
---

# Cancel Beads

```!
if [[ -f .claude/beads-loop.local.md ]]; then
  ITERATION=$(grep '^iteration:' .claude/beads-loop.local.md | sed 's/iteration: *//')
  LABEL=$(grep '^label_filter:' .claude/beads-loop.local.md | sed 's/label_filter: *//' | sed 's/^"\(.*\)"$/\1/')
  CURRENT=$(grep '^current_task:' .claude/beads-loop.local.md | sed 's/current_task: *//' | sed 's/^"\(.*\)"$/\1/')
  echo "FOUND_LOOP=true"
  echo "ITERATION=$ITERATION"
  echo "LABEL_FILTER=$LABEL"
  echo "CURRENT_TASK=$CURRENT"
else
  echo "FOUND_LOOP=false"
fi
```

Check the output above:

1. **If FOUND_LOOP=false**:
   - Say "No active beads loop found."

2. **If FOUND_LOOP=true**:
   - Use Bash: `rm .claude/beads-loop.local.md`
   - Report: "Cancelled beads loop at iteration N"
   - If CURRENT_TASK is set: "Current task was: [task id]"
   - Note: "Task progress preserved in beads database. Resume with `/beads-loop`"
   - Show: Run `bd ready` to see remaining tasks
