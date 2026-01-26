---
description: "Execute beads with parallel agent swarm (dependency-aware)"
argument-hint: "[--epic <epic-id>] [--label <label>] [--workers N] [--model MODEL]"
allowed-tools: ["Bash", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task"]
model: opus
---

# Beads Swarm Command

Execute beads tasks using parallel worker agents. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync beads.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `--epic <epic-id>` (optional): Filter beads by epic
- `--label <label>` (optional): Filter beads by label (default: `ralph`)
- `--workers N` (optional): Max concurrent workers (default: 3)
- `--model MODEL` (optional): Model for workers: haiku, sonnet, opus (default: sonnet)

## Instructions

### Step 1: Load Beads (Only)

**DO NOT read files, grep, or explore the codebase** - just get beads from CLI:

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

### Step 3: Spawn Workers

**Worker limit N** = `--workers` value or **3** if not specified. This is a queue — spawn up to N, then wait for completions before spawning more.

Mark each task `in_progress` before spawning its worker. Spawn up to N background workers in a **SINGLE message** (all Task calls in one response):

```json
Task({
  "description": "beads-abc123: Implement login form",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep"],
  "prompt": "Execute this ONE task then exit:\n\nTask ID: 1\nBead ID: beads-abc123\nSubject: Implement login form\nDescription: <full details from bead>\n\nSteps:\n1. Execute the task (read files, make changes, verify)\n2. Close bead: bd close beads-abc123 --reason 'Done'\n3. Output ONLY a one-line summary\n4. Exit immediately"
})
```

After all Task() calls return, output a status message like "3 workers launched. Waiting for completions." and **end your turn**. The system wakes you when a worker finishes.

### Step 4: Process Completions

When a worker finishes, you are automatically woken. Then:

1. **TaskUpdate** — mark the finished worker's task as `completed`
2. **TaskList()** — see overall progress and find ready tasks
3. Mark ready tasks `in_progress` and spawn new workers if slots available
4. Output status and **end your turn** — you will be woken on the next completion

Repeat until all tasks completed → run `bd sync` then say **"Beads swarm complete"**

**Note:** Agents close beads as tasks complete. Compatible with RalphTUI.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #2 beads-def456: Auth service (Worker-1)
■ #3 beads-ghi789: Login route (Worker-2)
□ #4 beads-jkl012: Protected routes > blocked by #2
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No beads found | Check epic/label filters |
| Worker fails mid-task | Other workers continue; bead not closed |
| Beads CLI not found | Install: `brew tap steveyegge/beads && brew install bd` |
| Context compacted | TaskList → spawn ready tasks → end turn |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early
- After stopping: `bd sync`

## Example Usage

```bash
/beads-swarm                                    # Default: 3 workers
/beads-swarm --epic beads-abc123 --workers 5    # Override: force 5 workers
/beads-swarm --label my-feature --model haiku   # Cheaper workers
```
