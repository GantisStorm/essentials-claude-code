<div align="center">

<img src="https://www.freelogovectors.net/wp-content/uploads/2023/05/essentials_logo_freelogovectors.net_.png" alt="Essentials" width="350"/>

# Essentials for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Verification-driven loops for Claude Code.**

Plans define exit criteria. Loops run until tests pass. Done means actually done.

Integrates with [Ralph TUI](https://github.com/subsy/ralph-tui) and [Beads](https://github.com/steveyegge/beads) for dashboard visualization and persistent task tracking.

</div>

---

## The Problem

```
You: "Add authentication"
AI:  *writes code* "Done!"
You: *runs tests* — 3 failing
You: "Fix these"
AI:  "Fixed!"
You: *runs tests* — still failing
     [repeat until you give up]
```

## The Solution

```
You: /plan-creator Add authentication
You: /implement-loop .claude/plans/auth-plan.md
AI:  *implements, tests fail, fixes, tests fail, fixes...*
AI:  "Exit criteria passed" ✓
     [loop cannot end until tests pass]
```

---

## Quick Start

```bash
# Install
/plugin marketplace add GantisStorm/essentials-claude-code
/plugin install essentials@essentials-claude-code
mkdir -p .claude/plans .claude/maps .claude/prompts .claude/prd

# Create plan → Execute loop → Done when tests pass
/plan-creator Add user authentication with JWT
/implement-loop .claude/plans/user-auth-3k7f2-plan.md
```

**Zero external dependencies.** The loop runs until your exit criteria pass.

---

## Three Workflows

Pick the one that fits your needs:

| Workflow | Best For | Dependencies |
|----------|----------|--------------|
| **Simple** | 80% of tasks | None |
| **Tasks** | RalphTUI dashboard | Optional: [RalphTUI](https://github.com/subsy/ralph-tui) |
| **Beads** | Multi-session persistence | Required: [Beads CLI](https://github.com/steveyegge/beads) |

### Simple (Start Here)

```bash
/plan-creator Add JWT authentication
/implement-loop .claude/plans/jwt-auth-plan.md
# Loop runs until exit criteria pass
```

### Tasks (prd.json + RalphTUI)

```bash
/plan-creator Add JWT authentication
/tasks-creator .claude/plans/jwt-auth-plan.md
/tasks-loop .claude/prd/jwt-auth.json
# Or visualize with: ralph-tui run --prd .claude/prd/jwt-auth.json
```

### Beads (Persistent Memory)

```bash
bd init
/plan-creator Add JWT authentication
/beads-creator .claude/plans/jwt-auth-plan.md
/beads-loop
# Survives context loss, multi-day features, session crashes
```

---

## How Loops Work

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Plan ──→ Implement ──→ Run Exit Criteria          │
│                              │                      │
│                         Pass? ───→ DONE ✓           │
│                              │                      │
│                         Fail? ───→ Fix ──┐          │
│                              ▲           │          │
│                              └───────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

The loop **cannot** end until verification passes. No exceptions.

---

## Commands

### Create Plans

| Command | Purpose |
|---------|---------|
| `/plan-creator <task>` | Implementation plan with exit criteria |
| `/bug-plan-creator <error> <desc>` | Bug investigation + fix plan |
| `/code-quality-plan-creator <files>` | LSP-powered quality analysis |

### Execute Loops

| Command | Stops When | Cancel With |
|---------|------------|-------------|
| `/implement-loop <plan>` | Exit criteria pass | `/cancel-implement` |
| `/tasks-loop [prd.json]` | All tasks pass | `/cancel-tasks` |
| `/beads-loop [--label]` | No ready beads | `/cancel-beads` |

### Convert Formats

| Command | Converts To |
|---------|-------------|
| `/tasks-creator <plan>` | prd.json for RalphTUI |
| `/beads-creator <plan>` | Beads issues |

### Utilities

| Command | Purpose |
|---------|---------|
| `/codemap-creator [dir]` | JSON code map via LSP |
| `/document-creator <dir>` | DEVGUIDE.md generation |
| `/prompt-creator <desc>` | Quality prompt creation |
| `/mr-description-creator` | PR/MR descriptions via gh/glab |

---

## What's In A Plan?

Plans are markdown files in `.claude/plans/`. They contain everything needed:

```markdown
## Reference Implementation
[Complete code, 50-200+ lines — not pseudocode]

## Migration Patterns
[Exact before/after with file:line references]

## Exit Criteria
npm test -- auth && npm run typecheck
[Specific commands, not "run tests"]

## Architecture
[Current system understanding]

## Testing Strategy
[What tests to add]
```

**The Self-Contained Rule:** Each task must be implementable with ONLY its description. No "see design.md" allowed. When context compacts, the executor only has the task.

---

## prd.json Schema

For the Tasks workflow:

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

**Key:** Use `userStories` not `tasks`. Use `passes` not `status`.

---

## Project Structure

```
your-project/
├── .claude/
│   ├── plans/          # Source of truth
│   ├── prd/            # prd.json files
│   ├── maps/           # Code maps
│   └── prompts/        # Generated prompts
└── .beads/             # Beads DB (if using)
```

---

## Model Configuration

Edit YAML frontmatter in `essentials/commands/*.md` or `essentials/agents/*.md`:

```yaml
---
model: opus    # opus | sonnet | haiku
---
```

| Model | Use For |
|-------|---------|
| `opus` | Complex reasoning (default) |
| `sonnet` | Balanced cost/quality |
| `haiku` | Fast, simple tasks |

---

## Requirements

| Tool | Required? | Purpose |
|------|-----------|---------|
| None | — | Simple workflow works out of the box |
| [Beads CLI](https://github.com/steveyegge/beads) | For Beads workflow | `brew tap steveyegge/beads && brew install bd` |
| [RalphTUI](https://github.com/subsy/ralph-tui) | For dashboard | TUI visualization |
| Context7 MCP | Optional | Enhanced docs in plans |
| SearXNG MCP | Optional | Web search in plans |

---

## Troubleshooting

**Loop won't stop?**
Exit criteria must return exit code 0. Check your test command.

**Wrong exit criteria?**
Edit `.claude/plans/your-plan.md` directly, then re-run the loop.

**Context filling up?**
Plans are external files. Loop re-reads them after context compacts.

**prd.json tasks not found?**
Use `userStories` and `passes` fields. See schema above.

**Beads CLI missing?**
`brew tap steveyegge/beads && brew install bd`

---

## Best Practices

1. **Start simple** — `/plan-creator` + `/implement-loop` handles 80% of tasks
2. **Exit criteria = exact commands** — `npm test -- auth`, not "run tests"
3. **Review plans before looping** — Cheaper to fix a plan than debug bad code
4. **Escalate when needed** — Tasks/Beads for multi-session or context issues

---

## Documentation

- [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) — Zero-dependency default
- [WORKFLOW-TASKS.md](WORKFLOW-TASKS.md) — prd.json + RalphTUI
- [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) — Persistent multi-session
- [COMPARISON.md](COMPARISON.md) — Why verification matters

---

## Contributing

1. Fork it
2. Create your branch (`git checkout -b feature/thing`)
3. Commit changes
4. Push and open a PR

---

## Credits

- [Ralph Wiggum pattern](https://ghuntley.com/ralph/) by Geoffrey Huntley
- Built for [Claude Code](https://claude.ai/code)

---

<div align="center">

MIT License

*"Done" means tests pass. No exceptions.*

</div>
