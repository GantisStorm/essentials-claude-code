---
description: "Implement a plan with iterative loop until completion"
argument-hint: "<plan_path> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh)", "Read", "TodoWrite", "Bash", "Edit"]
hide-from-slash-command-tool: "true"
---

# Implement Loop Command

Execute a plan file iteratively until all todos are complete AND exit criteria pass.

**IMPORTANT**: The plan file is your source of truth. Exit Criteria MUST pass before the loop will end.

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

- `<plan_path>` (required): Path to the plan file
- `--max-iterations N` (optional): Maximum iterations before stopping (default: unlimited)

## Instructions

### Step 1: Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh" $ARGUMENTS
```

### Step 2: Read the Plan

Read the plan file and extract:
1. **Files to Edit** - existing files that need modification
2. **Files to Create** - new files to create
3. **Implementation Plan** - per-file implementation instructions
4. **Requirements** - acceptance criteria
5. **Exit Criteria** - verification script and success conditions

### Step 3: Create Todos

Use **TodoWrite** to create a todo for each:
- File that needs to be edited or created
- Major requirement to satisfy
- Run exit criteria verification

### Step 4: Implement Each Todo

For each todo:
1. Mark it as **in_progress** using TodoWrite
2. Read the relevant section from the plan
3. Implement the changes following the plan exactly
4. Verify the implementation (run tests, type checks)
5. Mark as **completed** ONLY when fully done

### Step 5: Run Exit Criteria

Before declaring completion:
1. Find the `## Exit Criteria` section in the plan
2. Run the verification command
3. If it passes, say "Exit criteria passed - implementation complete"
4. If it fails, fix the issues and retry

### Step 6: Loop Until Done

The stop hook checks:
- If verification PASSES → loop ends
- If verification FAILS → loop continues with error context
- If todos remain incomplete → loop continues

Say **"Exit criteria passed"** when complete.

## Context Recovery

If context compacts:
1. Read the plan file again
2. Check the current todo list status
3. Continue with the next pending todo

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Exit criteria fail | Fix issues and retry |
| Context compacted | Re-read plan, check todos, continue |

## Example Usage

```bash
/implement-loop .claude/plans/add-user-auth.md
/implement-loop .claude/plans/fix-memory-leak.md --max-iterations 10
```
