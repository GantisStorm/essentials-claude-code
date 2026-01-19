# Tasks Workflow for RalphTUI Integration

> **Middle-ground option.** Simpler than Beads but supports RalphTUI's TUI dashboard. Use [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) for most tasks. Use this when you want RalphTUI's visual interface or prd.json format.

[RalphTUI](https://github.com/subsy/ralph-tui) is an AI Agent Loop Orchestrator with a terminal UI for monitoring autonomous execution. This workflow creates `.claude/prd/*.json` files compatible with both RalphTUI and the internal `/tasks-loop`.

---

## What is prd.json?

A JSON file containing self-contained tasks following RalphTUI's schema:

```json
{
  "name": "Feature Name",
  "description": "Brief description",
  "branchName": "feature/name",
  "userStories": [
    {
      "id": "US-001",
      "title": "Task title",
      "description": "FULL implementation details",
      "acceptanceCriteria": ["Specific criterion 1"],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

**Key insight**: Each task's `description` contains everything needed to implement - the executor never needs to read the original plan.

---

## Setup

**Install RalphTUI** (optional - only if using external execution):
```bash
bun install -g ralph-tui
ralph-tui setup
```

**No external tools needed** for internal `/tasks-loop` execution.

---

## The 4-Stage Workflow

```
PLANNING (Human Control)                    EXECUTION (Choice)
┌────────────────────────────────────┐      ┌─────────────────────────────────┐
│ 1. Analysis: "ultrathink..."       │      │ 3. /tasks-creator <plan>        │
│ 2. /plan-creator → validate plan   │─────▶│ 4. Execute:                     │
│                                    │      │    /tasks-loop OR ralph-tui     │
└────────────────────────────────────┘      └─────────────────────────────────┘
```

### Stages 1-2: Planning

```
ultrathink and traverse and analyse the code. Ask clarifying questions before finalising.
```

```bash
/plan-creator <task>                # Create architectural plan
```

**Validate before tasks:** Read plan, verify implementation code is correct, check task breakdown. The plan is the source of truth - `/tasks-creator` copies from it verbatim.

### Stage 3: Convert to prd.json

```bash
/tasks-creator .claude/plans/feature-3k7f2-plan.md
```

**Output:**
```
TASKS CREATED

FILE: .claude/prd/feature-3k7f2.json
TOTAL_TASKS: 5
READY_TASKS: 2

## Next Steps

Review tasks:
  cat .claude/prd/feature-3k7f2.json | jq '.userStories | length'

Execute (choose one):
  /tasks-loop .claude/prd/feature-3k7f2.json           # Internal loop
  ralph-tui run --prd .claude/prd/feature-3k7f2.json   # RalphTUI dashboard
```

**Review tasks:** Verify each task has full implementation code, not summaries.

### Stage 4: Execute

**Option A: Internal Loop**
```bash
/tasks-loop .claude/prd/<name>.json                    # Run internally
/tasks-loop .claude/prd/<name>.json --max-iterations 5 # Limit iterations
/cancel-tasks                                           # Stop gracefully
```

**Option B: RalphTUI (external)**
```bash
ralph-tui run --prd .claude/prd/<name>.json            # Visual TUI dashboard
```

---

## Execution Options Comparison

| Feature | `/tasks-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Installation | None (built-in) | Requires bun + ralph-tui |
| Interface | Terminal output | TUI dashboard |
| Pause/Resume | `/cancel-tasks` + restart | Keyboard shortcuts |
| Multi-agent | Claude Code only | Claude, OpenCode, Factory Droid |
| Subagent tree | No | Yes (toggle with T) |

---

## The Self-Contained Task Rule

Each task must be implementable with ONLY its description. The Context field is for disaster recovery only.

| Bad | Good |
|-----|------|
| "See plan for details" | FULL code (50-200+ lines) in description |
| "Run tests" | `npm test -- auth-middleware` |
| "Update the file" | File + line numbers + BEFORE/AFTER code |

**Litmus test:** Could someone implement this with ONLY the task description?

---

## prd.json Schema Reference

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Feature name |
| `description` | string | No | Brief description |
| `branchName` | string | No | Git branch |
| `userStories` | array | Yes | Task list |
| `metadata` | object | No | Optional metadata |

### User Story Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique ID (US-001) |
| `title` | string | Yes | Short title |
| `description` | string | Yes | FULL implementation details |
| `acceptanceCriteria` | string[] | Yes | Verification criteria |
| `priority` | number | No | 1=highest, 2=default |
| `passes` | boolean | Yes | Always `false` initially |
| `dependsOn` | string[] | No | IDs of blocking tasks |

**CRITICAL**: Use `userStories` not `tasks`, use `passes` not `status`.

---

## When to Use Tasks vs Other Workflows

| Situation | Workflow |
|-----------|----------|
| Single session, most tasks | [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) |
| Want RalphTUI dashboard | **Tasks** (this workflow) |
| Simple JSON format needed | **Tasks** (this workflow) |
| Multi-session, context loss | [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) |
| Persistent across sessions | [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) |

---

## Context Recovery

If you lose track:

```bash
# List prd files
ls .claude/prd/

# Read a prd file
cat .claude/prd/<name>.json | jq '.'

# Find pending tasks
jq '[.userStories[] | select(.passes == false)]' .claude/prd/<name>.json

# Find ready tasks (no blockers)
jq '.userStories as $all | [.userStories[] | select(.passes == false) | select((.dependsOn == null) or (.dependsOn | length == 0) or ((.dependsOn // []) | all(. as $dep | ($all | map(select(.id == $dep and .passes == true)) | length > 0))))]' .claude/prd/<name>.json
```

---

## Resources

- [RalphTUI Documentation](https://ralph-tui.com/docs)
- [RalphTUI GitHub](https://github.com/subsy/ralph-tui)
- [RalphTUI JSON Tracker](https://ralph-tui.com/docs/plugins/trackers/json)

**Related:** [Simple workflow](WORKFLOW-SIMPLE.md) | [Beads workflow](WORKFLOW-BEADS.md) | [Main guide](README.md)
