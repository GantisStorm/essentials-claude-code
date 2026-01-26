---
description: "Implement from conversation context with parallel swarm"
argument-hint: "<task description> [--workers N] [--model MODEL]"
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "Bash"]
model: opus
---

# Implement Swarm Command

Execute implementation from conversation context using parallel workers. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync state.

**Source:** Conversation context + argument input + mentioned files.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `<task description>` (required): What to implement
- `--workers N` (optional): Max concurrent workers (default: 3)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Create Task Graph Immediately

**ONLY use what's already available:**
- The user's argument input
- Conversation history (already in context)

**DO NOT:**
- Read files unless the user explicitly asks you to
- Grep or explore the codebase
- Use Glob to find files

Create tasks immediately from context. Include file paths in task descriptions so workers can read them during execution.

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

### Step 2: Spawn Workers

**Worker limit N** = `--workers` value or **3** if not specified. This is a queue — spawn up to N, then wait for completions before spawning more.

Mark each task `in_progress` before spawning its worker. Spawn up to N background workers in a **SINGLE message** (all Task calls in one response):

```json
Task({
  "description": "Task-1: Fix auth validation",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
  "prompt": "Execute this ONE task then exit:\n\nTask ID: 1\nSubject: Fix auth token validation\nDescription: <full details>\n\nSteps:\n1. Execute the task (read files, make changes, verify)\n2. Output ONLY a one-line summary\n3. Exit immediately"
})
```

After all Task() calls return, output a status message like "3 workers launched. Waiting for completions." and **end your turn**. The system wakes you when a worker finishes.

### Step 3: Process Completions

When a worker finishes, you are automatically woken. Then:

1. **TaskUpdate** — mark the finished worker's task as `completed`
2. **TaskList()** — see overall progress and find ready tasks
3. Mark ready tasks `in_progress` and spawn new workers if slots available
4. Output status and **end your turn** — you will be woken on the next completion

Repeat until all tasks completed → say **"Swarm complete"**

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
| Context compacted | TaskList → spawn ready tasks → end turn |

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
