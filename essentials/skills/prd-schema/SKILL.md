---
name: prd-schema
description: prd.json schema reference for Ralph TUI — validates structure, prevents unsupported fields
allowed-tools: Bash, Read, Write, Edit
argument-hint: "[validate <path>]"
---

prd.json schema reference from [Ralph TUI](https://github.com/subsy/ralph-tui). Use this when creating, editing, or reviewing `.claude/prd/*.json` files.

## When to Use

Invoke `/prd-schema` before editing any prd.json file. Invoke `/prd-schema validate <path>` to check an existing file.

## Conversion from Plans

prd.json files are typically created by `/tasks-converter` from architectural plans (`.claude/plans/*-plan.md`). The pipeline:

```
/plan-creator (or /bug-plan-creator, /code-quality-plan-creator)
    ↓ writes
.claude/plans/{slug}-{hash5}-plan.md
    ↓ consumed by
/tasks-converter <plan-path>
    ↓ writes
.claude/prd/<slug>.json
    ↓ executed by
/tasks-loop or /tasks-swarm or ralph-tui
```

**How plan sections map to prd.json fields:**

| Plan Section | prd.json Field |
|-------------|----------------|
| `## Summary` | `name`, `description` |
| `## Files` | One user story per file (typically) |
| `### Requirements` | `acceptanceCriteria[]` |
| `### Reference Implementation` | `description` (full code copied verbatim) |
| `### Migration Pattern` | `description` (before/after code copied verbatim) |
| `## Dependency Graph` | `dependsOn[]` (file deps translated to story IDs) |
| `## Exit Criteria` | `acceptanceCriteria[]` |
| Plan path | `metadata.planReference` |

Each story's `description` must be **100% self-contained** — the executor agent receives only the story description, never the source plan. All code, requirements, and verification commands are copied verbatim from the plan into the story.

## Schema

### Root Object

```json
{
  "name": "string (REQUIRED)",
  "description": "string (optional)",
  "branchName": "string (optional)",
  "userStories": ["array (REQUIRED, see below)"],
  "metadata": {
    "createdAt": "ISO 8601 string (optional)",
    "updatedAt": "ISO 8601 string (auto-set on write)",
    "version": "string (optional)",
    "sourcePrd": "string — path to source PRD markdown (optional)"
  }
}
```

`project` is accepted as an alias for `name`, but `name` is preferred.

### User Story Object

```json
{
  "id": "string (REQUIRED) — e.g. 'US-001'",
  "title": "string (REQUIRED)",
  "description": "string (optional)",
  "acceptanceCriteria": ["string[] (optional)"],
  "priority": "number (optional, default: 2) — 1=highest, 4=lowest",
  "passes": "boolean (REQUIRED) — false=incomplete, true=complete",
  "labels": ["string[] (optional)"],
  "dependsOn": ["string[] (optional) — IDs of blocking stories"],
  "notes": "string (optional)",
  "completionNotes": "string (optional, alias for notes)"
}
```

### Required Fields (validation fails without these)

| Scope | Field | Type |
|-------|-------|------|
| Root | `name` | string |
| Root | `userStories` | array (1+ elements) |
| Story | `id` | string |
| Story | `title` | string |
| Story | `passes` | boolean |

### Unsupported Fields (rejected by Ralph TUI)

| Field | Why It's Wrong |
|-------|---------------|
| `prd` | Don't wrap content in a `prd` key |
| `tasks` | Use `userStories`, not `tasks` |
| `status` | Use `passes` (boolean), not `status` (string) |
| `subtasks` | Flat list only, no nesting |
| `estimated_hours` | No time tracking |
| `files` | Not part of schema |
| `assignee` | Not part of schema |
| `type` | Not part of schema |
| `epic` | Not part of schema |
| `parent` | Not part of schema |

## Dependencies

`dependsOn` is an array of story IDs. A story is blocked until all its dependencies have `passes: true`.

```json
{
  "id": "US-003",
  "title": "Integration tests",
  "dependsOn": ["US-001", "US-002"],
  "passes": false
}
```

- If a dependency ID doesn't exist in the file, the story is treated as ready.
- Circular dependencies are not checked — ensure a valid DAG.

## Task Selection Order

Ralph TUI selects the next task by:
1. Filter to `passes: false`
2. Filter to stories with all `dependsOn` resolved (`passes: true`)
3. Sort by `priority` (lowest number first)
4. Return first match

## Minimal Valid Example

```json
{
  "name": "My Feature",
  "userStories": [
    {
      "id": "US-001",
      "title": "First task",
      "passes": false
    }
  ]
}
```

## Complete Example

```json
{
  "name": "User Authentication",
  "description": "Add user authentication to the application",
  "branchName": "feature/auth",
  "userStories": [
    {
      "id": "US-001",
      "title": "Create login page",
      "description": "Build login form with email and password fields.",
      "acceptanceCriteria": [
        "Form has email and password inputs",
        "Form validates required fields",
        "Submit button is disabled during submission"
      ],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    },
    {
      "id": "US-002",
      "title": "Implement authentication API",
      "description": "POST /api/auth/login endpoint that verifies credentials and returns JWT.",
      "acceptanceCriteria": [
        "POST /api/auth/login accepts email and password",
        "Returns JWT token on success",
        "Returns 401 on invalid credentials"
      ],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    },
    {
      "id": "US-003",
      "title": "Connect login form to API",
      "description": "Wire up the login form to call the authentication API.",
      "acceptanceCriteria": [
        "Form submits to /api/auth/login",
        "Success stores token and redirects",
        "Error shows message to user"
      ],
      "priority": 2,
      "passes": false,
      "dependsOn": ["US-001", "US-002"]
    }
  ],
  "metadata": {
    "createdAt": "2024-01-15T10:00:00Z",
    "version": "1.0"
  }
}
```

## Instructions

### If `validate <path>` argument provided:

Read the file and check for schema violations:

```bash
# Check for rejected top-level fields
jq 'keys[] | select(. == "prd" or . == "tasks")' <path>

# Check every story has required fields
jq '.userStories[] | select(.id == null or .title == null or .passes == null) | .id // "unnamed"' <path>

# Check for unsupported story fields
jq '.userStories[] | to_entries[] | select(.key | test("^(subtasks|estimated_hours|files|status|assignee|type|epic|parent)$")) | "\(.key) in story"' <path>
```

Report each violation with the fix from the schema above.

### If no argument:

Output the schema summary:

```
prd.json Schema (Ralph TUI)

Root: name (req), description, branchName, userStories (req), metadata
Story: id (req), title (req), passes (req), description, acceptanceCriteria, priority, labels, dependsOn, notes, completionNotes

Rejected fields: prd, tasks, status, subtasks, estimated_hours, files, assignee, type, epic, parent

Use "passes: false" (not "status: open"). Use "userStories" (not "tasks").
```
