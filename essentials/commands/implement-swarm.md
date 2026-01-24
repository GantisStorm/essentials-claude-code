---
description: "Implement from conversation context with parallel swarm"
argument-hint: "<task description> [--workers N] [--model MODEL]"
allowed-tools: ["Read", "Glob", "Grep", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Bash", "Edit"]
model: opus
---

# Implement Swarm Command

Execute implementation from conversation context using parallel workers. All workers complete → done.

**Source:** Conversation context + argument input + mentioned files.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `<task description>` (required): What to implement
- `--workers N` (optional): Override worker count (default: auto-detected)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

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
- **Verification**: How to confirm success

### Step 2: Confirm Understanding

Briefly confirm before spawning:
```
Implementing: [goal from argument + context]
Files: [list from discussion]
Verification: [approach]

Spawning swarm...
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

### Step 4: Calculate Optimal Workers

Analyze the task graph to find max parallelism:

1. Build dependency graph from tasks
2. Find the maximum width (most concurrent unblocked tasks)
3. Worker count = `min(max_width, 10)`

If `--workers N` provided, use that instead.

### Step 5: Spawn Worker Pool

**CRITICAL: Send ALL Task tool calls in a SINGLE message for true parallelism.**

Spawn N workers. Each worker loops until no work remains:

```json
Task({
  "description": "Worker-1 executor",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "prompt": "You are Worker-1 in a parallel swarm.

LOOP:
1. TaskList - find all tasks
2. Filter: pending, no owner, blockedBy all completed
3. TaskUpdate - claim: owner: Worker-1, status: in_progress
4. Execute task per description
5. TaskUpdate - status: completed
6. GOTO 1

STOP WHEN: All tasks completed OR no claimable tasks remain
CONFLICT: If already claimed by another, skip and find next"
})
```

### Step 6: Report Launch

```
Swarm launched:
- Tasks: N
- Workers: 3 (auto-detected)

Press ctrl+t for progress
```

### Step 7: Collect Results

When all complete, say **"Swarm complete"**.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #3 Fix validation (Worker-1)
■ #4 Update tests (Worker-2)
□ #5 Integration > blocked by #3, #4
```

## Context Tips

- Reference specific messages from conversation
- Use patterns agreed upon in discussion
- If anything is unclear, ask before spawning

## Error Handling

| Scenario | Action |
|----------|--------|
| Context unclear | Ask for clarification |
| Worker fails mid-task | Other workers continue |
| All tasks blocked | Circular dependency |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
# After discussing a bug
/implement-swarm fix the auth bug we discussed

# With worker override
/implement-swarm refactor the API handlers --workers 5

# Cheaper workers for simple tasks
/implement-swarm update all the error messages --model haiku
```

## When to Use

- After back-and-forth discussion about work
- When tasks are parallelizable and speed matters
- For quick implementations without formal planning

**For structured plans:** Use `/plan-swarm <plan-file>` instead.
