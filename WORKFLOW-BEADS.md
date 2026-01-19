# Beads Workflow for Persistent Execution

> **Don't start here.** This is the most token-expensive workflow. Use [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) first. Escalate to beads only when the simple workflow fails—AI hallucinates mid-task, loses track, or the feature spans multiple days.

[Beads](https://github.com/steveyegge/beads) provides persistent, structured memory that survives session boundaries and context compaction. Use for large features spanning multiple sessions, or when plans cause hallucinations mid-implementation.

---

## What are Beads?

Atomic, self-contained task units in a local graph database. Unlike plans (session-scoped) or specs (project-scoped), beads **persist** across sessions.

| Component | Purpose |
|-----------|---------|
| Requirements | Full requirements copied verbatim |
| Reference Implementation | 20-400+ lines based on complexity |
| Migration Pattern | Exact before/after for file edits |
| Exit Criteria | Specific verification commands |
| Dependencies | `depends_on`/`blocks` relationships |
| Labels | Link to source (`plan:feature-name`) |

**Key insight:** When context compacts, `bd ready` always shows what's next. Each bead has everything needed—no reading other files.

---

## Setup

**Install:** `brew tap steveyegge/beads && brew install bd` (or npm: `npm install -g @beads/bd`)

**Initialize:**

| Mode | Command | When to Use |
|------|---------|-------------|
| Stealth | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected Branch | `bd init --branch beads-sync` | When main is protected |

**Stealth Mode** (`--stealth`): Keeps `.beads/` local only - no git sync, no team collaboration. Use for personal or brownfield projects.

**Essential commands:**
| Command | Action |
|---------|--------|
| `bd ready` | List tasks with no blockers |
| `bd blocked` | Show tasks waiting on dependencies |
| `bd create "Title" -p 0` | Create P0 task |
| `bd dep add <child> <parent>` | Link dependencies |
| `bd close <id> --reason "Done"` | Complete task |
| `bd sync` | Force immediate sync |

---

## The 4-Stage Workflow

```
PLANNING (Human Control)                    EXECUTION (AI Autonomy)
┌────────────────────────────────────┐      ┌─────────────────────────────────┐
│ 1. Analysis: "ultrathink..."       │      │ 3. /beads-creator <plan>        │
│ 2. /plan-creator → validate plan   │─────▶│ 4. /beads-loop                  │
│                                    │      │    bd ready → implement → close │
└────────────────────────────────────┘      └─────────────────────────────────┘
```

### Stages 1-2: Planning

```
ultrathink and traverse and analyse the code. Ask clarifying questions before finalising.
```

```bash
/plan-creator <task>                # Create plan
```

**Validate before beads:** Read plan, verify implementation code is correct, check task breakdown. Skipping leads to wasted work.

### Stage 3: Import to Beads

```bash
/beads-creator .claude/plans/feature-3k7f2-plan.md
```

**Output shows execution order:**
```
EXECUTION ORDER (by priority):
  P0 (no blockers): task-001, task-002
  P1 (after P0): task-003, task-004
  P2 (after P1): task-005
```

**Review beads:** `bd list -l "plan:<name>"` then `bd show <id>` — verify complete code snippets and exit criteria.

### Stage 4: Execute

**Option A: Internal Loop**
```bash
/beads-loop --label plan:<name>               # Run all beads with label
/beads-loop --max-iterations 10               # Limit iterations (optional)
/cancel-beads                                  # Stop gracefully
```

**Option B: RalphTUI (external)**
```bash
ralph-tui run --tracker beads --epic <epic-id>    # Visual TUI dashboard
```

RalphTUI requires `ralph` label on beads. Either add during creation or configure RalphTUI to use your label:
```toml
# .ralph-tui/config.toml
[trackerOptions]
labels = "plan:my-feature"
```

**Loop mechanism:** Stop hook checks `bd ready` for remaining tasks. If ready beads exist, loop continues.

**Loop cycle:** `bd ready` → pick highest priority → implement → `bd close` → repeat until no ready beads.

---

## The Self-Contained Bead Rule

Each bead must be implementable with ONLY its description. The Context Chain section is for disaster recovery only.

| Bad | Good |
|-----|------|
| "See design.md" | FULL code (50-200+ lines) in bead |
| "Run tests" | `npm test -- stripe-price` |
| "Update entity" | File + line numbers + before/after |

```bash
bd create "Add fields to entity.ts" -t task -p 2 -l "plan:billing" -d "
## Context Chain (disaster recovery ONLY)
**Plan Reference**: .claude/plans/billing-plan.md

## Requirements
<COPY full text from plan - not a reference>

## Reference Implementation
EDIT: path/to/file.ts
**BEFORE** (line 25): <code>
**AFTER**: <code>

## Exit Criteria
npm test -- stripe-price && npm run typecheck
"
```

The `## Context Chain` section is for disaster recovery only—normally the bead description has everything needed.

---

## When to Use Beads vs Other Workflows

| Situation | Workflow |
|-----------|----------|
| Single session, most tasks | [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) |
| Want RalphTUI dashboard, simpler format | [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) |
| Multi-session, context loss | **Beads** (this workflow) |
| AI hallucinating mid-task | **Beads** (this workflow) |
| Need persistent memory across days | **Beads** (this workflow) |
| Bug fix, small task | `bd create` directly |
| Found during work | `bd create --discovered-from <parent>` |

---

## Land the Plane Protocol

Work is NOT complete until `git push` succeeds.

```bash
bd close <id> --reason "Completed"
git pull --rebase && bd sync && git add -A && git commit -m "chore: session end" && git push
bd ready && git status    # Must be clean
```

---

## Configuration

```bash
bd setup claude    # Install hooks for Claude Code
bd setup cursor    # Cursor IDE rules
```

**Protected branches:** `bd init --branch beads-sync` + `bd daemon --start --auto-commit`

**Labels:** `plan:<name>`, `discovered`, `tech-debt`, `blocked-external`

---

## Resources

- [Beads GitHub](https://github.com/steveyegge/beads)
- [Installing bd](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Protected Branches](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)
- [RalphTUI Beads Tracker](https://ralph-tui.com/docs/plugins/trackers/beads)

**Related:** [Simple workflow](WORKFLOW-SIMPLE.md) | [Tasks workflow](WORKFLOW-TASKS.md) | [Main guide](README.md)
