---
description: "Implement from conversation context with parallel swarm"
argument-hint: "<task description> [--workers N] [--model MODEL]"
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Task", "Bash"]
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

**Worker limit N** = `--workers` value or **3** if not specified. NEVER exceed N concurrent agents.

This is a **queue**, not a pool — spawn up to N, then wait for completions before spawning more.

**Initial spawn — exactly min(N, ready_tasks) agents in a SINGLE message:**

```json
// Spawn all initial agents in ONE message for true parallelism
Task({
  "description": "Task-1: Fix auth validation",
  "subagent_type": "general-purpose",
  "model": "sonnet",
  "run_in_background": true,
  "allowed_tools": ["Read", "Edit", "Write", "Bash", "Glob", "Grep",
                     "TaskUpdate", "TaskList", "TaskGet"],
  "prompt": "Execute this ONE task then exit:

Task ID: 1
Subject: Fix auth token validation
Description: <full details>

Steps:
1. TaskUpdate({ taskId: '1', status: 'in_progress' })
2. Execute the task (read files, make changes, verify)
3. TaskUpdate({ taskId: '1', status: 'completed' })
4. Output ONLY a one-line summary (e.g. 'Done: fixed auth validation in auth.ts')
5. Exit immediately - do NOT loop or produce detailed reports"
})
// + Task for #2, #3... up to N workers
```

**After all Task() calls return, immediately output a status message like:**
"3 workers launched. Waiting for completions."
**Do NOT call TaskList or any other tool.** Your turn is done.

### Step 3: Handle Worker Completions

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

