---
description: "Cancel active implement loop"
allowed-tools: ["Bash"]
hide-from-slash-command-tool: "true"
---

# Cancel Implement

```!
if [[ -f .claude/implement-loop.local.md ]]; then
  ITERATION=$(grep '^iteration:' .claude/implement-loop.local.md | sed 's/iteration: *//')
  PLAN_PATH=$(grep '^plan_path:' .claude/implement-loop.local.md | sed 's/plan_path: *//' | sed 's/^"\(.*\)"$/\1/')
  echo "FOUND_LOOP=true"
  echo "ITERATION=$ITERATION"
  echo "PLAN_PATH=$PLAN_PATH"
else
  echo "FOUND_LOOP=false"
fi
```

Check the output above:

1. **If FOUND_LOOP=false**:
   - Say "No active implement loop found."

2. **If FOUND_LOOP=true**:
   - Use Bash: `rm .claude/implement-loop.local.md`
   - Report: "Cancelled implement loop at iteration N for plan: [plan path]"
   - Note: Todos remain in their current state for reference
