---
description: "Implement from plan file OR conversation context with parallel swarm"
argument-hint: "[plan_path] [--workers N] [--model MODEL]"
allowed-tools: ["Read", "Glob", "Grep", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Bash", "Edit"]
model: opus
---

# Implement Swarm Command

Execute implementation using parallel worker agents. All workers complete → done.

**Works with:**
- A plan file path (if provided)
- OR the current conversation context (if no path provided)

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `[plan_path]` (optional): Path to plan file. If omitted, uses conversation context.
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

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
  - **Verification**: How to confirm success

### Step 2: Confirm Understanding (Context Mode Only)

If using context, briefly confirm:
```
Based on our discussion, I'll implement:
- [Goal summary]
- Files: [list]
- Verification: [how to check]

Spawning swarm...
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

### Step 4: Calculate Optimal Workers

Analyze the task graph to find max parallelism:

1. Build dependency graph from tasks
2. Find the maximum width (most concurrent unblocked tasks at any point)
3. Worker count = `min(max_width, 10)` (cap at 10)

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
- Tasks: N (with M dependency edges)
- Max parallelism: 3 (auto-detected)
- Workers: 3 (background)

Press ctrl+t for progress
```

### Step 7: Collect Results

When asked for status:
1. TaskList - see all task states
2. TaskOutput - get worker reports
3. Summarize completed/in-progress/blocked/failed

Say **"Swarm complete"** when all tasks finished.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #3 Implement auth (Worker-1)
■ #4 Add routes (Worker-2)
□ #5 Integration tests > blocked by #3, #4
```

## Context Mode Tips

When using conversation context:
- Reference specific messages: "As we discussed, the login should..."
- Use agreed-upon patterns from the conversation
- If anything is unclear, ask before spawning workers

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Context unclear | Ask for clarification |
| Worker fails mid-task | Other workers continue |
| All tasks blocked | Circular dependency |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
# With plan file
/implement-swarm .claude/plans/add-user-auth.md

# From conversation context (after discussing a feature/bug)
/implement-swarm

# With options
/implement-swarm --workers 5
/implement-swarm .claude/plans/refactor.md --model haiku
```

## When to Use

- **With plan file**: For structured, pre-planned work
- **From context**: After back-and-forth discussion about a bug fix or feature
- **Swarm vs Loop**: Use swarm when tasks are parallelizable and speed matters
