---
allowed-tools: Task, TaskOutput, Bash, Read, Glob
argument-hint: "<plan-path>"
description: Convert plans to self-contained Beads (project)
---

# Beads Creator

Convert architectural plans into self-contained Beads issues.

**Key Principle**: Each bead must be implementable with ONLY its description. Never reference external files without copying the content.

## Arguments

Plan path: `.claude/plans/feature-3k7f2-plan.md`

## Instructions

### Step 1: Validate

```bash
bd version
bd ready &>/dev/null && echo "OK" || echo "Run: bd init"
ls $ARGUMENTS
```

### Initialization Options

| Mode | Command | When to Use |
|------|---------|-------------|
| Stealth (default) | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected Branch | `bd init --branch beads-sync` | When main is protected |

**Stealth Mode** (`--stealth`): Keeps `.beads/` local only - no git sync, no team collaboration, no backup. Use for personal or brownfield projects.

### Step 2: Read Plan

```bash
cat "$ARGUMENTS"
```

### Step 3: Launch Agent

Launch `beads-creator-default`:

```
Convert plan to self-contained beads.

Plan Path: <path>

## Plan Content

<full plan content>

## Key Principle

Each bead must be SELF-CONTAINED:
- Copy requirements verbatim (never "see plan")
- Include code examples
- Include exact file paths
- Include acceptance criteria

Create epic first, then child tasks with --parent.
```

Use `subagent_type: "beads-creator-default"` and `run_in_background: true`.

### Step 4: Report Result

```
## Beads Created

Epic: <id>
Tasks: <count>

Next Steps:
1. Review: bd list -l "plan:<name>"
2. Start: /beads-loop --label plan:<name>
```

## Self-Contained Bead Example

**BAD:**
```
bd create "Update auth" -t task
```

**GOOD:**
```
bd create "Add JWT validation" -t task -p 2 \
  --parent <epic-id> \
  -l "plan:add-auth" \
  -d "## Context Chain

**Plan Reference**: .claude/plans/auth-3k7f2-plan.md
**Task**: 1.2 from plan

## Requirements
<copied from plan - FULL text>

## Reference Implementation
<FULL code from plan>

## Exit Criteria
- [ ] \`npm test -- auth\` passes
- [ ] TypeScript compiles

## Files
- src/auth.ts"
```

**Litmus test:** Could someone implement this with ONLY the bead description?

## Error Handling

| Scenario | Action |
|----------|--------|
| bd not installed | "Install bd: https://github.com/anthropics/beads" |
| bd not initialized | "Run: bd init" |
| Path not found | Report error |

## Example Usage

```bash
/beads-creator .claude/plans/add-auth-3k7f2-plan.md
```
