---
allowed-tools: Bash(jq:*), Bash(bd:*), Bash(ls:*), Bash(cat:*)
argument-hint: "<json [path]> | <beads [epic-id|--label <label>]>"
description: Show task or bead status summary with formatted table
model: sonnet
context: fork
---

# Show Status

Show a formatted status dashboard for tasks (prd.json) or beads.

## Arguments

- `json <path>` — Show prd.json task status
- `json` (no path) — List available prd.json files
- `beads <epic-id>` — Show bead status for an epic
- `beads --label <label>` — Show bead status by label
- `beads` (no args) — List recent epics

## Instructions

### If no argument or invalid argument:

```
Usage: /show-status <json|beads> [path|epic-id]

  json <path>       Show prd.json task status
  beads <epic-id>   Show bead status for an epic
  beads -l <label>  Show bead status by label
```

### If first argument is `json`:

**If path provided**, read the raw JSON:

```bash
cat "<path>"
```

Parse the JSON output and render a dashboard using **box-drawing characters**. Follow this exact format:

```
┌─────────────────────────────────────────────────────────┐
│  Feature Name                                           │
├────────┬──────────────────────────────┬────────┬────────┤
│ ID     │ Title                        │ Status │ Deps   │
├────────┼──────────────────────────────┼────────┼────────┤
│ US-001 │ Create auth types            │   ✓    │        │
│ US-002 │ Implement token exchange     │   ○    │ US-001 │
│ US-003 │ Add login route              │   ○    │ US-002 │
├────────┴──────────────────────────────┴────────┴────────┤
│  Progress: 1/3 done  ████░░░░░░░░ 33%                   │
│  Ready: 1  Blocked: 1  Done: 1                          │
└─────────────────────────────────────────────────────────┘
```

**Formatting rules:**
- `✓` for `passes: true`, `○` for `passes: false`
- Column widths: auto-size to longest value in each column, pad with spaces
- Progress bar: 12 chars wide using `█` (filled) and `░` (empty), rounded to nearest block
- **Ready** = pending tasks whose `dependsOn` are all done (passes: true) or empty
- **Blocked** = pending tasks with unresolved `dependsOn`
- **Done** = tasks with `passes: true`
- All borders use box-drawing: `┌ ┐ └ ┘ ─ │ ┬ ┴ ├ ┤ ┼`

**If no path:**

```bash
ls .claude/prd/*.json 2>/dev/null || echo "No prd.json files found in .claude/prd/"
```

Ask which file to show.

### If first argument is `beads`:

**If epic-id provided:**

```bash
bd list --parent <epic-id> --all --json 2>/dev/null || bd list --parent <epic-id> --all
```

If JSON output available, render the same box-drawing dashboard:

```
┌──────────────────────────────────────────────────────────┐
│  Epic: Implement OAuth System                            │
├────────────┬──────────────────────────────┬───────┬──────┤
│ ID         │ Title                        │ State │ Deps │
├────────────┼──────────────────────────────┼───────┼──────┤
│ bd-abc123  │ Create auth types            │  ✓    │      │
│ bd-def456  │ Implement token exchange     │  ○    │ 1    │
│ bd-ghi789  │ Add login route              │  ○    │ 1    │
├────────────┴──────────────────────────────┴───────┴──────┤
│  Progress: 1/3 done  ████░░░░░░░░ 33%                    │
│  Open: 2  Closed: 1                                      │
└──────────────────────────────────────────────────────────┘
```

If JSON not available, render from the text output using the same box style.

- `✓` for closed/done, `○` for open
- Deps column: show count of dependencies

**If `--label` or `-l` provided:**

```bash
bd list -l <label> --all --json 2>/dev/null || bd list -l <label> --all
```

Same dashboard format, title uses label name.

**If no additional args:**

```bash
bd list --type epic -n 10
```

Ask which epic to show.
