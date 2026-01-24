# Tasks Workflow

> **Loops and swarms with prd.json format.** Powered by Claude Code's built-in Task System.

**Optional workflow for prd.json format.** Use [Simple workflow](WORKFLOW-SIMPLE.md) for most tasks. Use Tasks when you want structured JSON task tracking.

**Requires:** Claude Code v2.1.19+ (native task dependencies, `ctrl+t` progress, automatic persistence)

## When to Use

- You want prd.json format for task tracking
- You prefer structured JSON over markdown plans

## Execution Options

| Executor | Style | How |
|----------|-------|-----|
| `/tasks-loop`, `/tasks-swarm` | Claude Code's Task System (recommended) | Native dependencies, `ctrl+t` progress |
| Ralph TUI | Classic Ralph Wiggum loop | Community approach before native tasks |

**Note:** Both executors work with the same prd.json files created by `/tasks-converter`.

---

## Overview

```
/plan-creator <task>  →  /tasks-converter plan.md  →  /tasks-loop prd.json   (sequential)
                                                   →  /tasks-swarm prd.json  (parallel)
                                                   →  ralph-tui run          (dashboard)
```

---

## Usage

### 1. Create Plan
```bash
/plan-creator Add user authentication with JWT
```

### 2. Convert to prd.json
```bash
/tasks-converter .claude/plans/user-auth-3k7f2-plan.md
# Output: .claude/prd/user-auth-3k7f2.json
```

### 3. Execute: Loop or Swarm

**Loop (sequential, updates prd.json):**
```bash
/tasks-loop .claude/prd/user-auth-3k7f2.json
/cancel-loop                                     # Stop gracefully
```

**Swarm (parallel, faster):**
```bash
/tasks-swarm .claude/prd/user-auth-3k7f2.json    # Auto-detects workers
/cancel-swarm                                    # Stop workers
```

**RalphTUI (optional dashboard):**
```bash
ralph-tui run --prd .claude/prd/user-auth-3k7f2.json
```

### Loop vs Swarm

| Aspect | Loop | Swarm |
|--------|------|-------|
| Execution | Sequential | Parallel |
| prd.json sync | ✅ Updates `passes` | ✅ Updates `passes` |
| RalphTUI compatible | ✅ Yes | ✅ Yes |
| Best for | Verification, strict order | Speed, independent tasks |

---

## prd.json Schema

```json
{
  "name": "Feature Name",
  "userStories": [
    {
      "id": "US-001",
      "title": "Task title",
      "description": "FULL implementation (50-200+ lines)",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

### Required Fields

| Field | Type | Notes |
|-------|------|-------|
| `userStories` | array | NOT `tasks` or `items` |
| `passes` | boolean | NOT `status: "pending"` |
| `acceptanceCriteria` | string[] | NOT `criteria` |
| `dependsOn` | string[] | NOT `dependencies` |

Each task's `description` must contain EVERYTHING needed to implement—the executor never reads the original plan.

---

## Context Recovery

```bash
ls .claude/prd/                                           # List prd files
jq '.' .claude/prd/<name>.json                            # Read prd
jq '[.userStories[] | select(.passes == false)]' <file>   # Pending tasks
```

---

## RalphTUI (Optional)

Visual TUI dashboard for task execution. **For execution only**—use this plugin for planning.

### Install

```bash
# 1. Install Bun (required runtime)
curl -fsSL https://bun.sh/install | bash

# 2. Install RalphTUI
bun install -g ralph-tui

# 3. Setup (per project)
cd your-project && ralph-tui setup
```

### Run

```bash
ralph-tui run --prd .claude/prd/feature.json
ralph-tui run --prd ./prd.json --iterations 5
ralph-tui run --prd ./prd.json --headless
```

### Verify

```bash
ralph-tui --version
ralph-tui plugins agents
ralph-tui config show
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `s` | Start |
| `p` | Pause/Resume |
| `q` | Quit |
| `j/k` | Navigate |
| `o` | Cycle views |
| `T` | Subagent tree |
| `?` | All shortcuts |

### Troubleshooting

**"bun: command not found"** — Add to `~/.zshrc`:
```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

**"Agent not found"** — Run `which claude` and `ralph-tui plugins agents`

**Resources:** [RalphTUI Docs](https://ralph-tui.com/docs) · [GitHub](https://github.com/subsy/ralph-tui)

---

## Managing .ralph-tui/ Folder

The `ralph-tui setup` command creates a `.ralph-tui/` folder in your project with configuration and state files.

### Folder Structure

```
.ralph-tui/
├── config.toml       # Configuration (tracker, agent, options)
├── progress.md       # Cross-iteration context (patterns, notes)
├── session-meta.json # Current session state (auto-managed)
└── iterations/       # Iteration logs (created during runs)
```

### Recommended Configurations

**For Tasks (prd.json):**

```toml
# .ralph-tui/config.toml
configVersion = "2.1"
maxIterations = 0                              # Unlimited - complete all tasks
agent = "claude"
tracker = "json"
autoCommit = false
subagentTracingDetail = "full"                 # Show nested output and hierarchy

[agentOptions]
model = "claude-opus-4-5-20251101"             # Use Opus for best results

[trackerOptions]
# path is passed via CLI: ralph-tui run --prd ./path.json

[notifications]
sound = "system"
```

**For Beads:**

```toml
# .ralph-tui/config.toml
configVersion = "2.1"
maxIterations = 0                              # Unlimited - complete all tasks
agent = "claude"
tracker = "beads-bv"
autoCommit = false
subagentTracingDetail = "full"                 # Show nested output and hierarchy

[agentOptions]
model = "claude-opus-4-5-20251101"             # Use Opus for best results

[trackerOptions]
# epicId is passed via CLI: ralph-tui run --epic <epic-id>

[notifications]
sound = "system"
```

**Key settings:**
- `maxIterations = 0` — Run until all tasks complete
- `model = "claude-opus-4-5-20251101"` — Best reasoning for complex tasks
- `subagentTracingDetail = "full"` — Full visibility into agent activity
- `sound = "system"` — Desktop notifications on completion

### Switching Trackers

When working in the same repo with both Tasks and Beads workflows, update `config.toml`:

**For Tasks (prd.json):**
```toml
tracker = "json"

[trackerOptions]
# path is passed via CLI: ralph-tui run --prd ./path.json
```

**For Beads:**
```toml
tracker = "beads-bv"

[trackerOptions]
# epicId is passed via CLI: ralph-tui run --epic <epic-id>
```

Or override at runtime without editing config:
```bash
# Tasks workflow
ralph-tui run --tracker json --prd .claude/prd/feature.json

# Beads workflow
ralph-tui run --tracker beads-bv --epic <epic-id>
```

### Git Recommendations

**Include in repo (team settings):**
```gitignore
# .gitignore - track config, ignore state
!.ralph-tui/config.toml
.ralph-tui/session-meta.json
.ralph-tui/iterations/
```

**Exclude entirely (personal setup):**
```gitignore
.ralph-tui/
```

**Re-run setup anytime:**
```bash
ralph-tui setup    # Interactive wizard
ralph-tui setup --force  # Overwrite existing
```

### Custom Prompt Templates (Disable Auto-Commit)

**Important:** The `autoCommit = false` config setting only controls whether RalphTUI itself commits. The **default prompt template** still instructs the AI agent to commit after each task. To fully disable commits, use a custom template.

Create `.ralph-tui/templates/json.hbs`:

```bash
mkdir -p .ralph-tui/templates
```

Then create the file with this content (RalphTUI's default template with commit step removed):

```handlebars
{{!-- Full PRD for project context (agent studies this first) --}}
{{#if prdContent}}
We are working in a project to implement the following Product Requirements Document (PRD):

{{prdContent}}

---
{{/if}}

{{!-- Task details --}}
## Your Task: {{taskId}} - {{taskTitle}}

{{#if taskDescription}}
### Description
{{taskDescription}}
{{/if}}

{{#if acceptanceCriteria}}
### Acceptance Criteria
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
1. Study the PRD context above to understand the bigger picture
2. Study `.ralph-tui/progress.md` to understand overall status, implementation progress, and learnings including codebase patterns and gotchas
3. Implement this single story following acceptance criteria
4. Run quality checks: typecheck, lint, etc.
5. Document learnings in `.ralph-tui/progress.md`
6. Signal completion

## Stop Condition
**IMPORTANT**: If the work is already complete, verify it meets the
acceptance criteria and signal completion immediately.

When finished, signal completion with:
<promise>COMPLETE</promise>
```

**Template locations (checked in order):**
1. `--prompt ./path.hbs` (CLI flag)
2. `.ralph-tui/templates/json.hbs` (project)
3. `~/.config/ralph-tui/templates/json.hbs` (global)
4. Built-in default

**View current template:**
```bash
ralph-tui template show
```

---

## Comparison

| Feature | `/tasks-loop` | `ralph-tui` |
|---------|---------------|-------------|
| Install | None | bun + ralph-tui |
| Interface | Terminal | TUI dashboard |
| Multi-agent | Claude only | Claude, OpenCode, Droid |

---

## Related

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Default workflow, zero dependencies
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent task tracking with Beads
- [README.md](README.md) — All commands and plan creators
