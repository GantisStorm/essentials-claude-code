---
allowed-tools: Task, TaskOutput, Bash, Read, Glob
argument-hint: <spec-path>
description: Convert OpenSpec or SpecKit specs to self-contained Beads (project)
---

Convert an OpenSpec or SpecKit specification into self-contained Beads issues.

## Arguments

Spec path:
- OpenSpec: `openspec/changes/<name>/`
- SpecKit: `.specify/`

## Instructions

### Step 1: Validate

```bash
# Check bd installed
bd version

# Check initialized
bd ready &>/dev/null && echo "OK" || echo "Run: bd init"

# Check path exists
ls $ARGUMENTS
```

### Step 2: Detect Spec Type

```bash
if [ -f "$ARGUMENTS/proposal.md" ]; then
  echo "TYPE=openspec"
elif [ -f "$ARGUMENTS/spec.md" ]; then
  echo "TYPE=speckit"
else
  echo "ERROR: Not a valid spec directory"
  exit 1
fi
```

### Step 3: Read Spec Files

**For OpenSpec:**
```bash
cat $ARGUMENTS/proposal.md
cat $ARGUMENTS/tasks.md
cat $ARGUMENTS/design.md 2>/dev/null || true
find $ARGUMENTS/specs -name "*.md" -exec cat {} \; 2>/dev/null || true
```

**For SpecKit:**
```bash
cat .specify/spec.md
cat .specify/plan.md 2>/dev/null || true
```

### Step 4: Launch Agent

Launch `beads-creator-default`:

```
Convert spec to self-contained beads.

Spec Type: <openspec|speckit>
Spec Path: <path>
Change Name: <name>

## Spec Content

<content of all spec files>

## Key Principle

Each bead must be SELF-CONTAINED:
- Copy requirements verbatim (never "see spec")
- Include code examples
- Include exact file paths
- Include acceptance criteria

Create epic first, then child tasks with --parent.
```

Use `subagent_type: "beads-creator-default"` and `run_in_background: true`.

### Step 5: Report Result

```
===============================================================
BEADS CREATED
===============================================================

Epic: <id>
Tasks: <count>
Ready: <count>

Next Steps:
1. Review: bd list -l "openspec:<name>"
2. Start: /beads-loop --label openspec:<name>

===============================================================
```

## Self-Contained Bead Rule

Each bead must be implementable with ONLY its description.

**BAD:**
```
bd create "Update auth" -t task
```

**GOOD:**
```
bd create "Add JWT validation" -t task -p 2 \
  --parent <epic-id> \
  -l "openspec:add-auth" \
  -d "## Requirements
<copied from spec>

## Implementation
<code example>

## Acceptance Criteria
- [ ] Test passes

## Files
- src/auth.ts"
```

## Workflow

```
/plan-creator <task>
    │
    ▼
/proposal-creator <plan>
    │
    ▼
/beads-creator <spec>     ← THIS COMMAND
    │
    ▼
/beads-loop
```

## Error Handling

| Scenario | Action |
|----------|--------|
| bd not installed | "Install bd: https://github.com/steveyegge/beads" |
| bd not initialized | "Run: bd init" |
| Path not found | Report error |
