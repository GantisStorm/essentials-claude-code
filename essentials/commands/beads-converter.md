---
allowed-tools: Task, Bash, Read, Glob
argument-hint: "<plan-path>"
description: Convert plans to Beads - works with /beads-loop, /beads-swarm, or RalphTUI
model: opus
context: fork
---

# Beads Creator

Convert architectural plans into self-contained Beads issues. Works with `/beads-loop`, `/beads-swarm`, or RalphTUI - they're interchangeable.

## Arguments

Plan path: `.claude/plans/feature-3k7f2-plan.md`

## Instructions

### Step 1: Validate bd

```bash
bd version &>/dev/null || echo "ERROR: Install bd first"
```

If bd not installed, report error and stop.

### Step 2: Launch Agent

Launch background agent immediately with just the path:

```
Convert plan to beads: <plan-path>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:beads-converter-default"
run_in_background: true
prompt: "Convert plan to beads: <plan-path>"
```

Output a status message like "Converting to beads..." and **end your turn**. The system wakes you when the agent finishes.

### Step 3: Report Result

```
## Beads Created

Epic: <epic-id>
Tasks: <count>

## Next Steps

Review beads:
  bd list -l ralph
  bd show <epic-id>

Execute (choose one):
  /beads-loop                                    # Sequential (closes beads)
  /beads-swarm --epic <epic-id>                  # Parallel (closes beads)
  ralph-tui run --tracker beads --epic <epic-id> # Classic Ralph TUI executor
```

## Error Handling

| Scenario | Action |
|----------|--------|
| bd not installed | "Install bd: https://github.com/anthropics/beads" |
| bd not initialized | "Run: bd init" |
| Path not found | Report error |

## Example Usage

```bash
/beads-converter .claude/plans/add-auth-3k7f2-plan.md
```
