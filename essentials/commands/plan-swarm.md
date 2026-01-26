---
description: "Execute a plan file with parallel agent swarm (dependency-aware)"
argument-hint: "<plan_path> [--workers N] [--model MODEL]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "TaskOutput", "Bash"]
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
- `--workers N` (optional): Override worker count (default: auto-detected from task graph)
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

### Step 3: Queue-Based Execution

Use `--workers N` to limit concurrent agents (default: 3). This is a **queue**, not a pool.

**Initial spawn - up to N agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "Task-1: Implement auth middleware",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Subject: Implement auth middleware
Description: <full details from plan>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Exit immediately - do NOT loop"
})
// + Task for #2, #3... up to N workers
```

**Track agent IDs** returned from each Task call for monitoring.

### Step 4: Poll All Agents and Refill Queue

**Monitor ALL active agents — never block on just one:**

```
WHILE tasks remain incomplete:
  1. POLL ALL active agents in a SINGLE message (parallel calls):
     → TaskOutput({ task_id: <agent_1>, block: false })
     → TaskOutput({ task_id: <agent_2>, block: false })
     → TaskOutput({ task_id: <agent_3>, block: false })
     → ... one call per active agent, ALL in the same message

  2. CHECK results:
     → If ANY agent completed → go to step 3
     → If NONE completed → pick ONE active agent, call:
       TaskOutput({ task_id: <agent_id>, block: true })
       Then immediately re-poll ALL remaining agents with block: false
       to catch concurrent completions

  3. Process ALL completed agents:
     → Remove each from active list

  4. FILL ALL EMPTY SLOTS:
     → Check TaskList for ready tasks (pending, unblocked)
     → slots_available = N - active_agents
     → ready_tasks = tasks that are pending AND not blocked
     → Spawn min(slots_available, ready_tasks) agents in SINGLE message
     → Track all new agent IDs in active list

  5. Repeat until all tasks complete
```

**CRITICAL:** Always poll ALL active agents each iteration. Never block on one agent while others may have finished.

**If user interrupts polling:**
- Active agents continue running in background
- User can say "check swarm status" or "resume polling"
- Poll all agents: TaskOutput({ block: false }) for EACH active agent in one message
- Use TaskList to see task completion status

### Step 5: Report Completion

Say **"Swarm complete"** when all tasks finished.

**Recovery commands:**
- "check swarm status" → TaskList + TaskOutput(block: false) for ALL active agents in one message
- "resume polling" → Resume poll-all-agents loop from Step 4
- `/cancel-swarm` → Stop all agents

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
2. Call TaskOutput(block: false) for ALL active agents in one message to get their reports
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
