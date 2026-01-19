---
description: "Execute prd.json tasks iteratively until all complete"
argument-hint: "[prd-path]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-tasks-loop.sh)", "Read", "TodoWrite", "Bash", "Edit", "Write"]
hide-from-slash-command-tool: "true"
model: opus
---

# Tasks Loop Command

Execute prd.json tasks iteratively until all tasks are complete.

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
- Pending tasks (`passes: false`)
- Dependencies (`dependsOn` array)
- Priorities (lower number = higher priority)

### Step 2: Find Next Task

Select the highest priority task that:
- Has `passes: false`
- Has no unresolved dependencies (all `dependsOn` tasks have `passes: true`)

### Step 3: Read Task Details

The task's `description` field is self-contained with:
- Requirements
- Reference implementation code
- Migration patterns (before/after)
- Exit criteria
- Files to modify

### Step 4: Implement the Task

Follow the task description:
1. Read the files mentioned
2. Make the required changes
3. Run any tests/verification in acceptance criteria

### Step 5: Mark Task Complete

Update prd.json to set the task's `passes: true`:

```bash
# Use jq to update the specific task
jq '(.userStories[] | select(.id == "<task-id>")).passes = true' <prd-path> > tmp.json && mv tmp.json <prd-path>
```

Or use the Edit tool to modify the JSON directly.

### Step 6: Loop Until Done

The stop hook checks prd.json for remaining tasks:
- If pending tasks exist → loop continues
- If all tasks complete → loop ends

### Step 7: Finalize

After all tasks complete, say **"All tasks complete"**.

## Context Recovery

If you lose track:

```bash
# Read the prd.json to see all tasks
cat <prd-path>

# Use jq to find pending tasks
jq '[.userStories[] | select(.passes == false)]' <prd-path>

# Find ready tasks (no blockers)
jq '.userStories as $all | [.userStories[] | select(.passes == false) | select((.dependsOn == null) or (.dependsOn | length == 0) or ((.dependsOn // []) | all(. as $dep | ($all | map(select(.id == $dep and .passes == true)) | length > 0))))]' <prd-path>
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
