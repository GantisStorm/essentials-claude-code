---
description: "Implement from conversation context with iterative loop"
argument-hint: "<task description>"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit", "Glob", "Grep"]
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

### Step 1: Analyze Context

Review everything available:

1. **Argument input**: What the user is asking to implement
2. **Conversation history**: What was discussed, agreed upon, debugged
3. **Files mentioned**: Any files referenced in the conversation
4. **Requirements**: Acceptance criteria from discussion

Extract:
- **Goal**: What needs to be done
- **Files**: Which files to modify/create
- **Exit Criteria**: How to verify success (tests, commands, behavior)

### Step 2: Confirm Understanding

Briefly confirm before starting:
```
Implementing: [goal from argument + context]
Files: [list from discussion]
Exit criteria: [verification approach]

Proceeding...
```

### Step 3: Create Task Graph

For each work item, create a task:

```json
TaskCreate({
  "subject": "Fix auth token validation",
  "description": "Full implementation details from context",
  "activeForm": "Fixing auth token validation"
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
2. **Implement**: Make changes based on context
3. **Verify**: Run any task-specific verification
4. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
5. **Next**: Find next unblocked task via TaskList

### Step 5: Run Exit Criteria

Before declaring completion:
1. Run the verification (tests, commands, etc.)
2. If pass → "Exit criteria passed"
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

