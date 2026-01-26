---
description: "Execute prd.json with parallel agent swarm (dependency-aware)"
argument-hint: "[prd_path] [--workers N] [--model MODEL]"
allowed-tools: ["Read", "Bash", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput"]
model: opus
---

# Tasks Swarm Command

Execute prd.json tasks using parallel worker agents. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync prd.json.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `[prd_path]` (optional): Path to prd.json (default: `./prd.json`)
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
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

For each userStory, create a task:

```json
TaskCreate({
  "subject": "US-001: Setup database schema",
  "description": "<full description from userStory - self-contained>",
  "activeForm": "Setting up database schema",
  "metadata": { "id": "US-001", "prdPath": "<prd-path>" }
})
```

Set dependencies from `dependsOn`:

```json
TaskUpdate({
  "taskId": "2",
  "addBlockedBy": ["1"]
})
```

Skip stories already completed (`passes: true`).

### Step 3: Queue-Based Execution

Use `--workers N` to limit concurrent agents (default: 3). This is a **queue**, not a pool.

**Initial spawn - up to N agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "US-001: Setup database schema",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Story ID: US-001
Subject: Setup database schema
Description: <full details from userStory>
PRD_PATH: <prd-path>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Update prd.json: jq '(.userStories[] | select(.id == \"US-001\")).passes = true' PRD_PATH > tmp.json && mv tmp.json PRD_PATH
5. Output ONLY a one-line summary (e.g. 'Done: US-001 database schema created')
6. Exit immediately - do NOT loop or produce detailed reports"
})
// + Task for US-002, US-003... up to N workers
```

**Track agent IDs** returned from each Task call for monitoring.

### Step 4: Monitor ALL Agents and Refill Queue

**Poll ALL active agents each cycle — never monitor just one:**

```
WHILE tasks remain incomplete:
  1. POLL ALL active agents in a SINGLE message (parallel tool calls):
     → TaskOutput({ task_id: <agent_1>, block: false })
     → TaskOutput({ task_id: <agent_2>, block: false })
     → TaskOutput({ task_id: <agent_3>, block: false })
     → One call per active agent, ALL in the same message

  2. If ANY agent completed → go to step 4

  3. If NONE completed → wait for one to finish:
     → Pick ONE active agent
     → TaskOutput({ task_id: <agent_id>, block: true })
     → When it returns → immediately poll ALL remaining with block: false
       to catch any that finished concurrently

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
- Step 1 MUST poll ALL active agents every cycle, not just one
- Step 3 blocks on one agent only as a "sleep until something happens"
- After the blocking call returns, ALWAYS re-poll ALL remaining agents (block: false)
  to catch concurrent completions before refilling slots
- Step 5 refills ALL empty slots, not just one
- When TaskOutput returns, DISCARD the verbose output — do NOT echo, summarize, or process it
  Only check: did the agent complete? Then move on. Full transcripts clog context.

**If user interrupts polling:**
- Active agents continue running in background
- User can say "check swarm status" or "resume polling"
- Poll all agents: TaskOutput({ block: false }) for EACH active agent in one message
- Use TaskList to see task completion status

### Step 5: Report Completion

Say **"Tasks swarm complete"** when all tasks finished.

**Recovery commands:**
- "check swarm status" → TaskList + TaskOutput(block: false) for ALL active agents in one message
- "resume polling" → Resume poll-all-agents loop from Step 4
- `/cancel-swarm` → Stop all agents

**Note:** Agents update prd.json (`passes: true`) as tasks complete. Compatible with RalphTUI.

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 2 in progress, 3 open)
■ #2 US-002: Auth service (Worker-1)
■ #3 US-003: Login route (Worker-2)
□ #4 US-004: Protected routes > blocked by #2
```

## Context Recovery

If context compacts:
1. Call TaskList to see all tasks and their status
2. Call TaskOutput(block: false) for ALL active agents in one message to get their reports

## Error Handling

| Scenario | Action |
|----------|--------|
| prd.json not found | Check path |
| Worker fails mid-task | Other workers continue; task stays in_progress |
| All tasks blocked | Circular dependency in dependsOn |

## Stopping

- Workers self-terminate when no work remains
- Use `/cancel-swarm` to halt early

## Example Usage

```bash
/tasks-swarm                                          # Auto-detects workers
/tasks-swarm ./prd.json --workers 5                   # Override: force 5 workers
/tasks-swarm .claude/prd/feature.json --model haiku   # Cheaper workers, auto count
```
