# Beads Workflow

> **Loops and swarms with persistent memory.** Powered by Claude Code's built-in Task System.

**Optional workflow for multi-session work.** Use [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Beads when you need persistent memory across sessions or multi-day features.

**Requires:** Claude Code v2.1.19+ (native task dependencies, `ctrl+t` progress, automatic persistence)

## When to Use

- Multi-day features spanning multiple sessions
- AI loses track mid-task or hallucinates
- Context keeps compacting and losing progress
- Need persistent memory that survives session boundaries

## Execution Options

| Executor | Style | How |
|----------|-------|-----|
| `/beads-loop`, `/beads-swarm` | Claude Code's Task System (recommended) | Native dependencies, `ctrl+t` progress |
| Ralph TUI | Classic Ralph Wiggum loop | Community approach before native tasks |

**Note:** Both executors work with the same beads created by `/beads-converter`.

---

## Requirements

```bash
brew tap steveyegge/beads && brew install bd
```

---

## Overview

```
/plan-creator <task>  →  /beads-converter plan.md  →  /beads-loop   (sequential)
                                                   →  /beads-swarm  (parallel)
                                                   →  ralph-tui run (dashboard)
```

**How dependencies flow:**
```
Plan Creator               beads-converter            beads-loop / beads-swarm
┌──────────────────┐    ┌────────────────────┐    ┌──────────────────────┐
│ ## Dependency     │ →  │ bd dep add         │ →  │ addBlockedBy (task   │
│ Graph            │    │ (beads depends_on) │    │ primitive)           │
│                  │    │                    │    │                      │
│ Phase 1: A, B   │    │ beads-abc: no deps │    │ task "1": ready      │
│ Phase 2: C      │    │ beads-def: no deps │    │ task "2": ready      │
│   depends on A,B│    │ beads-ghi: dep abc │    │ task "3": blocked    │
│                  │    │            dep def │    │   blockedBy: ["1","2"]│
└──────────────────┘    └────────────────────┘    └──────────────────────┘
```

The plan's `## Dependency Graph` table is the source of truth. The converter reads it to build file→bead ID maps and runs `bd dep add` for each dependency. The executor reads `depends_on` from `bd list --json` and translates to `addBlockedBy` using an ID map. Beads in the same phase run in parallel in swarm mode.

---

## Setup

### 1. Install Beads CLI

```bash
# macOS
brew tap steveyegge/beads && brew install bd

# Or npm
npm install -g @anthropics/beads
```

### 2. Initialize

| Mode | Command | Use Case |
|------|---------|----------|
| Stealth | `bd init --stealth` | Personal/brownfield, local only |
| Full Git | `bd init` | Team projects, sync via git |
| Protected | `bd init --branch beads-sync` | When main is protected |

### 3. Fix Common Issues

```bash
bd doctor --fix
```

---

## Usage

### 1. Create Plan
```bash
/plan-creator Add complete auth system
# Also works: /bug-plan-creator, /code-quality-plan-creator
```

### 2. Convert to Beads
```bash
/beads-converter .claude/plans/auth-system-3k7f2-plan.md
# Creates epic + child tasks with 'ralph' label
# Sets dependencies via bd dep add from plan's Dependency Graph
```

The converter reads the plan's `## Dependency Graph` table, builds a file→bead ID map, and runs `bd dep add` for each dependency. Uses heredoc (`<<'BEAD_EOF'`) for bead descriptions containing code blocks. Falls back to per-file `Dependencies`/`Provides` for older plans.

### 3. Execute: Loop or Swarm

**Loop (sequential, syncs beads):**
```bash
/beads-loop                         # All beads with ralph label
/beads-loop --label custom-label    # Filter by label
/cancel-loop                        # Stop gracefully
```

**Swarm (parallel, faster):**
```bash
/beads-swarm                            # Default: 3 workers
/beads-swarm --epic <epic-id>           # Filter by epic
/beads-swarm --label ralph --workers 5  # Override worker count
/cancel-swarm                           # Stop workers
```

**RalphTUI (optional dashboard):**
```bash
ralph-tui run --tracker beads --epic <epic-id>
```

### Loop vs Swarm

| Aspect | Loop | Swarm |
|--------|------|-------|
| **Executor** | Main agent (foreground) | Background agents |
| **Concurrency** | 1 task at a time | Up to N tasks (`--workers`) |
| **Context** | Full conversation history | Each agent gets task description only |
| **Beads sync** | Closes beads | Closes beads |
| **RalphTUI compatible** | Yes | Yes |

**Both use the same task graph with dependencies.** Only difference is who executes and how many at once. Swarm is faster when tasks can run in parallel — parallelism depends on the `depends_on` structure. Beads with no unresolved dependencies run simultaneously.

**Task lifecycle**: `pending` → (blocked until deps complete) → `in_progress` → `completed`

---

## Essential Commands

```bash
bd ready                             # Tasks with no blockers
bd blocked                           # Tasks waiting on dependencies
bd list -l ralph                     # Tasks with ralph label
bd show <id>                         # Full task details
bd close <id> --reason "Done"        # Complete task
bd sync                              # Force sync
```

---

## Context Recovery

```bash
bd ready                        # What's next
bd blocked                      # What's waiting
bd list --status in_progress    # Current work
bd show <id>                    # Full details
```

---

## Land the Plane

Work is NOT complete until `git push` succeeds:

```bash
bd close <id> --reason "Completed"
git pull --rebase && bd sync && git add -A && git commit -m "chore: session end" && git push
```

---

## RalphTUI (Optional)

For installation, see [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md#ralphtui-optional).

### Setup for Beads

```bash
ralph-tui setup    # Select beads-bv tracker when prompted
```

Then update `.ralph-tui/config.toml` with [recommended settings](WORKFLOW-TASKS.md#recommended-configurations):

```toml
configVersion = "2.1"
maxIterations = 0
agent = "claude"
tracker = "beads-bv"
autoCommit = false
subagentTracingDetail = "full"

[agentOptions]
model = "claude-opus-4-5-20251101"

[trackerOptions]

[notifications]
sound = "system"
```

**Switching workflows?** See [Managing .ralph-tui/ Folder](WORKFLOW-TASKS.md#managing-ralph-tui-folder) for switching between Tasks and Beads trackers.

### Beads-Specific Usage

```bash
ralph-tui run --tracker beads-bv --epic <epic-id>
```

**Task Hierarchy:** Tasks must be children of the epic to appear:

```bash
bd create --title "Feature" --type epic     # → beads-abc123
bd create --title "Task 1" --type task --parent beads-abc123 -l ralph
```

The `/beads-converter` command handles this automatically.

### Custom Prompt Templates (Disable Auto-Commit)

**Important:** The `autoCommit = false` config setting only controls whether RalphTUI itself commits. The **default prompt template** still instructs the AI agent to commit after each task. To fully disable commits, use a custom template.

Create `.ralph-tui/templates/beads-bv.hbs`:

```bash
mkdir -p .ralph-tui/templates
```

Then create the file with this content (RalphTUI's default template with commit step removed):

```handlebars
{{!-- Full PRD for project context (if available) --}}
{{#if prdContent}}
We are working in a project to implement the following Product Requirements Document (PRD):

{{prdContent}}

---
{{/if}}

## Bead Details
- **ID**: {{taskId}}
- **Title**: {{taskTitle}}
{{#if epicId}}
- **Epic**: {{epicId}}{{#if epicTitle}} - {{epicTitle}}{{/if}}
{{/if}}
{{#if taskDescription}}
- **Description**: {{taskDescription}}
{{/if}}

{{#if acceptanceCriteria}}
## Acceptance Criteria
{{acceptanceCriteria}}
{{/if}}

{{#if dependsOn}}
**Prerequisites**: {{dependsOn}}
{{/if}}

{{#if recentProgress}}
## Recent Progress
{{recentProgress}}
{{/if}}

## Workflow
1. Study the PRD context above (if available)
2. Study `.ralph-tui/progress.md` to understand overall status, implementation progress, and learnings including codebase patterns and gotchas
3. Implement the requirements (stay on current branch)
4. Run your project's quality checks
5. Close the bead: `bd close {{taskId}} --db {{beadsDbPath}} --reason "..."`
6. Document learnings in `.ralph-tui/progress.md`
7. Signal completion

## Stop Condition
**IMPORTANT**: If the work is already complete, verify it works
correctly and signal completion immediately.

When finished, signal completion with:
<promise>COMPLETE</promise>
```

**Template locations (checked in order):**
1. `--prompt ./path.hbs` (CLI flag)
2. `.ralph-tui/templates/beads-bv.hbs` (project)
3. `~/.config/ralph-tui/templates/beads-bv.hbs` (global)
4. Built-in default

**View current template:**
```bash
ralph-tui template show
```

---

## Comparison

| Feature | `/beads-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Install | Beads CLI | Beads CLI + bun + ralph-tui |
| Interface | Terminal | TUI dashboard |
| Multi-agent | Claude only | Claude, OpenCode, Droid |

---

## Resources

- [Beads GitHub](https://github.com/steveyegge/beads)
- [Installing bd](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Protected Branches](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)

---

## Related

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — Dashboard visualization with Ralph TUI
- [README.md](README.md) — All commands and plan creators
