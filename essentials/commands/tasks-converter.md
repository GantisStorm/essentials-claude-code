---
allowed-tools: Task, Bash, Read, Glob, Write
argument-hint: "<plan-path>"
description: Convert plans to prd.json - works with /tasks-loop, /tasks-swarm, or RalphTUI
model: opus
context: fork
---

# Tasks Creator

Convert architectural plans into prd.json format. Works with `/tasks-loop`, `/tasks-swarm`, or RalphTUI - they're interchangeable.

## Arguments

Plan path: `.claude/plans/feature-3k7f2-plan.md`

## Instructions

### Step 1: Launch Agent

Launch background agent immediately with just the path:

```
Convert plan to prd.json: <plan-path>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:tasks-converter-default"
run_in_background: true
prompt: "Convert plan to prd.json: <plan-path>"
```

Output a status message like "Converting to prd.json..." and **end your turn**. The system wakes you when the agent finishes.

### Step 2: Report Result

```
## Tasks Created

File: <path>
Tasks: <count>

## Next Steps

Review tasks:
  cat <path> | jq '.userStories | length'

Execute (choose one):
  /tasks-loop <path>           # Sequential (syncs prd.json)
  /tasks-swarm <path>          # Parallel (syncs prd.json)
  ralph-tui run --prd <path>   # Classic Ralph TUI executor
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Path not found | Report error |
| Invalid plan format | Report what's missing |
| .claude/prd/ missing | Create directory |

## Example Usage

```bash
/tasks-converter .claude/plans/add-auth-3k7f2-plan.md
```
