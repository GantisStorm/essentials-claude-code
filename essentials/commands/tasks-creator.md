---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Write
argument-hint: "<plan-path>"
description: Convert plans to prd.json for RalphTUI or /tasks-loop
model: opus
---

# Tasks Creator

Convert architectural plans into prd.json format compatible with RalphTUI and /tasks-loop.

**Key Principle**: Each task must be implementable with ONLY its description. Never reference external files without copying the content.

## Arguments

Plan path: `.claude/plans/feature-3k7f2-plan.md`

## Instructions

### Step 1: Validate

```bash
ls $ARGUMENTS
```

### Step 2: Read Plan

```bash
cat "$ARGUMENTS"
```

### Step 3: Launch Agent

Launch `tasks-creator-default`:

```
Convert plan to prd.json format.

Plan Path: <path>

## Plan Content

<full plan content>

## Key Principle

Each task must be SELF-CONTAINED:
- Copy requirements verbatim (never "see plan")
- Include code examples
- Include exact file paths
- Include acceptance criteria

Output to .claude/prd/<plan-name>.json
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:tasks-creator-default"
run_in_background: true
```

Wait with TaskOutput (block: true).

### Step 4: Report Result

```
## Tasks Created

File: <path>
Tasks: <count>

## Next Steps

Review tasks:
  cat <path> | jq '.userStories | length'

Execute (choose one):
  /tasks-loop <path>           # Internal loop
  ralph-tui run --prd <path>   # RalphTUI dashboard
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
/tasks-creator .claude/plans/add-auth-3k7f2-plan.md
```
