---
description: "Execute beads with parallel agent swarm (dependency-aware)"
argument-hint: "[--epic <epic-id>] [--label <label>] [--workers N] [--model MODEL]"
allowed-tools: ["Bash", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Read", "Edit"]
model: opus
---

# Beads Swarm Command

Execute beads tasks using parallel worker agents. All workers complete → done.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `--epic <epic-id>` (optional): Filter beads by epic
- `--label <label>` (optional): Filter beads by label (default: `ralph`)
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Load Beads

```bash
bd list --status open --json
# Or with filters:
bd list --epic <epic-id> --status open --json
bd list -l <label> --status open --json
```

Parse the output to get all beads.

### Step 2: Create Task Graph

For each bead, create a task:

```json
TaskCreate({
  "subject": "beads-abc123: Implement login form",
  "description": "<full bead description - self-contained>",
  "activeForm": "Implementing login form",
  "metadata": { "beadId": "beads-abc123" }
})
```

Set dependencies based on parent/child relationships:

```json
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

### Step 3: Calculate Optimal Workers

Analyze the task graph to find max parallelism:

1. Build dependency graph from parent/child relationships
2. Find the maximum width (most concurrent unblocked tasks at any point)
3. Worker count = `min(max_width, 10)` (cap at 10 to avoid overload)

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
6. Close bead: bd close <beadId> --reason 'Done'
7. GOTO 1

STOP WHEN: All tasks completed OR no claimable tasks remain
CONFLICT: If already claimed by another, skip and find next"
})
```

### Step 5: Report Launch

```
Beads Swarm launched:
- Beads: N
- Max parallelism: 3 (auto-detected)
- Workers: 3 (background)

Press ctrl+t for progress
```

### Step 6: Collect Results

When asked for status:
1. TaskList - see all task states
2. TaskOutput - get worker reports
3. Verify beads closed: `bd list --status closed`

When all complete:
```bash
bd sync  # Ensure changes are persisted
```

Say **"Beads swarm complete"** when all tasks finished.

**Note:** Workers close beads as tasks complete. Compatible with RalphTUI.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #2 beads-def456: Auth service (Worker-1)
■ #3 beads-ghi789: Login route (Worker-2)
□ #4 beads-jkl012: Protected routes > blocked by #2
```

## Context Recovery

If context compacts:
1. Call TaskList to see all tasks and their status
2. Call TaskOutput on workers for their reports
3. Check beads: `bd ready`

## Error Handling

| Scenario | Action |
|----------|--------|
| No beads found | Check epic/label filters |
| Worker fails mid-task | Other workers continue; bead not closed |
| Beads CLI not found | Install: `brew tap steveyegge/beads && brew install bd` |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early
- After stopping: `bd sync`

## Example Usage

```bash
/beads-swarm                                    # Auto-detects workers
/beads-swarm --epic beads-abc123 --workers 5    # Override: force 5 workers
/beads-swarm --label my-feature --model haiku   # Cheaper workers, auto count
```
