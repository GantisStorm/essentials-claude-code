---
description: "Implement from conversation context with iterative loop"
argument-hint: "<task description>"
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit", "Read", "Glob", "Grep", "Write"]
model: opus
---

# Implement Loop Command

Execute implementation from conversation context and task description. Loops until exit criteria pass.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync state.

**Source:** Conversation context + argument input + mentioned files.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `<task description>` (required): What to implement (e.g., "fix the auth bug we discussed", "add the login feature")

## Instructions

### Step 1: Create Task Graph Immediately

**ONLY use what's already available:**
- The user's argument input
- Conversation history (already in context)

**DO NOT:**
- Read files unless the user explicitly asks you to
- Grep or explore the codebase
- Use Glob to find files

Create tasks immediately from context. Include file paths in task descriptions so they can be read during execution.

For each work item, create a task:

```json
TaskCreate({
  "subject": "Fix auth token validation",
  "description": "Full implementation details from context",
  "activeForm": "Fixing auth token validation"
})
```

**Set dependencies with `addBlockedBy`** — identify which tasks depend on others completing first:

```json
// Task 2 needs the type fix from task 1
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

A task with non-empty `blockedBy` shows as **blocked** in `ctrl+t`. When a blocking task is marked `completed`, it's automatically removed from the blocked list. A task becomes **ready** (executable) when its blockedBy list is empty.

### Step 2: Execute Tasks Sequentially

For each task (in dependency order):

1. **Claim**: `TaskUpdate({ taskId: "N", status: "in_progress" })`
2. **Read files as needed**: Use Read tool on file paths from task description
3. **Implement**: Make changes based on context
4. **Verify**: Run any task-specific verification
5. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
6. **Next**: Find next unblocked task via TaskList

### Step 3: Run Exit Criteria

Before declaring completion:
1. Run the verification (tests, commands, etc.)
2. If pass → "Exit criteria passed"
3. If fail → fix issues and retry

### Step 4: Loop Until Done

Continue until:
- All tasks completed AND
- Exit criteria pass

Say **"Exit criteria passed"** when complete.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 Fix token validation
■ #2 Update error handling
□ #3 Add tests > blocked by #2
```

## Context Tips

- Reference specific messages: "As we discussed, the token should..."
- Use patterns agreed upon in conversation
- If anything is unclear, ask before implementing

## Error Handling

| Scenario | Action |
|----------|--------|
| Context unclear | Ask for clarification |
| Exit criteria fail | Fix issues and retry |
| Context compacted | TaskList → continue |

## Example Usage

```bash
# After discussing a bug
/implement-loop fix the auth bug we discussed

# After agreeing on a feature
/implement-loop add the user profile endpoint

# Reference specific discussion
/implement-loop implement the caching strategy from above
```

