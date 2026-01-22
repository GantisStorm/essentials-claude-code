---
allowed-tools: Bash(jq:*), Bash(mv:*), Bash(cat:*), Bash(ls:*)
argument-hint: "<prd.json path>"
description: Reset a prd.json file to initial state (all tasks pending)
model: opus
context: fork
---

# Reset PRD

Reset a prd.json file so all tasks are pending again.

## Instructions

Run this single command to reset the prd file (replace `<path>` with the actual path from $ARGUMENTS):

```bash
jq '.userStories = [.userStories[] | del(.completionNotes) | .passes = false] | del(.metadata.updatedAt)' "<path>" > /tmp/reset-prd-$$.json && mv /tmp/reset-prd-$$.json "<path>" && echo "Reset complete. Tasks: $(jq '.userStories | length' "<path>") set to passes: false"
```

If no path was provided, list `.claude/prd/*.json` and ask which one to reset.

After resetting, tell the user they can run: `/tasks-loop <path>`
