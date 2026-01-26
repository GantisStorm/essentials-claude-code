---
description: "Execute a plan file with parallel agent swarm (dependency-aware)"
argument-hint: "<plan_path> [--workers N] [--model MODEL]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "Bash"]
model: opus
---

# Plan Swarm Command

Execute a plan file using parallel worker agents. **Requires a plan file.** All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync state.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

- `<plan_path>` (required): Path to the plan file
- `--workers N` (optional): Max concurrent workers (default: 3)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Read the Plan (Only)

Read the plan file and extract tasks. **DO NOT read other files, grep, or explore the codebase** - just parse the plan:
1. **Files to Edit** - existing files that need modification
2. **Files to Create** - new files to create
3. **Implementation Plan** - per-file implementation instructions
4. **Requirements** - acceptance criteria
5. **Exit Criteria** - verification script and success conditions

### Step 2: Create Task Graph

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

### Step 3: Spawn Workers

**Worker limit N** = `--workers` value or **3** if not specified. This is a queue — spawn up to N, then wait for completions before spawning more.

Mark each task `in_progress` before spawning its worker. Spawn up to N background workers in a **SINGLE message** (all Task calls in one response):

```json
Task({
  "description": "Task-1: Implement auth middleware",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
  "prompt": "Execute this ONE task then exit:\n\nTask ID: 1\nSubject: Implement auth middleware\nDescription: <full details from plan>\n\nSteps:\n1. Execute the task (read files, make changes, verify)\n2. Output ONLY a one-line summary\n3. Exit immediately"
})
```

After all Task() calls return, output a status message like "3 workers launched. Waiting for completions." and **end your turn**. The system wakes you when a worker finishes.

### Step 4: Process Completions

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
■ #3 Implement auth (Worker-1)
■ #4 Add routes (Worker-2)
□ #5 Integration tests > blocked by #3, #4
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Worker fails mid-task | Other workers continue; task stays in_progress |
| All tasks blocked | Circular dependency - review task graph |
| Context compacted | TaskList → spawn ready tasks → end turn |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
/plan-swarm .claude/plans/add-user-auth.md              # Default: 3 workers
/plan-swarm .claude/plans/refactor.md --workers 5       # Override: force 5 workers
/plan-swarm .claude/plans/docs.md --model haiku         # Cheaper workers
```
