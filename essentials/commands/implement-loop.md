---
description: "Implement from plan file OR conversation context with iterative loop"
argument-hint: "[plan_path] [--max-iterations N]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit", "Glob", "Grep"]
model: opus
---

# Implement Loop Command

Execute implementation iteratively until all tasks complete AND exit criteria pass.

**Works with:**
- A plan file path (if provided)
- OR the current conversation context (if no path provided)

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `[plan_path]` (optional): Path to plan file. If omitted, uses conversation context.
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Step 1: Determine Source

**If plan path provided:**
- Read the plan file
- Extract tasks, requirements, exit criteria

**If NO plan path (context mode):**
- Review the conversation history
- Identify what was discussed and agreed upon
- Extract:
  - **Goal**: What needs to be implemented
  - **Requirements**: Acceptance criteria from discussion
  - **Files**: Which files to modify/create
  - **Exit Criteria**: How to verify success (tests, commands, etc.)

### Step 2: Confirm Understanding (Context Mode Only)

If using context, briefly confirm:
```
Based on our discussion, I'll implement:
- [Goal summary]
- Files: [list]
- Exit criteria: [verification command]

Proceeding with implementation...
```

### Step 3: Create Task Graph

For each work item, create a task:

```json
TaskCreate({
  "subject": "Implement auth middleware",
  "description": "Full implementation details - self-contained",
  "activeForm": "Implementing auth middleware"
})
```

Set dependencies:

```json
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

### Step 4: Execute Tasks Sequentially

For each task (in dependency order):

1. **Claim**: `TaskUpdate({ taskId: "N", status: "in_progress" })`
2. **Implement**: Make changes
3. **Verify**: Run any task-specific verification
4. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
5. **Next**: Find next unblocked task via TaskList

### Step 5: Run Exit Criteria

Before declaring completion:
1. Run the verification command(s)
2. If pass → "Exit criteria passed - implementation complete"
3. If fail → fix issues and retry

### Step 6: Loop Until Done

Continue until:
- All tasks completed AND
- Exit criteria pass

Say **"Exit criteria passed"** when complete.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 Setup database schema
■ #2 Implement auth middleware
□ #3 Add login route > blocked by #2
```

## Context Mode Tips

When using conversation context:
- Reference specific messages: "As we discussed, the login should..."
- Use agreed-upon patterns from the conversation
- If anything is unclear, ask before implementing

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Context unclear | Ask for clarification |
| Exit criteria fail | Fix issues and retry |
| Context compacted | TaskList → continue |

## Example Usage

```bash
# With plan file
/implement-loop .claude/plans/add-user-auth.md

# From conversation context (after discussing a feature/bug)
/implement-loop

# With iteration limit
/implement-loop --max-iterations 10
```

## When to Use

- **With plan file**: For structured, pre-planned work
- **From context**: After back-and-forth discussion about a bug fix or feature
