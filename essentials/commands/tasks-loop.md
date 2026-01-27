---
description: "Execute prd.json tasks iteratively until all complete"
argument-hint: "[prd-path]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit", "Write", "Glob", "Grep"]
hide-from-slash-command-tool: "true"
model: opus
---

# Tasks Loop Command

Execute prd.json tasks iteratively until all tasks are complete.

**Note:** Loop and swarm are interchangeable - swarm is just faster when tasks can run in parallel. Both enforce exit criteria and sync prd.json.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `prd-path` (optional): Path to prd.json (default: `./prd.json`)
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Step 1: Read prd.json (Only)

**DO NOT read other files, grep, or explore the codebase** - just parse the prd.json. **Never spawn sub-agents or delegate work — do ALL implementation directly yourself.**

```bash
cat <prd-path>
```

Parse the JSON and identify:
- All userStories
- Dependencies (`dependsOn` array)
- Priorities (lower number = higher priority)
- Completion status (`passes: true/false`)

### Step 2: Create Task Graph

Create a task for each userStory and build an **ID map** as you go:

```json
// Create tasks in order — each returns a task ID
TaskCreate({ "subject": "US-001: Setup database schema", ... })  // → task "1"
TaskCreate({ "subject": "US-002: Implement auth service", ... }) // → task "2"
TaskCreate({ "subject": "US-003: Add login route", ... })        // → task "3"

// ID map: { "US-001": "1", "US-002": "2", "US-003": "3" }
```

Full TaskCreate per story:

```json
TaskCreate({
  "subject": "US-001: Setup database schema",
  "description": "<full description from userStory - self-contained>",
  "activeForm": "Setting up database schema",
  "metadata": { "id": "US-001", "prdPath": "<prd-path>" }
})
```

**Translate `dependsOn` to `addBlockedBy`** using the ID map:

```json
// prd.json says: US-003 has dependsOn: ["US-001", "US-002"]
// ID map: US-001→"1", US-002→"2", US-003→"3"
TaskUpdate({
  "taskId": "3",
  "addBlockedBy": ["1", "2"]
})
```

A task with non-empty `blockedBy` shows as **blocked** in `ctrl+t`. When a blocking task is marked `completed`, it's automatically removed from the blocked list. A task becomes **ready** (executable) when its blockedBy list is empty.

Skip stories already completed (`passes: true`) — create them as already completed.

### Step 3: Execute Tasks Sequentially

For each task (in dependency order):

1. **Claim**: `TaskUpdate({ taskId: "N", status: "in_progress" })`
2. **Read**: Task description contains full implementation details
3. **Implement**: Make changes as described
4. **Verify**: Run acceptance criteria
5. **Complete**: `TaskUpdate({ taskId: "N", status: "completed" })`
6. **Update prd.json**: Set `passes: true` for the userStory
7. **Next**: Find next unblocked task via TaskList

### Step 4: Update prd.json on Completion

When a task completes, also update prd.json:

```bash
jq '(.userStories[] | select(.id == "<story-id>")).passes = true' <prd-path> > tmp.json && mv tmp.json <prd-path>
```

This keeps prd.json in sync for RalphTUI compatibility.

### Step 5: Loop Until Done

Use TaskList to check progress:
- If pending tasks exist → continue with next unblocked task
- If all tasks complete → say "All tasks complete" and stop

**Say "All tasks complete" when done.**

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (2 done, 1 in progress, 3 open)
✓ #1 US-001: Setup database schema
■ #2 US-002: Implement auth service
□ #3 US-003: Add login route > blocked by #2
□ #4 US-004: Add protected routes > blocked by #2
```

## Context Recovery

If you lose track:

```bash
# Check built-in tasks
TaskList

# Or check prd.json directly
cat <prd-path>
jq '[.userStories[] | select(.passes == false)]' <prd-path>
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No pending tasks | All complete or check prd.json |
| Task blocked | Complete blocking tasks first |
| Invalid JSON | Check prd.json syntax |
| Test failure | Fix and retry, don't mark complete |

## Stopping

- Say "All tasks complete" when done
- Run `/cancel-loop` to stop early

## Example Usage

```bash
/tasks-loop
/tasks-loop ./prd.json
/tasks-loop ./tasks/my-feature.json
/tasks-loop ./prd.json --max-iterations 5
```
