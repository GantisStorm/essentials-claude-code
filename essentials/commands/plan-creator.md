---
allowed-tools: Task, TaskOutput
argument-hint: <feature-description>
description: Create architectural plans for new features in existing codebases (brownfield development) - detailed enough to feed directly into /implement-loop, /tasks-converter, or /beads-converter. For bugs use /bug-plan-creator, for code quality use /code-quality-plan-creator.
context: fork
model: opus
---

# Architectural Plan Creator

Create comprehensive architectural plans for **new features in existing codebases** (brownfield development). Plans specify HOW to implement, not just WHAT.

**Use the right tool:**
- **New features/enhancements** → `/plan-creator` (this command)
- **Bug fixes** → `/bug-plan-creator`
- **Code quality improvements** → `/code-quality-plan-creator`

## Arguments

Takes a feature description:
- `"Add OAuth2 authentication with Google login"`
- `"Add user profile page with avatar upload"`
- `"Refactor auth module to use dependency injection"`

**Tip:** For complex features, use `/prompt-creator "feature: ..."` first to create a detailed feature request.

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS` as the task description. Grammar and spell check before passing to agent.

### Step 2: Launch Agent

Launch background agent with just the task:

```
Create architectural plan: <corrected task description>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:plan-creator-default"
run_in_background: true
prompt: "Create architectural plan: <corrected task description>"
```

Wait with TaskOutput (block: true).

### Step 3: Report Result

```
## Architectural Plan Created

**Plan**: .claude/plans/{task-slug}-{hash5}-plan.md

Next Steps:
1. Review the plan
2. `/implement-loop <plan-path>` - Direct implementation (80% of tasks)
3. `/tasks-converter <plan-path>` → `/tasks-loop` or RalphTUI - prd.json format
4. `/beads-converter <plan-path>` → `/beads-loop` or RalphTUI - For large plans
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Agent fails | Report error, stop |
| Plan not ready | Report issues, suggest fixes |

## Example Usage

```bash
/plan-creator Add OAuth2 authentication with Google login
/plan-creator Add user profile page with avatar upload
/plan-creator Refactor the auth module to use dependency injection
/plan-creator Add real-time notifications with WebSockets
```
