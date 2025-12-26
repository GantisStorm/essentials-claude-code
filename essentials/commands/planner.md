---
allowed-tools: Task, TaskOutput
argument-hint: <task description>
description: Create a comprehensive implementation plan for a task, with grammar and spelling check on the task description (project)
---

Create a comprehensive implementation plan for the specified task, then guide the user to choose their implementation approach.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the plan FILE directly, not in chat.

## Instructions

### Step 1: Grammar Check

Before launching the `planner-default` agent, first grammar and spell check the provided task description (`$ARGUMENTS`). Ensure the revised task description is clear, correct, and unambiguous.

### Step 2: Launch Planner in Background

Launch the `planner-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Create a comprehensive implementation plan for the following task:

<corrected and grammar-checked task description>

Write the plan to `.claude/plans/` following your standard format.

IMPORTANT: At the end of your plan, include implementation options guidance for the user to choose between /editor (batch mode) and /issue-builder (iterative mode).
```

Use `subagent_type: "planner-default"` when invoking the Task tool.

### Step 3: Wait for Plan Completion

Use `TaskOutput` with `block: true` to wait for the planner agent to complete. The planner will:
1. Investigate the codebase thoroughly
2. Research external documentation if needed
3. Create a detailed implementation plan in `.claude/plans/`
4. Return the plan file path and implementation guidance

### Step 4: Present Implementation Options

From the planner's output, extract the plan file path and present the user with their options:

```
## Planning Complete

**Plan File**: .claude/plans/{task-slug}-{hash5}-plan.md
**Files to Modify**: [count]
**Quality Score**: [XX]/50

### Review & Optimize (Optional)

**Plan Builder (`/plan-builder`)** - Refine the plan before implementation
- Add missing details, reorganize sections, update requirements
- Tracks changes with git-style revision history
- Command: `/plan-builder .claude/plans/{plan-file} "<your changes>"`
- Use when: Plan needs refinement or additional details

### Choose Your Implementation Approach

**Option 1: Direct File Editing (`/editor`)** - Batch mode, all files in parallel
- Best for: Simple plans (<5 files), clear dependencies, single session
- Command: `/editor .claude/plans/{plan-file} <file1> <file2> ...`

**Option 2: Issue-Based Implementation (`/issue-builder`)** - Iterative mode, one issue at a time
- Best for: Complex plans (>5 files), unclear dependencies, resumable work
- Command: `/issue-builder .claude/plans/{plan-file}`

**Recommended**: [Option 1|Option 2] - [brief reason from planner]

### Next Steps

1. Review the plan: Open `.claude/plans/{plan-file}`
2. (Optional) Optimize: `/plan-builder` if plan needs refinement
3. Choose implementation approach: `/editor` or `/issue-builder`
```

## Workflow Diagram

```
/planner <task>
    │
    ▼
┌─────────────────────┐
│ Grammar check task  │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Launch planner      │◄── run_in_background: true
│ (planner-default)   │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for plan
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Present options:    │
│ /editor or          │
│ /issue-builder      │
└─────────────────────┘
    │
    ▼
[User chooses implementation approach]
```

## Error Handling

- **Planner fails**: Report error and stop
- **Plan not ready**: Report issues found, suggest fixes

## Example Usage

```bash
# Create a plan for a task
/planner Add OAuth2 authentication with Google login

# After plan is created, user chooses:
/editor .claude/plans/oauth2-authentication-a3f9e-plan.md src/auth/handler src/auth/middleware
# OR
/issue-builder .claude/plans/oauth2-authentication-a3f9e-plan.md
```
