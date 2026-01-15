---
description: "Implement an OpenSpec change iteratively until all tasks complete"
argument-hint: "<change-id> [--step|--auto] [--max-iterations N]"
model: haiku
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-spec-loop.sh)", "Read", "TodoWrite", "Bash", "Edit", "AskUserQuestion"]
hide-from-slash-command-tool: "true"
---

# Spec Loop Command

Implement an approved OpenSpec change iteratively, keeping tasks.md in sync until all tasks are complete.

**IMPORTANT**: Keep edits minimal and focused on the requested change. Update `tasks.md` after each task completion. Use the plan_reference for full implementation details if needed. The loop will not end until ALL tasks are marked `[x]`.

## Why Spec Loop?

This command is an alternative to the 5-stage Beads workflow. Use it when you want the iterative loop benefits without Beads:

| Workflow | When to Use |
|----------|-------------|
| `/implement-loop` | Plans from `/plan-creator`, `/bug-plan-creator`, `/code-quality-plan-creator` |
| `/spec-loop` | OpenSpec changes (proposal.md + tasks.md) |
| `/beads-loop` | Large specs converted to self-contained Beads |

## Arguments

The command accepts the following arguments:
- Change ID (required): `<change-id>` - The OpenSpec change to implement
- Mode flag (optional): `--step` (default) or `--auto` - Controls pause behavior
- Iteration limit (optional): `--max-iterations N` - Maximum number of iterations

## Instructions

### Step 1: Setup

Run the setup script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-spec-loop.sh" $ARGUMENTS
```

You are now in **spec loop mode**. Your task is to implement the OpenSpec change completely.

### Guardrails

- Favor straightforward, minimal implementations first and add complexity only when it is requested or clearly required.
- Keep changes tightly scoped to the requested outcome.
- Refer to `openspec/AGENTS.md` if you need additional OpenSpec conventions or clarifications.

### Step 2: Read the Spec

Read these files from the change directory:
1. `proposal.md` - The approved change proposal
2. `design.md` - Technical design (if present)
3. `tasks.md` - The task checklist to complete

### Step 3: Create Todos

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

### Step 4: Implement Each Task

For each task:
1. Mark it as **in_progress** using TodoWrite
2. Reference the proposal/design for context
3. Implement the change with minimal, focused edits
4. Verify the implementation works
5. Mark as **completed** in TodoWrite
6. Update `tasks.md` to mark the task `[x]`

### Step 5: Keep tasks.md in Sync

**IMPORTANT**: After completing each task, update `tasks.md`:

```markdown
# Before
- [ ] Implement user authentication endpoint

# After
- [x] Implement user authentication endpoint
```

### Step 6: Confirm Completion

Before the loop ends:
1. Verify every task in `tasks.md` is marked `[x]`
2. Confirm all acceptance criteria from `proposal.md` are satisfied
3. Say "All spec tasks complete" when done

### Step 7: Loop Continues

When you try to exit:
- The stop hook checks `tasks.md` for uncompleted tasks
- If uncompleted tasks remain → loop continues
- If all tasks marked `[x]` → loop ends, implementation complete

### Step 8: Archive (Optional)

When all tasks are complete, you may archive the change:
```bash
openspec archive <change-id>
```

## Step Mode (Default)

Step mode pauses after each task for human control. This prevents context compaction and quality degradation on large specs.

**After completing each task, you MUST:**

1. Re-read `tasks.md` to get current status
2. Show execution order in the pause message
3. Use AskUserQuestion to let user confirm or pick

**Before pausing, output execution status:**
```
===============================================================
TASK COMPLETED: <task-name>
===============================================================

Progress: N/M tasks complete

EXECUTION ORDER (remaining):
  Next → Task 3: Add validation middleware
  Then → Task 4: Create unit tests
  Then → Task 5: Run integration tests
===============================================================
```

**Then use AskUserQuestion:**

The options MUST include:
1. **Continue (Recommended)** - proceed to next task in order
2. **Stop** - end the spec loop
3. **One option per remaining task** - let user pick a specific task
4. *(Other is automatic for feedback)*

Example with 2 remaining tasks:
```
Use AskUserQuestion with:
- question: "Task complete. Next: Add validation middleware. Continue?"
- header: "Next step"
- options:
  - label: "Continue (Recommended)"
    description: "Proceed to: Add validation middleware"
  - label: "Stop"
    description: "End the spec loop here"
  - label: "Create unit tests"
    description: "Skip to: Create unit tests"
```

Based on the response:
- **Continue**: Proceed to the next uncompleted task in order
- **Stop**: End the loop and report progress
- **Specific task**: Work on that task next (skip order)
- **Other/feedback**: Handle user's custom input

**Auto mode** (`--auto` flag): Skips pauses but still follows task order from tasks.md.

## Context Recovery

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

**Reference Commands:**

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

## Error Handling

| Scenario | Action |
|----------|--------|
| Context compacted mid-implementation | Use Quick Recovery or Deep Recovery steps above |
| Task verification fails | Keep task as in_progress, debug and fix before marking complete |
| Missing proposal.md or tasks.md | Run `openspec show <change-id>` to verify change exists |
| Uncompleted tasks remain at exit | Loop automatically continues until all tasks marked `[x]` |

## Example Usage

```bash
# Implement a specific OpenSpec change with step mode (default)
/spec-loop AUTH-001

# Implement with auto mode (no pauses)
/spec-loop AUTH-001 --auto

# Implement with iteration limit
/spec-loop AUTH-001 --max-iterations 10

# Implement with step mode explicitly
/spec-loop AUTH-001 --step
```
