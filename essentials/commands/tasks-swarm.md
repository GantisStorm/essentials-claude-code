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

**Worker limit N** = `--workers` value or **3** if not specified. NEVER exceed N concurrent agents.

This is a **queue**, not a pool — spawn up to N, then wait for completions before spawning more.

**Initial spawn — exactly min(N, ready_tasks) agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "US-001: Setup database schema",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep",
                     "TaskUpdate", "TaskList", "TaskGet"],
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

After spawning, call **TaskList()** once to confirm workers started. Then **STOP: output a short status message with ZERO tool calls.** Example: "3 workers running, 4 queued. Waiting for completions." Your turn ends and the system resumes you when a worker finishes.

### Step 4: Wait for Background Agent Notifications

Background agents automatically notify the main agent when they finish (v2.0.64+). The main agent gets woken up with zero effort.

**When woken by a background agent completing:**

1. Call **TaskList()** — see which tasks completed
2. **Fallback:** If the completed worker's task still shows pending/in_progress, mark it completed via TaskUpdate (workers may not always self-update)
3. Check for ready tasks (pending AND not blocked)
4. If slots available (N - in_progress_count > 0) AND ready tasks exist:
   → Spawn new workers in a SINGLE message to fill slots
   → Call **TaskList()** once to confirm
5. If all tasks completed → say **"Tasks swarm complete"**
6. Otherwise → **STOP: output a short status message with ZERO tool calls** — system resumes you on next completion

**CRITICAL — what STOP means:**
- **STOP = respond with text and ZERO tool calls.** This ends your turn. The system resumes you when a worker finishes. Do NOT call TaskList again after stopping — you will be woken automatically.
- NEVER call TaskOutput — it returns full agent transcripts (70k+ tokens) that flood context
- NEVER poll TaskList in a loop — call it ONCE when woken, then STOP
- Workers are granted TaskUpdate via allowed_tools and SHOULD self-update status — but always verify via TaskList and fix any missed updates
- TaskList returns only metadata (IDs, subjects, statuses) — zero context bloat
- Refill ALL empty slots each cycle, not just one

**Recovery commands:**
- "check swarm status" → TaskList (shows all task statuses)
- "resume swarm" → TaskList, then spawn workers for any ready tasks, then STOP (text only, zero tool calls)
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
2. Count in_progress tasks to determine active worker count
3. Spawn workers for any ready tasks if slots available
4. STOP (text only, zero tool calls) — system resumes you on next completion

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
