---
allowed-tools: Bash(bd:*), Bash(jq:*), Bash(xargs:*)
argument-hint: "<epic-id> or --label <label>"
description: Reset a beads epic to initial state (reopen all child tasks)
model: opus
context: fork
---

# Reset Beads

Reopen all tasks in a beads epic so they can be re-run from the beginning.

## Instructions

### If epic ID provided:

Get all child tasks (including closed) and reopen them:

```bash
bd list --parent <epic-id> --all --json | jq -r '.[].id' | xargs -I {} bd reopen {} --reason "Reset for re-run"
```

### If --label provided:

Get all tasks with that label (including closed) and reopen them:

```bash
bd list -l <label> --all --json | jq -r '.[].id' | xargs -I {} bd reopen {} --reason "Reset for re-run"
```

### If no argument:

List recent epics for the user to choose:

```bash
bd list --type epic -n 10
```

Then ask which epic to reset.

After resetting, tell the user they can run: `/beads-loop` or `/beads-loop --label <label>`
