---
description: "Execute prd.json tasks iteratively until all complete"
argument-hint: "[prd-path]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-tasks-loop.sh)", "Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Edit", "Write"]
hide-from-slash-command-tool: "true"
model: opus
---

# Tasks Loop Command

Execute prd.json tasks iteratively until all tasks are complete.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Arguments

- `prd-path` (optional): Path to prd.json (default: `./prd.json`)
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-tasks-loop.sh" $ARGUMENTS
```

### Step 1: Read prd.json

```bash
cat <prd-path>
```

Parse the JSON and identify:
- All userStories
- Dependencies (`dependsOn` array)
- Priorities (lower number = higher priority)
- Completion status (`passes: true/false`)

### Step 2: Create Task Graph

For each userStory, create a built-in task:

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
  "addBlockedBy": ["1"]  // Map US-xxx IDs to task IDs
})
```

Skip stories already completed (`passes: true`) - create them as already completed.

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

The stop hook checks prd.json for remaining tasks:
- If pending tasks exist → loop continues
- If all tasks complete → loop ends

### Step 6: Finalize

After all tasks complete, say **"All tasks complete"**.

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
- Run `/cancel-tasks` to stop early

## Example Usage

```bash
/tasks-loop
/tasks-loop ./prd.json
/tasks-loop ./tasks/my-feature.json
/tasks-loop ./prd.json --max-iterations 5
```
