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

**Worker limit N** = `--workers` value or **3** if not specified. NEVER exceed N concurrent agents.

This is a **queue**, not a pool — spawn up to N, then wait for completions before spawning more.

**Initial spawn — exactly min(N, ready_tasks) agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "Task-1: Implement auth middleware",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep",
                     "TaskUpdate", "TaskList", "TaskGet"],
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Subject: Implement auth middleware
Description: <full details from plan>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Output ONLY a one-line summary (e.g. 'Done: implemented auth middleware')
5. Exit immediately - do NOT loop or produce detailed reports"
})
// + Task for #2, #3... up to N workers
```

**After all Task() calls return, immediately output a status message like:**
"3 workers launched. Waiting for completions."
**Do NOT call TaskList or any other tool.** Your turn is done.

### Step 4: Handle Worker Completions

Background agents automatically notify you when they finish. You get woken up — then:

1. Call **TaskList()** — see which tasks completed
2. **Fallback:** If the completed worker's task still shows pending/in_progress, mark it completed via TaskUpdate (workers may not always self-update)
3. Spawn new workers for any ready tasks (pending AND not blocked) if slots available
4. If all tasks completed → say **"Swarm complete"**
5. Otherwise → output a short status message. **Do NOT call any more tools.** Your turn is done — you will be woken on the next completion.

**CRITICAL:**
- After spawning or after processing a completion: **output text, then make ZERO more tool calls.** This is how you wait. You WILL be woken when the next worker finishes.
- NEVER call TaskList in a loop — call it exactly ONCE per wake-up
- NEVER call TaskOutput — full transcripts (70k+ tokens) flood context
- NEVER use sleep — just output text and stop
- Workers are granted TaskUpdate via allowed_tools and SHOULD self-update status — but always verify via TaskList and fix any missed updates
- Refill ALL empty slots each cycle, not just one

**Recovery commands:**
- "check swarm status" → TaskList (shows all task statuses)
- "resume swarm" → TaskList, spawn workers for ready tasks, then output text and stop
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
2. Count in_progress tasks to determine active worker count
3. Spawn workers for any ready tasks if slots available
4. Output text and stop — do NOT call any more tools. You will be woken on next completion.

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
