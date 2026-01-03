---
description: "Execute beads iteratively until all tasks complete"
argument-hint: "[--label <label>] [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh)", "Read", "TodoWrite", "Bash", "Edit"]
hide-from-slash-command-tool: "true"
---

# Beads Loop Command

Execute beads iteratively until all ready tasks are complete. This is Stage 5 of the 5-stage workflow.

## Workflow Integration

This command is the final stage after:
1. `/plan-creator` - Create architectural plan
2. `/proposal-creator` - Create OpenSpec proposal
3. Validation - Review and approve spec
4. `/beads-creator` - Convert spec to beads
5. **`/beads-loop`** - Execute beads iteratively

## Setup

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh" $ARGUMENTS

if [ -f .claude/beads-loop.local.md ]; then
  LABEL=$(grep '^label_filter:' .claude/beads-loop.local.md | sed 's/label_filter: *//' | sed 's/^"\(.*\)"$/\1/')
  echo ""
  echo "==============================================================="
  echo "BEADS LOOP - Iterative Task Execution"
  echo "==============================================================="
  echo ""
  if [ -n "$LABEL" ]; then
    echo "Label: $LABEL"
  else
    echo "Label: (all tasks)"
  fi
  echo ""
  echo "WORKFLOW:"
  echo "  1. bd ready → find tasks with no blockers"
  echo "  2. bd show <id> → read task details"
  echo "  3. bd update <id> --status in_progress"
  echo "  4. Implement the task"
  echo "  5. bd close <id> --reason 'Done: <summary>'"
  echo "  6. If OpenSpec: edit tasks.md to mark [x]"
  echo "  7. Repeat until no ready tasks"
  echo ""
  echo "STOP: /cancel-beads or say 'All beads complete'"
  echo "==============================================================="
fi
```

## Instructions

You are now in **beads loop mode**. Execute all ready beads until complete.

### Step 1: Find Ready Work

```bash
bd ready
```

Shows tasks with no blockers, sorted by priority.

### Step 2: Pick a Task

Select the highest priority ready task. Note its ID.

### Step 3: Read Task Details

```bash
bd show <id>
```

The task description should be self-contained with requirements, acceptance criteria, and files to modify.

### Step 4: Start Working

```bash
bd update <id> --status in_progress
```

### Step 5: Implement the Task

Follow the task description:
1. Read the files mentioned
2. Make the required changes
3. Run any tests/verification in acceptance criteria

### Step 6: Complete the Task

```bash
bd close <id> --reason "Done: <brief summary>"
```

### Step 7: Update OpenSpec (if applicable)

**IMPORTANT**: If working on an OpenSpec change (label starts with `openspec:`):

Edit `openspec/changes/<name>/tasks.md` to mark that task complete:

```markdown
# Before
- [ ] Task description here

# After
- [x] Task description here
```

### Step 8: Repeat

Continue until `bd ready` returns no tasks.

### Completion

When no ready tasks remain, say: **"All beads complete"**

Then archive the OpenSpec change if applicable:
```bash
openspec archive <change-name>
```

### Context Recovery

If you lose track:

```bash
bd ready                        # See what's next
bd list --status in_progress    # Find current work
bd show <id>                    # Full task details
```

### Stopping

- Say "All beads complete" when done
- Run `/cancel-beads` to stop early
- Max iterations reached (if set)
