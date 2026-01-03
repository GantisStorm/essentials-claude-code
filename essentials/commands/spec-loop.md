---
description: "Implement an OpenSpec change iteratively until all tasks complete"
argument-hint: "<change-id> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-spec-loop.sh)", "Read", "TodoWrite", "Bash"]
hide-from-slash-command-tool: "true"
---

# Spec Loop Command

Implement an approved OpenSpec change iteratively, keeping tasks.md in sync until all tasks are complete.

## Workflow Integration

This command is an alternative to the 5-stage Beads workflow. Use it when you want the iterative loop benefits without Beads:

| Workflow | When to Use |
|----------|-------------|
| `/implement-loop` | Plans from `/plan-creator`, `/bug-plan-creator` |
| `/spec-loop` | OpenSpec changes (proposal.md + tasks.md) |
| `/beads-loop` | Large specs converted to Beads issues |

## Setup

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-spec-loop.sh" $ARGUMENTS

# Extract and display loop info
if [ -f .claude/spec-loop.local.md ]; then
  CHANGE_ID=$(grep '^change_id:' .claude/spec-loop.local.md | sed 's/change_id: *//' | sed 's/^"\(.*\)"$/\1/')
  CHANGE_PATH=$(grep '^change_path:' .claude/spec-loop.local.md | sed 's/change_path: *//' | sed 's/^"\(.*\)"$/\1/')
  echo ""
  echo "==============================================================="
  echo "SPEC LOOP - OpenSpec Implementation Mode"
  echo "==============================================================="
  echo ""
  echo "Change: $CHANGE_ID"
  echo "Path: $CHANGE_PATH"
  echo ""
  echo "WORKFLOW:"
  echo "  1. Read proposal.md, design.md (if exists), tasks.md"
  echo "  2. Work through tasks sequentially"
  echo "  3. Mark each task [x] in tasks.md when complete"
  echo "  4. Loop continues until all tasks marked [x]"
  echo ""
  echo "STOPPING CONDITIONS:"
  echo "  - All tasks in tasks.md marked [x]"
  echo "  - Max iterations reached (if set)"
  echo "  - User cancels with /cancel-spec-loop"
  echo ""
  echo "CONTEXT RECOVERY:"
  echo "  - Run: openspec show $CHANGE_ID"
  echo "  - Read: $CHANGE_PATH/tasks.md"
  echo "==============================================================="
fi
```

## Initial Instructions

You are now in **spec loop mode**. Your task is to implement the OpenSpec change completely.

### Guardrails

- Favor straightforward, minimal implementations first and add complexity only when it is requested or clearly required.
- Keep changes tightly scoped to the requested outcome.
- Refer to `openspec/AGENTS.md` if you need additional OpenSpec conventions or clarifications.

### Step 1: Read the Spec

Read these files from the change directory:
1. `proposal.md` - The approved change proposal
2. `design.md` - Technical design (if present)
3. `tasks.md` - The task checklist to complete

### Step 2: Create Todos

Use **TodoWrite** to create a todo for each task in `tasks.md`:
- Mark them as pending initially
- Work through them sequentially

Example todo structure:
```
1. [pending] Implement user authentication endpoint
2. [pending] Add validation middleware
3. [pending] Create unit tests
4. [pending] Update API documentation
```

### Step 3: Implement Each Task

For each task:
1. Mark it as **in_progress** using TodoWrite
2. Reference the proposal/design for context
3. Implement the change with minimal, focused edits
4. Verify the implementation works
5. Mark as **completed** in TodoWrite
6. Update `tasks.md` to mark the task `[x]`

### Step 4: Keep tasks.md in Sync

**IMPORTANT**: After completing each task, update `tasks.md`:

```markdown
# Before
- [ ] Implement user authentication endpoint

# After
- [x] Implement user authentication endpoint
```

### Step 5: Confirm Completion

Before the loop ends:
1. Verify every task in `tasks.md` is marked `[x]`
2. Confirm all acceptance criteria from `proposal.md` are satisfied
3. Say "All spec tasks complete" when done

### Step 6: Loop Continues

When you try to exit:
- The stop hook checks `tasks.md` for uncompleted tasks
- If uncompleted tasks remain → loop continues
- If all tasks marked `[x]` → loop ends, implementation complete

### Step 7: Archive (Optional)

When all tasks are complete, you may archive the change:
```bash
openspec archive <change-id>
```

### Context Recovery

If context is compacted and you lose track:

**Quick Recovery:**
1. Run `openspec show <change-id>` for summary
2. Read `tasks.md` to see what's done and what's next
3. Check your todo list status
4. Continue with the next uncompleted task

**Deep Recovery (using back-references):**

The OpenSpec change has a chain of back-references:
```
proposal.md → plan_reference (source plan)
design.md → Reference Implementation (FULL code)
tasks.md → Exit Criteria (EXACT commands)
specs/*.md → Requirements with scenarios
```

1. **Find plan reference**: `grep "Source Plan" openspec/changes/<id>/proposal.md`
2. **Read source plan**: Contains full implementation code, architecture diagrams, exit criteria
3. **Read design.md**: Has Reference Implementation (FULL code) and Migration Patterns
4. **Read tasks.md**: Has Exit Criteria (EXACT verification commands)

### Reference Commands

Use these when you need additional context:
```bash
# Quick context
openspec show <id> --json --deltas-only

# Find plan reference
grep "Source Plan" openspec/changes/<id>/proposal.md

# Read full implementation code
cat openspec/changes/<id>/design.md | grep -A 100 "Reference Implementation"

# Read exit criteria
cat openspec/changes/<id>/tasks.md | grep -A 20 "Exit Criteria"
```

**IMPORTANT**:
- Keep edits minimal and focused on the requested change
- Update `tasks.md` after each task completion
- Use the plan_reference for full implementation details if needed
- The loop will not end until ALL tasks are marked `[x]`
