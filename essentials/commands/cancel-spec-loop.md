---
description: "Cancel active spec loop"
allowed-tools: ["Bash"]
---

# Cancel Spec Loop

Gracefully stop the active spec loop while preserving progress.

## Action

```!
if [ -f .claude/spec-loop.local.md ]; then
  CHANGE_ID=$(grep '^change_id:' .claude/spec-loop.local.md | sed 's/change_id: *//' | sed 's/^"\(.*\)"$/\1/')
  rm -f .claude/spec-loop.local.md
  echo "Spec loop cancelled."
  echo ""
  echo "Progress preserved in: openspec/changes/$CHANGE_ID/tasks.md"
  echo "Resume later with: /spec-loop $CHANGE_ID"
else
  echo "No active spec loop found."
  echo ""
  echo "State file .claude/spec-loop.local.md does not exist."
fi
```

## After Cancellation

Your task progress is preserved in `tasks.md`:
- Completed tasks remain marked `[x]`
- Uncompleted tasks remain `[ ]`

To resume later:
```bash
/spec-loop <change-id>
```

The loop will pick up where you left off.
