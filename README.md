# Essentials for Claude Code

**Plan first. Implement until done.** No more "it's complete" when tests are failing.

## The Problem

Claude Code is powerful, but without structure it can:
- Start coding before understanding the full picture
- Lose track of what's done when context gets long
- Say "done" when tests are still failing
- Hallucinate on large features that exceed context

**The Solution:** Plan first, then implement until exit criteria pass.

```bash
/plan-creator Add user authentication with JWT
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
# Loop continues until ALL exit criteria pass
```

## Install

```bash
/plugin marketplace add GantisStorm/essentials-claude-code
/plugin install essentials@essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts
# Note: .beads/ directory is created automatically by `bd init` if using Beads workflow
```

## Workflows

> **80% of tasks need only the Simple workflow.** Start there. Escalate only when you hit problems (hallucinations, lost context, multi-day features).

| Workflow | Commands | Execution | When to Use |
|----------|----------|-----------|-------------|
| **Simple** | `/plan-creator` → `/implement-loop` | Internal | Single session, most tasks (start here) |
| **Tasks** | Plan → `/tasks-creator` | `/tasks-loop` or RalphTUI | RalphTUI dashboard, prd.json format |
| **Beads** | Plan → `/beads-creator` | `/beads-loop` or RalphTUI | Multi-session, context loss, hallucinations |

```mermaid
flowchart LR
    P["/plan-creator<br/>/bug-plan-creator<br/>/code-quality-plan-creator"] --> Plans[".claude/plans/"]
    Plans --> IL["/implement-loop"]
    Plans --> TC["/tasks-creator"]
    Plans --> BC["/beads-creator"]
    TC --> TL["/tasks-loop<br/>or RalphTUI"]
    BC --> BL["/beads-loop<br/>or RalphTUI"]

    IL --> Done1(("✓ Exit criteria pass"))
    TL --> Done2(("✓ All tasks complete"))
    BL --> Done3(("✓ No ready beads"))
```

**Simple:** Single-session features, bug fixes, refactoring. `/plan-creator` analyzes codebase → `/implement-loop` executes until exit criteria pass.

**Tasks:** RalphTUI integration with prd.json format. `/plan-creator` → `/tasks-creator` creates prd.json → `/tasks-loop` executes internally or `ralph-tui run --prd` for TUI dashboard.

**Beads:** Persistent memory across sessions. `/plan-creator` → `/beads-creator` creates self-contained beads → `/beads-loop` executes internally or `ralph-tui run --tracker beads` for TUI dashboard.

## Commands

### Planning

| Command | Purpose | Output |
|---------|---------|--------|
| `/plan-creator <task>` | Create implementation plan | `.claude/plans/{task}-{hash}-plan.md` |
| `/bug-plan-creator <error> <desc>` | Bug investigation plan | `.claude/plans/bug-fix-{desc}-{hash}-plan.md` |
| `/code-quality-plan-creator <files>` | Code quality analysis | `.claude/plans/code-quality-{file}-{hash}-plan.md` |
| `/tasks-creator <plan>` | Convert plan → prd.json | `./prd.json` |
| `/beads-creator <plan>` | Convert plan → Beads | Beads database |

### Loops

All loops run until complete. Optional: `--max-iterations N` to limit iterations.

| Command | Completes When | Cancel |
|---------|----------------|--------|
| `/implement-loop <plan>` | Exit criteria pass | `/cancel-implement` |
| `/tasks-loop [prd-path]` | All tasks `passes: true` | `/cancel-tasks` |
| `/beads-loop [--label X]` | No ready beads | `/cancel-beads` |

### Utilities

| Command | Purpose |
|---------|---------|
| `/codemap-creator [dir]` | Generate JSON code map |
| `/document-creator <dir>` | Generate DEVGUIDE.md |
| `/prompt-creator <desc>` | Create quality prompts |
| `/mr-description-creator` | Create PR/MR description |

### Project Outputs

| Directory | Contents |
|-----------|----------|
| `.claude/plans/` | Architectural plans |
| `.claude/maps/` | Code maps |
| `.claude/prompts/` | Generated prompts |
| `./prd.json` | Tasks file (RalphTUI format) |
| `.beads/` | Beads database (created by `bd init`) |

## Cost Optimization

Commands use optimized model selection:

| Command Type | Model | Rationale |
|-------------|-------|-----------|
| Creators (9) | `opus` | Complex reasoning, architectural planning |
| Loops (3) | `haiku` | Fast/cheap iterative execution |
| Cancels (3) | `haiku` | Lightweight file operations |

This reduces costs for repetitive loop iterations while preserving quality for planning tasks.

## Best Practices

1. **Start simple** — 80% of tasks need only `/plan-creator` → `/implement-loop`. Scale up only when you hit problems.
2. **Exit criteria are non-negotiable** — Not "tests pass" but exact commands: `npm test -- auth`.
3. **Review before looping** — Loops execute autonomously. Editing plans is cheap; debugging bad code is expensive.
4. **Token cost is a tradeoff** — The full pipeline copies code multiple times (plan → tasks/beads) for context recovery. This is intentional but expensive—don't use it for simple tasks.

| After | Review |
|-------|--------|
| Plan | Architecture, file structure, exit criteria |
| Tasks | Task descriptions contain full code, not summaries |
| Beads | Bead descriptions, code snippets, dependencies |

## Context Chain

Each output includes back-references for disaster recovery:

**Tasks Path:**
```
.claude/plans/billing-plan.md        ◄── SOURCE OF TRUTH
  │
  └──► prd.json
       ## Context (disaster recovery ONLY)
       **Plan Reference**: .claude/plans/billing-plan.md
       + FULL code in task description (self-contained)
```

**Beads Path:**
```
.claude/plans/billing-plan.md        ◄── SOURCE OF TRUTH
  │
  └──► beads
       ## Context Chain (disaster recovery ONLY)
       **Plan Reference**: .claude/plans/billing-plan.md
       + FULL code in bead description (self-contained)
```

When context compacts mid-loop, tasks/beads are self-contained (full code in description) but include back-references for recovery.

## How Loops Work

Based on [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) stop-hook pattern (a Claude Code plugin that provides the stop-hook loop pattern for persistent task execution).

**Mechanism:**
1. Setup script creates marker file (e.g., `.claude/implement-loop.local.md` or `.claude/tasks-loop-active`)
2. Stop hooks registered in `hooks.json` intercept exit attempts
3. Hook checks for completion (exit criteria pass, all tasks complete, no ready beads)
4. Not complete → block with continue prompt. Complete → allow exit, clean up marker.

**State tracking:**
- `/implement-loop`: Full state in `.claude/implement-loop.local.md`
- `/tasks-loop`: Task state in `prd.json`, iteration in `.claude/tasks-loop-active`
- `/beads-loop`: Task state in beads DB, iteration in `.claude/beads-loop-active`

**Recovery:** State files + external state (prd.json, beads DB) enable resume after context compaction.

## Requirements

| Tool | For | Install |
|------|-----|---------|
| Beads | `/beads-creator`, `/beads-loop` | [steveyegge/beads](https://github.com/steveyegge/beads) |
| RalphTUI | Alternative execution for Tasks/Beads | [subsy/ralph-tui](https://github.com/subsy/ralph-tui) (optional) |
| Built-in LSP | `/code-quality-plan-creator`, `/codemap-creator`, `/document-creator` | Already included in Claude Code |
| Context7 | `/plan-creator`, `/prompt-creator` | MCP server (optional) |
| SearXNG | `/plan-creator`, `/prompt-creator` | MCP server (optional) |

**Note on MCP servers:** Context7 and SearXNG enhance plan/prompt quality with external documentation and web search but are not required.

**Note on RalphTUI:** RalphTUI provides a visual TUI dashboard for monitoring task execution. Both `/tasks-loop` and `/beads-loop` work without it.

## Guides

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Single-session features, bug fixes, refactoring
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — RalphTUI integration with prd.json format
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent memory that survives sessions and context compaction
- [COMPARISON.md](COMPARISON.md) — Why verification-enforced completion matters (code-first vs conversation vs spec-first vs essentials)

## License

MIT
