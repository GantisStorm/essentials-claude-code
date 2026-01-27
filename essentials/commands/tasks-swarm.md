---
description: "Execute prd.json with parallel agent swarm (dependency-aware)"
argument-hint: "[prd_path] [--workers N] [--model MODEL]"
allowed-tools: ["Read", "Bash", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task"]
model: opus
---

# Tasks Swarm Command

Execute prd.json tasks using parallel worker agents. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync prd.json.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `[prd_path]` (optional): Path to prd.json (default: `./prd.json`)
- `--workers N` (optional): Max concurrent workers (default: 3)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Read prd.json (Only)

**DO NOT read other files, grep, or explore the codebase** - just parse the prd.json:

```bash
cat <prd-path>
```

Parse the JSON and identify:
- All userStories
- Dependencies (`dependsOn` array)
- Priorities (lower number = higher priority)
- Completion status (`passes: true/false`)

### Step 2: Create Task Graph

Create a task for each userStory and build an **ID map** as you go:

```json
// Create tasks in order — each returns a task ID
TaskCreate({ "subject": "US-001: Setup database schema", ... })  // → task "1"
TaskCreate({ "subject": "US-002: Implement auth service", ... }) // → task "2"
TaskCreate({ "subject": "US-003: Add login route", ... })        // → task "3"

// ID map: { "US-001": "1", "US-002": "2", "US-003": "3" }
```

Full TaskCreate per story:

```json
TaskCreate({
  "subject": "US-001: Setup database schema",
  "description": "<full description from userStory - self-contained>",
  "activeForm": "Setting up database schema",
  "metadata": { "id": "US-001", "prdPath": "<prd-path>" }
})
```

**Translate `dependsOn` to `addBlockedBy`** using the ID map:

```json
// prd.json says: US-003 has dependsOn: ["US-001", "US-002"]
// ID map: US-001→"1", US-002→"2", US-003→"3"
TaskUpdate({
  "taskId": "3",
  "addBlockedBy": ["1", "2"]
})
```

A task with non-empty `blockedBy` shows as **blocked** in `ctrl+t`. When a blocking task is marked `completed`, it's automatically removed from the blocked list. A task becomes **ready** when its blockedBy list is empty.

Skip stories already completed (`passes: true`).

### Step 3: Spawn Workers

**Worker limit N** = `--workers` value or **3** if not specified. This is a queue — spawn up to N, then wait for completions before spawning more.

Mark each task `in_progress` before spawning its worker. Spawn up to N background workers in a **SINGLE message** (all Task calls in one response):

```json
Task({
  "description": "US-001: Setup database schema",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
  "prompt": "Execute this ONE task then exit:\n\nTask ID: 1\nStory ID: US-001\nSubject: Setup database schema\nDescription: <full details from userStory>\nPRD_PATH: <prd-path>\n\nSteps:\n1. Execute the task (read files, make changes, verify)\n2. Update prd.json: jq '(.userStories[] | select(.id == \"US-001\")).passes = true' PRD_PATH > tmp.json && mv tmp.json PRD_PATH\n3. Output ONLY a one-line summary\n4. Exit immediately"
})
```

After all Task() calls return, output a status message like "3 workers launched. Waiting for completions." and **end your turn**. The system wakes you when a worker finishes.

### Step 4: Process Completions

When a worker finishes, you are automatically woken. Then:

1. **TaskUpdate** — mark the finished worker's task as `completed`
2. **TaskList()** — see overall progress and find newly unblocked tasks
3. **Find ready tasks**: A task is ready when its status is `pending` AND its `blockedBy` list is empty. Completing a task automatically removes it from other tasks' `blockedBy` lists, potentially unblocking them.
4. Mark ready tasks `in_progress` and spawn new workers if slots available (respect worker limit N)
5. Output status and **end your turn** — you will be woken on the next completion

**Task lifecycle**: `pending` → (blocked until deps complete) → `in_progress` → `completed`

Repeat until all tasks completed → say **"Tasks swarm complete"**

**Note:** Agents update prd.json (`passes: true`) as tasks complete. Compatible with RalphTUI.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #2 US-002: Auth service (Worker-1)
■ #3 US-003: Login route (Worker-2)
□ #4 US-004: Protected routes > blocked by #2
```

## Error Handling

| Scenario | Action |
|----------|--------|
| prd.json not found | Check path |
| Worker fails mid-task | Other workers continue; task stays in_progress |
| All tasks blocked | Circular dependency in dependsOn |
| Context compacted | TaskList → spawn ready tasks → end turn |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
/tasks-swarm                                          # Default: 3 workers
/tasks-swarm ./prd.json --workers 5                   # Override: force 5 workers
/tasks-swarm .claude/prd/feature.json --model haiku   # Cheaper workers
```
