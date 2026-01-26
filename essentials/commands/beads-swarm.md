---
description: "Execute beads with parallel agent swarm (dependency-aware)"
argument-hint: "[--epic <epic-id>] [--label <label>] [--workers N] [--model MODEL]"
allowed-tools: ["Bash", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput"]
model: opus
---

# Beads Swarm Command

Execute beads tasks using parallel worker agents. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync beads.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `--epic <epic-id>` (optional): Filter beads by epic
- `--label <label>` (optional): Filter beads by label (default: `ralph`)
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
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

### Step 3: Queue-Based Execution

Use `--workers N` to limit concurrent agents (default: 3). This is a **queue**, not a pool.

**Initial spawn - up to N agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "beads-abc123: Implement login form",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Bead ID: beads-abc123
Subject: Implement login form
Description: <full details from bead>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Close bead: bd close beads-abc123 --reason 'Done'
5. Exit immediately - do NOT loop"
})
// + Task for beads-def456, beads-ghi789... up to N workers
```

**Track agent IDs** returned from each Task call for monitoring.

### Step 4: Monitor ALL Agents and Refill Queue

**Always monitor ALL active agents — never just one:**

```
WHILE tasks remain incomplete:
  1. POLL ALL active agents in a SINGLE message (parallel tool calls):
     → TaskOutput({ task_id: <agent_1>, block: false })
     → TaskOutput({ task_id: <agent_2>, block: false })
     → TaskOutput({ task_id: <agent_3>, block: false })
     → One call per active agent, ALL in the same message

  2. If ANY agent completed → go to step 4
     If NONE completed → go to step 3

  3. BLOCK on ALL active agents in a SINGLE message (parallel tool calls):
     → TaskOutput({ task_id: <agent_1>, block: true })
     → TaskOutput({ task_id: <agent_2>, block: true })
     → TaskOutput({ task_id: <agent_3>, block: true })
     → ALL calls in the same message, ALL with block: true
     → Each call blocks independently until its agent finishes
     → The message returns when ALL agents have completed

  4. Process ALL completed agents:
     → Remove each from active list

  5. FILL ALL EMPTY SLOTS:
     → Check TaskList for ready tasks (pending, unblocked)
     → slots_available = N - active_agents
     → ready_tasks = tasks that are pending AND not blocked
     → Spawn min(slots_available, ready_tasks) agents in SINGLE message
     → Track all new agent IDs in active list

  6. Repeat until all tasks complete
```

**CRITICAL:**
- ALWAYS include ALL active agents in every TaskOutput call — never monitor just one
- The non-blocking poll (step 1) catches fast completions without waiting
- The blocking call (step 3) monitors ALL remaining agents simultaneously
- After blocking returns, ALL agents have finished — refill ALL slots at once

**If user interrupts polling:**
- Active agents continue running in background
- User can say "check swarm status" or "resume polling"
- Poll all agents: TaskOutput({ block: false }) for EACH active agent in one message
- Use TaskList to see task completion status

When all complete:
```bash
bd sync  # Ensure changes are persisted
```

### Step 5: Report Completion

Say **"Beads swarm complete"** when all tasks finished.

**Recovery commands:**
- "check swarm status" → TaskList + TaskOutput(block: false) for ALL active agents in one message
- "resume polling" → Resume poll-all-agents loop from Step 4
- `/cancel-swarm` → Stop all agents

**Note:** Agents close beads as tasks complete. Compatible with RalphTUI.

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
2. Call TaskOutput(block: false) for ALL active agents in one message to get their reports
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
