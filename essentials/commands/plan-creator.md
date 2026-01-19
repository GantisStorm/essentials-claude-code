---
allowed-tools: Task, TaskOutput
argument-hint: <task-description>
description: Create a comprehensive architectural plan for any task - detailed enough to feed directly into /implement-loop, /tasks-creator, or /beads-creator
context: fork
model: opus
---

# Architectural Plan Creator

Create a comprehensive architectural plan for any task. Plans specify HOW to implement, not just WHAT.

## Arguments

Takes any task description:
- `"Add OAuth2 authentication"`
- `"Fix login timeout issue"`
- `"Refactor auth module to use dependency injection"`

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS` as the task description. Grammar and spell check before passing to agent.

### Step 2: Launch Agent

Launch `plan-creator-default` in background:

```
Create a comprehensive architectural plan with maximum depth and verbosity.

Task: <corrected task description>

Requirements:
- Produce a VERBOSE architectural plan suitable for /implement-loop, /tasks-creator, or /beads-creator
- Include complete implementation specifications (not just requirements)
- Specify exact code structures, file organizations, and component relationships
- Provide ordered implementation steps with clear dependencies
- Include exit criteria with verification commands

Write the plan to `.claude/plans/` following standard format.
```

Use `subagent_type: "plan-creator-default"` and `run_in_background: true`.

Wait with TaskOutput (block: true).

### Step 3: Report Result

```
## Architectural Plan Created

**Plan**: .claude/plans/{task-slug}-{hash5}-plan.md

Next Steps:
1. Review the plan
2. `/implement-loop <plan-path>` - Direct implementation (80% of tasks)
3. `/tasks-creator <plan-path>` → `/tasks-loop` or RalphTUI - prd.json format
4. `/beads-creator <plan-path>` → `/beads-loop` or RalphTUI - For large plans
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Agent fails | Report error, stop |
| Plan not ready | Report issues, suggest fixes |

## Example Usage

```bash
/plan-creator Add OAuth2 authentication with Google login
/plan-creator Fix the login timeout issue when session expires
/plan-creator Refactor the auth module to use dependency injection
```
