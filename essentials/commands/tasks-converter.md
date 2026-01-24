---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Write
argument-hint: "<plan-path>"
description: Convert plans to prd.json for RalphTUI or /tasks-loop
model: opus
context: fork
---

# Tasks Creator

Convert architectural plans into prd.json format compatible with RalphTUI and /tasks-loop.

**Key Principle**: Each task must be implementable with ONLY its description. Never reference external files without copying the content.

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

Wait with TaskOutput (block: true).

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

## Self-Contained Task Example

**BAD:**
```json
{
  "description": "Update auth. See plan for details."
}
```

**GOOD:**
```json
{
  "id": "US-001",
  "title": "Add JWT validation",
  "description": "## Requirements\n<copied from plan - FULL text>\n\n## Reference Implementation\n```typescript\n<FULL code from plan>\n```\n\n## Exit Criteria\n- `npm test -- auth` passes\n- TypeScript compiles",
  "acceptanceCriteria": [
    "npm test -- auth passes",
    "TypeScript compiles"
  ],
  "priority": 1,
  "passes": false,
  "dependsOn": []
}
```

**Litmus test:** Could someone implement this with ONLY the task description?

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
