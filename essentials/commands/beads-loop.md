---
description: "Execute beads iteratively until all tasks complete"
argument-hint: "[--label <label>] [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh)", "Read", "TodoWrite", "Bash"]
hide-from-slash-command-tool: "true"
---

# Beads Loop Command

Execute beads iteratively until all ready tasks are complete. This is Stage 5 of the 5-stage workflow.

## Workflow Integration

This command is the final stage after:
1. `/plan-creator` - Create architectural plan
2. OpenSpec/SpecKit - Create detailed spec
3. Validation - Review and approve spec
4. `/beads-creator` - Convert spec to self-contained beads
5. **`/beads-loop`** - Execute beads iteratively ← YOU ARE HERE

## Setup

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-beads-loop.sh" $ARGUMENTS

# Extract and display loop info
if [ -f .claude/beads-loop.local.md ]; then
  LABEL=$(grep '^label_filter:' .claude/beads-loop.local.md | sed 's/label_filter: *//' | sed 's/^"\(.*\)"$/\1/')
  echo ""
  echo "==============================================================="
  echo "BEADS LOOP - Iterative Task Execution Mode"
  echo "==============================================================="
  echo ""
  if [ -n "$LABEL" ]; then
    echo "Label Filter: $LABEL"
  else
    echo "Label Filter: (all tasks)"
  fi
  echo ""
  echo "WORKFLOW:"
  echo "  1. Run bd ready to find tasks with no blockers"
  echo "  2. Pick highest priority task"
  echo "  3. Read task with bd show <id>"
  echo "  4. Implement using the self-contained description"
  echo "  5. Close with bd close <id> --reason 'Completed: <summary>'"
  echo "  6. Repeat until no ready tasks remain"
  echo ""
  echo "STOPPING CONDITIONS:"
  echo "  - No ready tasks (bd ready returns empty)"
  echo "  - Max iterations reached (if set)"
  echo "  - User cancels with /cancel-beads"
  echo ""
  echo "CONTEXT RECOVERY:"
  echo "  - Run: bd ready (see what's next)"
  echo "  - Run: bd show <id> (full task context)"
  echo "  - Run: bd list --status in_progress (resume current)"
  echo "==============================================================="
fi
```

## Initial Instructions

You are now in **beads loop mode**. Your task is to execute all ready beads until complete.

### Step 1: Find Ready Work

```bash
bd ready
```

This shows tasks with no blockers, sorted by priority. If a label filter is active, only matching tasks appear.

### Step 2: Pick a Task

Select the highest priority ready task. Note its ID (e.g., `project-abc`).

### Step 3: Read Task Details

```bash
bd show <id>
```

The task description is **self-contained** with:
- Spec reference
- Requirements (copied, not just referenced)
- Acceptance criteria
- Files to modify

### Step 4: Start Working

```bash
bd update <id> --status in_progress
```

### Step 5: Implement the Task

Follow the task description exactly:
1. Read the files mentioned
2. Make the required changes
3. Run any tests/verification mentioned in acceptance criteria
4. If you discover new issues: `bd create "Found: <issue>" --discovered-from <id>`

### Step 6: Complete the Task

```bash
bd close <id> --reason "Completed: <brief summary>"
```

### Step 7: OpenSpec Auto-Sync

If working on an OpenSpec change (label starts with `openspec:`):
- **Automatic**: The stop hook syncs closed beads back to `tasks.md`
- Each `bd close` automatically marks the matching task `[x]`
- Check sync status in `.claude/beads-loop.local.md`

No manual sync needed - it happens automatically on each iteration.

### Step 8: Loop Continues

When you try to exit:
- The stop hook runs `bd ready` to check for more tasks
- If tasks remain → loop continues with next task
- If no tasks → loop ends, all beads complete

### Step 9: Auto-Archive OpenSpec (when complete)

When all beads are complete and you're working on an OpenSpec change:
- **Automatic**: The stop hook runs `openspec archive` automatically
- All tasks in `tasks.md` are synced and marked `[x]`
- The change is moved to `openspec/archive/`

No manual archive needed - it happens automatically when the loop ends.

### Context Recovery

If context is compacted and you lose track:

**Quick Recovery (bead is self-contained):**
1. Run `bd ready` to see what's next
2. Run `bd list --status in_progress` to find current work
3. Run `bd show <id>` for full task details
4. Continue implementation

**Deep Recovery (using context chain):**

Each bead has dual back-references enabling full recovery:
```
Bead
 ├── Spec Reference → specs/*.md (requirements, scenarios)
 └── Plan Reference → .claude/plans/*-plan.md (source of truth)
```

1. **From bead**: `bd show <id>` - has spec_reference and plan_reference
2. **From spec**: Read specs/*.md for requirements and scenarios
3. **From plan**: Read source plan for:
   - Full implementation code
   - Architecture diagrams
   - Exit criteria (exact commands)
   - Migration patterns (before/after)

**Recovery commands:**
```bash
# Find spec and plan references in bead
bd show <id> | grep -E "(Spec Reference|Plan Reference)"

# Read referenced spec
cat <spec-reference-path>

# Read referenced plan
cat <plan-reference-path>

# Find Reference Implementation in design.md
cat <spec-path>/design.md | grep -A 100 "Reference Implementation"
```

**IMPORTANT**:
- Each bead is self-contained - `bd show <id>` has everything you need
- Use spec_reference for requirements and scenarios
- Use plan_reference for full implementation code if needed
- Don't skip tasks - complete them in priority order
- Close tasks as soon as done - this unblocks dependent tasks

### Completion Signals

Say one of these when all tasks are done:
- "All beads complete"
- "No ready tasks remaining"
- "Beads loop complete"
