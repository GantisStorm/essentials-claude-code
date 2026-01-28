---
name: beads-schema
description: Beads (bd CLI) reference — issue types, statuses, priorities, dependencies, and common commands
allowed-tools: Bash, Read, Write, Edit
argument-hint: "[validate]"
---

Beads CLI (`bd`) reference from [Beads](https://github.com/steveyegge/beads). Use this when creating, editing, or managing beads issues.

## When to Use

Invoke `/beads-schema` before working with `bd` commands. Invoke `/beads-schema validate` to check that `bd` is initialized and working.

## Core Concepts

Beads is a git-backed issue tracker. Issues are stored as JSONL in `.beads/` and sync via git. The CLI is `bd`.

### Conversion from Plans

Beads are typically created by `/beads-converter` from architectural plans (`.claude/plans/*-plan.md`). The pipeline:

```
/plan-creator (or /bug-plan-creator, /code-quality-plan-creator)
    ↓ writes
.claude/plans/{slug}-{hash5}-plan.md
    ↓ consumed by
/beads-converter <plan-path>
    ↓ runs
bd create (epic) + bd create (child tasks) + bd dep add
    ↓ stored in
.beads/beads.jsonl
    ↓ executed by
/beads-loop or /beads-swarm or ralph-tui
```

**How plan sections map to bead fields:**

| Plan Section | Bead Field | CLI Flag |
|-------------|------------|----------|
| `## Summary` | Epic title + description | `bd create "Title" -t epic -d "..."` |
| `## Files` | One bead per file (typically) | `bd create "Title" --parent <epic>` |
| `### Requirements` | Bead description (exit checklist) | `-d "## Requirements\n..."` |
| `### Reference Implementation` | Bead description (full code) | `-d "## Reference Implementation\n..."` |
| `### Migration Pattern` | Bead description (before/after) | `-d "## Migration Pattern\n..."` |
| `## Dependency Graph` | Bead dependencies | `bd dep add <child> <parent>` |
| `## Exit Criteria` | Bead description (exit criteria) | `-d "## Exit Criteria\n..."` |

Each bead's description must be **100% self-contained** — the executor agent receives only the bead description, never the source plan. All code, requirements, and verification commands are copied verbatim from the plan into the bead.

### Issue Types (core)

| Type | Description |
|------|-------------|
| `task` | General work item (default) |
| `bug` | Bug report or defect |
| `feature` | New feature or enhancement (`enhancement` is alias) |
| `chore` | Maintenance or housekeeping |
| `epic` | Large body of work spanning multiple issues |

### Statuses

| Status | Description |
|--------|-------------|
| `open` | Ready to work (default) |
| `in_progress` | Currently being worked on |
| `blocked` | Waiting on dependency |
| `deferred` | Deliberately put on ice |
| `closed` | Finished |

### Priority (0-4, lower = higher)

| Priority | Meaning |
|----------|---------|
| P0 | Critical |
| P1 | High |
| P2 | Medium (default) |
| P3 | Low |
| P4 | Backlog |

Supports both `--priority 1` and `--priority P1` formats.

### Hierarchical IDs

Beads supports parent-child hierarchies via dotted IDs:

- `bd-a3f8` (Epic)
- `bd-a3f8.1` (Task under epic)
- `bd-a3f8.1.1` (Sub-task)

Use `--parent <epic-id>` when creating to auto-generate child IDs.

## Essential Commands

### Create

```bash
# Create a task (default type)
bd create "Fix login bug" -p 1

# Create with type and parent
bd create "Add toggle switch" --type task --parent bd-a3f8

# Create epic
bd create "User Authentication" --type epic

# Full flags
bd create "Title" \
  --type task \
  --priority 1 \
  --parent bd-a3f8 \
  --description "Detailed description" \
  --acceptance "Criteria for completion" \
  --labels frontend,auth \
  --deps bd-001,bd-002
```

**Create flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--type` | `-t` | Issue type (default: task) |
| `--priority` | `-p` | Priority 0-4 or P0-P4 (default: 2) |
| `--parent` | | Parent issue ID (creates child) |
| `--description` | `-d` | Issue description |
| `--acceptance` | | Acceptance criteria |
| `--design` | | Design notes |
| `--notes` | | Additional notes |
| `--labels` | `-l` | Comma-separated labels |
| `--deps` | | Dependencies (format: `id` or `type:id`) |
| `--assignee` | `-a` | Assignee |
| `--id` | | Explicit issue ID |
| `--due` | | Due date (+6h, tomorrow, 2025-01-15) |
| `--defer` | | Hide from `bd ready` until date |
| `--silent` | | Output only the issue ID |
| `--json` | | JSON output |

### Update

```bash
# Update status
bd update bd-a3f8 --status in_progress

# Update multiple fields
bd update bd-a3f8 --title "New title" --priority 1 --description "Updated desc"

# Append to notes (vs replace)
bd update bd-a3f8 --append-notes "Additional context"
```

**Do NOT use `bd edit`** — it opens an interactive editor. Use `bd update` with flags instead.

### Close

```bash
# Close one or more issues
bd close bd-a3f8 --reason "Completed"
bd close bd-001 bd-002 bd-003 --reason "All done"
```

### Show

```bash
bd show bd-a3f8          # Human-readable
bd show bd-a3f8 --json   # JSON output
```

### List

```bash
bd list                          # All open issues
bd list --type epic              # Only epics
bd list --parent bd-a3f8         # Children of epic
bd list --status open            # Filter by status
bd list --label frontend         # Filter by label
bd list --json                   # JSON output
```

### Ready

```bash
bd ready         # Tasks with no open blockers
bd ready --json  # JSON output
```

Shows tasks that are `open`, have all dependencies resolved (`closed`/`cancelled`), and are not deferred.

### Dependencies

```bash
# Add dependency: child depends on parent (child blocked until parent closes)
bd dep add bd-child bd-parent

# Dependency types
bd dep add bd-child bd-parent              # Default: "blocks"
bd dep add bd-child bd-parent --type related  # Non-blocking relation

# Remove dependency
bd dep remove bd-child bd-parent
```

**Dependency types that block readiness:**

| Type | Effect |
|------|--------|
| `blocks` | Child blocked until parent closes (default) |
| `parent-child` | Auto-created via `--parent` flag |

**Non-blocking dependency types:** `related`, `discovered-from`, `replies-to`, `relates-to`, `duplicates`, `supersedes`

### Labels

```bash
bd label add bd-a3f8 frontend
bd label remove bd-a3f8 frontend
```

### Sync

```bash
bd sync   # Export to JSONL, commit, pull, import, push
```

Always run `bd sync` after making changes to persist them.

## Task Selection Order

`bd ready` selects tasks by:
1. Filter to `status: open`
2. Filter to tasks with all blocking dependencies resolved (`closed`/`cancelled`)
3. Filter out deferred tasks (past `defer_until`)
4. Sort by priority (P0 first)
5. Return matches

## Issue Fields Reference

### Core fields (used by essentials commands)

| Field | JSON key | Type | Required |
|-------|----------|------|----------|
| ID | `id` | string | auto-generated |
| Title | `title` | string | yes (max 500 chars) |
| Description | `description` | string | no |
| Status | `status` | string | yes (default: open) |
| Priority | `priority` | int 0-4 | yes (default: 2) |
| Type | `issue_type` | string | yes (default: task) |
| Acceptance Criteria | `acceptance_criteria` | string | no |
| Design | `design` | string | no |
| Notes | `notes` | string | no |
| Assignee | `assignee` | string | no |
| Labels | `labels` | string[] | no |
| Dependencies | `dependencies` | object[] | no |

### Timestamp fields (auto-managed)

| Field | JSON key |
|-------|----------|
| Created | `created_at` |
| Updated | `updated_at` |
| Closed | `closed_at` |
| Created by | `created_by` |
| Close reason | `close_reason` |

## Common Workflows

### Create epic with tasks

```bash
# 1. Create epic
bd create "User Authentication" --type epic --json
# Returns: bd-a3f8

# 2. Add tasks as children
bd create "Login form" --type task --parent bd-a3f8 -p 1
bd create "Auth API" --type task --parent bd-a3f8 -p 1
bd create "Integration tests" --type task --parent bd-a3f8 -p 2

# 3. Add dependency (tests depend on form + API)
bd dep add bd-a3f8.3 bd-a3f8.1
bd dep add bd-a3f8.3 bd-a3f8.2

# 4. Check ready tasks
bd ready --json
```

### Work on a task

```bash
bd update bd-a3f8.1 --status in_progress
# ... do work ...
bd close bd-a3f8.1 --reason "Login form implemented with validation"
bd sync
```

## Instructions

### If `validate` argument provided:

Check beads is set up and working:

```bash
# Check bd is installed
bd version

# Check beads is initialized
ls .beads/

# List all issues
bd list --json

# Check for ready tasks
bd ready --json
```

Report the beads version, issue count, and any issues.

### If no argument:

Output the quick reference:

```
Beads CLI (bd) Quick Reference

Types: task (default), bug, feature, chore, epic
Statuses: open, in_progress, blocked, deferred, closed
Priority: P0 (critical) → P4 (backlog), default P2

Create:   bd create "Title" --type task -p 1 --parent <epic-id>
Update:   bd update <id> --status in_progress
Close:    bd close <id> --reason "Done"
Ready:    bd ready --json
List:     bd list --parent <epic-id> --json
Deps:     bd dep add <child> <parent>
Sync:     bd sync

Do NOT use "bd edit" (interactive). Use "bd update" with flags.
```
