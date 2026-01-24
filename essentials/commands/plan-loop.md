---
description: "Execute a plan file with iterative loop until completion"
argument-hint: "<plan_path> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh)", "Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit"]
hide-from-slash-command-tool: "true"
model: opus
---

# Plan Loop Command

Execute a plan file iteratively until all tasks are complete AND exit criteria pass. **Requires a plan file.**

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

**IMPORTANT**: The plan file is your source of truth. Exit Criteria MUST pass before the loop will end.

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

- `<plan_path>` (required): Path to the plan file
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Step 1: Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh" $ARGUMENTS
```

### Step 2: Read the Plan

Read the plan file and extract:
1. **Files to Edit** - existing files that need modification
2. **Files to Create** - new files to create
3. **Implementation Plan** - per-file implementation instructions
4. **Requirements** - acceptance criteria
5. **Exit Criteria** - verification script and success conditions

### Step 3: Create Task Graph

For each work item, create a task with dependencies:

```json
TaskCreate({
  "subject": "Implement auth middleware",
  "description": "Full implementation details from plan - self-contained",
  "activeForm": "Implementing auth middleware"
})
```

Set dependencies based on plan structure:

```json
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

**Task types:**
- File edits/creates → one task per file
- Major requirements → one task each
- Exit criteria verification → final task, blocked by all others

### Step 4: Execute Tasks Sequentially

For each task (in dependency order):

1. **Claim**: `TaskUpdate({ taskId: "N", status: "in_progress" })`
2. **Read**: Get relevant section from plan
3. **Implement**: Make changes following plan exactly
4. **Verify**: Run any task-specific verification
5. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
6. **Next**: Find next unblocked task via TaskList

### Step 5: Run Exit Criteria

Before declaring completion:
1. Find the `## Exit Criteria` section in the plan
2. Run the verification command
3. If it passes, say "Exit criteria passed - implementation complete"
4. If it fails, fix the issues and retry

### Step 6: Loop Until Done

The stop hook checks:
- If verification PASSES → loop ends
- If verification FAILS → loop continues with error context
- If tasks remain incomplete → loop continues

Say **"Exit criteria passed"** when complete.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 Setup database schema
■ #2 Implement auth middleware
□ #3 Add login route > blocked by #2
□ #4 Add protected routes > blocked by #2
□ #5 Run exit criteria > blocked by #3, #4
```

## Context Recovery

If context compacts:
1. Call TaskList to see all tasks and their status
2. Read the plan file again
3. Find next pending unblocked task
4. Continue implementation

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Exit criteria fail | Fix issues and retry |
| Context compacted | TaskList → re-read plan → continue |

## Example Usage

```bash
/plan-loop .claude/plans/add-user-auth.md
/plan-loop .claude/plans/fix-memory-leak.md --max-iterations 10
```
