---
description: "Implement from conversation context with parallel swarm"
argument-hint: "<task description> [--workers N] [--model MODEL]"
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Bash"]
model: opus
---

# Implement Swarm Command

Execute implementation from conversation context using parallel workers. All workers complete → done.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync state.

**Source:** Conversation context + argument input + mentioned files.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `<task description>` (required): What to implement
- `--workers N` (optional): Override worker count (default: auto-detected)
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

### Step 2: Queue-Based Execution

Use `--workers N` to limit concurrent agents (default: 3). This is a **queue**, not a pool.

**Initial spawn - up to N agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "Task-1: Fix auth validation",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Subject: Fix auth token validation
Description: <full details>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Exit immediately - do NOT loop"
})
// + Task for #2, #3... up to N workers
```

**Track agent IDs** returned from each Task call for monitoring.

### Step 3: Monitor ALL Agents and Refill Queue

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

**If user interrupts polling:**
- Active agents continue running in background
- User can say "check swarm status" or "resume polling"
- Poll all agents: TaskOutput({ block: false }) for EACH active agent in one message
- Use TaskList to see task completion status

### Step 4: Report Completion

When all tasks complete, say **"Swarm complete"**.

**Recovery commands:**
- "check swarm status" → TaskList + TaskOutput(block: false) for ALL active agents in one message
- "resume polling" → Resume poll-all-agents loop from Step 3
- `/cancel-swarm` → Stop all agents

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

