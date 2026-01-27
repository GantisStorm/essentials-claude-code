---
allowed-tools: Task
argument-hint: <feature-description>
description: Create architectural plans for new features - works with any executor (loop or swarm). For bugs use /bug-plan-creator, for code quality use /code-quality-plan-creator.
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

Launch agent with just the task:

```
Create architectural plan: <corrected task description>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:plan-creator-default"
prompt: "Create architectural plan: <corrected task description>"
```

### Step 3: Report Result

```
## Architectural Plan Created

**Plan**: .claude/plans/{task-slug}-{hash5}-plan.md

Next Steps:
1. Review the plan
2. Execute directly (loop or swarm are interchangeable):
   - `/plan-loop <plan-path>` or `/plan-swarm <plan-path>`
3. Or convert to prd.json/beads first:
   - `/tasks-converter <plan-path>` → `/tasks-loop` or `/tasks-swarm`
   - `/beads-converter <plan-path>` → `/beads-loop` or `/beads-swarm`
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
