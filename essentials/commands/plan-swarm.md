---
description: "Execute a plan file with parallel agent swarm (dependency-aware)"
argument-hint: "<plan_path> [--workers N] [--model MODEL]"
allowed-tools: ["Read", "Glob", "Grep", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Bash", "Edit"]
model: opus
---

# Plan Swarm Command

Execute a plan file using parallel worker agents. **Requires a plan file.** All workers complete → done.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

- `<plan_path>` (required): Path to the plan file
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Read the Plan

Read the plan file and extract:
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

### Step 3: Calculate Optimal Workers

Analyze the task graph to find max parallelism:

1. Build dependency graph from tasks
2. Find the maximum width (most concurrent unblocked tasks at any point)
3. Worker count = `min(max_width, 10)` (cap at 10 to avoid overload)

**Example:**
```
#1 ──→ #3 ──→ #5
#2 ──→ #4 ──┘

Max width = 2 (tasks #1 and #2 can run together, then #3 and #4)
→ Spawn 2 workers
```

If `--workers N` provided, use that instead.

### Step 4: Spawn Worker Pool

**CRITICAL: Send ALL Task tool calls in a SINGLE message for true parallelism.**

Spawn N workers (auto-detected or overridden). Each worker loops until no work remains:

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

### Step 5: Report Launch

```
Swarm launched:
- Tasks: N (with M dependency edges)
- Max parallelism: 3 (auto-detected)
- Workers: 3 (background)

Press ctrl+t for progress
```

### Step 6: Collect Results

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

## Context Recovery

If context compacts:
1. Call TaskList to see all tasks and their status
2. Call TaskOutput on workers for their reports
3. Check what remains

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Worker fails mid-task | Other workers continue; task stays in_progress |
| All tasks blocked | Circular dependency - review task graph |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
/plan-swarm .claude/plans/add-user-auth.md              # Auto-detects workers
/plan-swarm .claude/plans/refactor.md --workers 5       # Override: force 5 workers
/plan-swarm .claude/plans/docs.md --model haiku         # Cheaper workers, auto count
```
