# Essentials for Claude Code — Complete Guide

Detailed documentation for all commands, workflows, and integration options.

---

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/plan-creator <task>` | Create architectural implementation plans. Output: `.claude/plans/{task}-{hash}-plan.md` |
| `/bug-plan-creator <error>` | Deep bug investigation with root cause analysis. Output: `.claude/plans/bug-fix-{desc}-{hash}-plan.md` |
| `/code-quality-plan-creator <files>` | LSP-powered code quality analysis (requires Serena MCP). Output: `.claude/plans/code-quality-{file}-{hash}-plan.md` |
| `/proposal-creator [input]` | Convert plans to OpenSpec proposals. Output: `openspec/changes/<id>/` |
| `/implement-loop <plan>` | Execute plan iteratively until exit criteria pass. Stop: `/cancel-implement` |
| `/spec-loop <change-id>` | Execute OpenSpec change until all tasks marked `[x]`. Stop: `/cancel-spec-loop` |
| `/beads-creator <path>` | Convert OpenSpec/SpecKit to self-contained Beads issues. |
| `/beads-loop` | Execute beads until no ready tasks remain. Stop: `/cancel-beads` |
| `/codemap-creator [dir]` | Generate JSON code map with symbol extraction (requires Serena MCP). |
| `/prompt-creator <description>` | Transform descriptions into quality prompts. |
| `/document-creator <dir>` | Generate DEVGUIDE.md documentation (requires Serena MCP). |
| `/mr-description-creator` | Create MR/PR descriptions via gh/glab CLI. |

---

## How the Loops Work

All three loops (`/implement-loop`, `/spec-loop`, `/beads-loop`) work the same way:

1. **Setup** - Creates state file in `.claude/`
2. **Iterate** - Works through tasks one by one
3. **Track** - Updates tasks.md or beads database
4. **Stop Hook** - Prevents exit until complete
5. **Complete** - Removes state file when done

### Tracking Progress

| Loop | Source of Truth | How to Mark Complete |
|------|-----------------|---------------------|
| `/implement-loop` | Plan + TodoWrite | Mark todo as completed |
| `/spec-loop` | `tasks.md` | Edit: `- [ ]` → `- [x]` |
| `/beads-loop` | Beads database + `tasks.md` | `bd close` + edit tasks.md |

### Stopping Loops

| Loop | Cancel Command | Completion Signal |
|------|----------------|-------------------|
| `/implement-loop` | `/cancel-implement` | "Exit criteria passed" |
| `/spec-loop` | `/cancel-spec-loop` | "All spec tasks complete" |
| `/beads-loop` | `/cancel-beads` | "All beads complete" |

---

## Workflows

Choose based on task size:

| Size | Workflow | When to Use |
|------|----------|-------------|
| **Small** | `/plan-creator` → `/implement-loop` | Single session, simple tasks |
| **Medium** | `/plan-creator` → `/proposal-creator` → `/spec-loop` | Need validation before coding |
| **Large** | Plan → Proposal → `/beads-creator` → `/beads-loop` | Multi-session, complex features |

### 3-Stage: Simple

```
/plan-creator <task>
    ↓
.claude/plans/*-plan.md
    ↓
/implement-loop <plan>
    ↓
Exit criteria pass → Done
```

### 4-Stage: With OpenSpec

```
/plan-creator <task>
    ↓
/proposal-creator <plan>
    ↓
openspec/changes/<id>/
    ↓
/spec-loop <id>
    ↓
All tasks [x] → openspec archive <id>
```

### 5-Stage: With Beads

```
/plan-creator <task>
    ↓
/proposal-creator <plan>
    ↓
/beads-creator <spec>
    ↓
/beads-loop --label openspec:<id>
    ↓
No ready tasks → openspec archive <id>
```

---

## Self-Contained Beads

Each bead must be implementable with ONLY its description.

**BAD:**
```
bd create "Update auth" -t task
```

**GOOD:**
```
bd create "Add JWT validation" -t task -p 2 \
  --parent <epic-id> \
  -d "## Requirements
Users must provide valid JWT in Authorization header.

## Implementation
<full code example>

## Acceptance Criteria
- [ ] Invalid token returns 401

## Files
- src/middleware/auth.ts"
```

---

## Beads Loop Workflow

When using `/beads-loop` with OpenSpec:

```
1. bd ready                              # Find next task
2. bd show <id>                          # Read details
3. bd update <id> --status in_progress   # Start work
4. <implement the task>
5. bd close <id> --reason "Done: ..."    # Complete in beads
6. Edit tasks.md: - [ ] → - [x]          # Mark in OpenSpec
7. Repeat until no ready tasks
8. openspec archive <name>               # Archive when done
```

**Key**: After `bd close`, manually edit `tasks.md` to mark the task `[x]`.

---

## Reference

### Directory Structure

```
essentials/
├── agents/          # Specialized agents
├── commands/        # Slash commands
├── hooks/           # Stop hook for loops
├── scripts/         # Setup scripts
└── skills/          # github-cli, gitlab-cli
```

### Project Outputs

- `.claude/plans/` - Architectural plans
- `.claude/maps/` - Code maps
- `.claude/prompts/` - Generated prompts
- `openspec/changes/` - OpenSpec proposals

### Requirements

- **Claude Code** CLI
- **Serena MCP** - For `/code-quality-plan-creator`, `/document-creator`, `/codemap-creator`
- **Beads** - For `/beads-creator`, `/beads-loop`
- **OpenSpec** - For `/proposal-creator`, `/spec-loop`

### License

MIT
