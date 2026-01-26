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

**Worker limit N** = `--workers` value or **3** if not specified. NEVER exceed N concurrent agents.

This is a **queue**, not a pool — spawn up to N, then wait for completions before spawning more.

**Initial spawn — exactly min(N, ready_tasks) agents in a SINGLE message:**

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
5. Output ONLY a one-line summary (e.g. 'Done: implemented login form')
6. Exit immediately - do NOT loop or produce detailed reports"
})
// + Task for beads-def456, beads-ghi789... up to N workers
```

After spawning, call **TaskList()** once to confirm workers started. Then **stop and wait** — do NOT loop or sleep.

### Step 4: Wait for Background Agent Notifications

**Do NOT poll or sleep.** Background agents automatically notify the main agent when they finish (v2.0.64+). The main agent gets woken up with zero effort.

**When woken by a background agent completing:**

1. Call **TaskList()** — see which tasks completed
2. Check for ready tasks (pending AND not blocked)
3. If slots available (N - in_progress_count > 0) AND ready tasks exist:
   → Spawn new workers in a SINGLE message to fill slots
   → Call **TaskList()** once to confirm
4. If all tasks completed → run `bd sync` then say **"Beads swarm complete"**
5. Otherwise → **stop and wait** for next notification

**CRITICAL:**
- NEVER call TaskOutput — it returns full agent transcripts (70k+ tokens) that flood context
- NEVER use sleep loops — background agents wake the main agent automatically
- Workers update TaskList via TaskUpdate({ status: 'completed' }) — this is the sole source of truth
- TaskList returns only metadata (IDs, subjects, statuses) — zero context bloat
- Refill ALL empty slots each cycle, not just one

**Recovery commands:**
- "check swarm status" → TaskList (shows all task statuses)
- "resume swarm" → TaskList, then spawn workers for any ready tasks, then stop and wait
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
2. Count in_progress tasks to determine active worker count
3. Check beads: `bd ready`
4. Spawn workers for any ready tasks if slots available
5. Stop and wait for next notification

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
