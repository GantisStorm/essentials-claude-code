---
allowed-tools: Task, AskUserQuestion
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

Takes a feature description and optional reference material:
- `"Add OAuth2 authentication with Google login"`
- `"Add user profile page with avatar upload"`
- `"Refactor auth module to use dependency injection"`
- `"Add caching layer" .claude/maps/code-map-src-a3f9e.json` — pass a code map, design doc, or any file as additional context

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS` as the task description. Grammar and spell check before passing to agent.

### Step 2: Ask Clarifying Questions

Use AskUserQuestion to gather missing context. Ask only what's unclear — skip questions the user already answered in their input.

**Questions to consider** (ask 1-4 based on what's missing):

- **Scope**: Which parts of the codebase should this touch? Any areas off-limits?
- **Constraints**: Any specific tech, patterns, or libraries to use or avoid?
- **Behavior**: Key edge cases, error handling, or user-facing behaviors to get right?
- **Exit criteria**: How will we verify it works? Specific test commands, endpoints to hit, or behaviors to check?

**If the input is already detailed enough** (clear scope, obvious constraints, well-defined behavior), skip this step entirely and go straight to Step 3.

### Step 3: Launch Agent

Assemble the enriched prompt from the original description + clarifying answers. Launch background agent:

```
Create architectural plan:

Task: <corrected task description>

<clarifying context from user answers, if any>
<reference material contents, if any>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:plan-creator-default"
run_in_background: true
prompt: "<assembled prompt with all context>"
```

Output a status message like "Creating plan..." and **end your turn**. The system wakes you when the agent finishes.

### Step 4: Report Result

```
## Architectural Plan Created

**Plan**: .claude/plans/{task-slug}-{hash5}-plan.md

Next Steps:
1. Review the plan
2. Execute directly:
   - `/plan-loop <plan-path>` (sequential)
   - `/plan-swarm <plan-path>` (parallel subagents)
   - `/plan-team <plan-path>` (Agent Teams with contracts)
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
