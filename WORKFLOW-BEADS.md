# 5-Stage Workflow: Add Beads for Large Plans

[Beads](https://github.com/steveyegge/beads) is a distributed, git-backed graph issue tracker for AI agents. It provides persistent, structured memory for coding agents, replacing messy markdown plans with a dependency-aware graph that survives session boundaries and context compaction.

**Best for:** Large features spanning multiple sessions, plans that cause hallucinations mid-implementation, long-running projects needing persistent task tracking.

---

## Why Beads?

| Approach | Problem |
|----------|---------|
| **SpecKit/OpenSpec alone** | AI writes good code initially, then **hallucinates** as context fills |
| **Beads alone** | Manually creating tasks for big features is tedious |
| **Together** | Spec tools provide structure → Beads provides atomic execution |

> "Using openspec and beads together gave me great results once I managed to give each bead enough context coming from openspec." — [nicoracarlo on r/ClaudeCode](https://www.reddit.com/r/ClaudeCode/comments/1q182tf/testing_cc_with_openspec_and_beads/)

---

## Installing bd

| Method | Command | Best For |
|--------|---------|----------|
| **Homebrew** | `brew tap steveyegge/beads && brew install bd` | macOS/Linux (recommended) |
| **npm** | `npm install -g @beads/bd` | JS/Node.js projects |
| **Install script** | `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh \| bash` | Quick setup, CI/CD |
| **go install** | `go install github.com/steveyegge/beads/cmd/bd@latest` | Go developers |

**Verify installation:**
```bash
bd version
bd help
```

---

## Essential Commands

| Command | Action |
|---------|--------|
| `bd init` | Initialize beads in project |
| `bd ready` | List tasks with no open blockers |
| `bd create "Title" -p 0` | Create a P0 task |
| `bd dep add <child> <parent>` | Link tasks (blocks, related, parent-child) |
| `bd show <id>` | View task details and audit trail |
| `bd close <id> --reason "Done"` | Complete a task |
| `bd sync` | Export/import/commit/push |

---

## The 5-Stage Workflow

```
┌───────────────────────────────────────────────────────────────────────────┐
│                       PLANNING PHASE (Human Control)                      │
│                                                                           │
│  ┌───────────────────┐   ┌───────────────────┐   ┌─────────────────────┐  │
│  │ STAGE 1: ANALYSIS │   │ STAGE 2: SPEC     │   │ STAGE 3: VALIDATION │  │
│  │                   │   │                   │   │                     │  │
│  │ "ultrathink and   │ → │ /plan-creator     │ → │ Review spec output  │  │
│  │  traverse..."     │   │        +          │   │ Check for:          │  │
│  │                   │   │ /proposal-creator │   │  • Misunderstandings│  │
│  │                   │   │   or              │   │  • Completeness     │  │
│  │                   │   │ /speckit.specify  │   │  • Edge cases       │  │
│  └───────────────────┘   └───────────────────┘   └─────────────────────┘  │
│                                                          │                │
│                              NO ←── "Is spec correct?" ──┴──→ YES         │
│                              ↓                                 ↓          │
│                          iterate                           proceed        │
└───────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ↓
┌───────────────────────────────────────────────────────────────────────────┐
│                      EXECUTION PHASE (AI Autonomy)                        │
│                                                                           │
│  ┌─────────────────────────────┐   ┌───────────────────────────────────┐  │
│  │ STAGE 4: IMPORT TO BEADS    │   │ STAGE 5: EXECUTE WITH /beads-loop │  │
│  │                             │   │                                   │  │
│  │ /beads-creator <spec-path>   │ → │ ┌─────────────────────────────┐   │  │
│  │                             │   │ │ Loop (via stop hook):       │   │  │
│  │ Each bead must be           │   │ │  1. bd ready → pick task    │   │  │
│  │ SELF-CONTAINED with:        │   │ │  2. Implement task          │   │  │
│  │  • Full context             │   │ │  3. bd close                │   │  │
│  │  • Requirements             │   │ │  4. Edit tasks.md → [x]     │   │  │
│  │  • Acceptance criteria      │   │ │  5. Repeat until done       │   │  │
│  │  • Files to modify          │   │ └─────────────────────────────┘   │  │
│  │                             │   │                                   │  │
│  │                             │   │ On complete:                      │  │
│  │                             │   │  • openspec archive <name>        │  │
│  └─────────────────────────────┘   └───────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## Stage 1: Analysis

Force deep understanding before planning:

```
ultrathink and traverse and analyse the code to thoroughly understand
the context before preparing a detailed plan to implement the requirement

Before finalising the plan you can ask me any question to clarify the requirement
```

---

## Stage 2: Plan + Spec Creation

Create architectural plan with `/plan-creator`, then generate specs:

- `/proposal-creator <plan-path>` (recommended - converts plan to OpenSpec)
- `/openspec:proposal` or `/speckit.specify` (manual creation)

---

## Stage 3: Validation (CRITICAL)

Thoroughly validate the spec. Skipping = trouble.

> "Skipping this validation part is like asking for troubles." — nicoracarlo

---

## Stage 4: Import to Beads

Convert specs to self-contained beads with full context chain:

```bash
/beads-creator openspec/changes/<name>/
# or
/beads-creator .specify/
```

### Context Chain: Plan → Spec → Beads

The `/beads-creator` command preserves the full context chain:

```
Plan (SOURCE OF TRUTH)
 │
 │  Contains: Full implementation code, exit criteria, migration patterns
 │
 └──▶ OpenSpec (proposal.md has plan_reference)
       │
       │  Contains: Reference Implementation, Exit Criteria, specs
       │
       └──▶ Beads (each has spec_ref + plan_ref)
             │
             │  Contains: Requirements (copied, not referenced),
             │            Reference Implementation (full code),
             │            Exit Criteria (exact commands)
             │
             └──▶ Loops recover from plan if context lost
```

Each bead is **self-contained** with dual back-references:
- **Spec Reference** → requirements and scenarios
- **Plan Reference** → full implementation code (source of truth)

---

## Stage 5: Execute with /beads-loop

Start the automatic execution loop:

```bash
# Option 1: Automatic loop (recommended)
/beads-loop --label openspec:<change-name>

# Option 2: Manual execution
bd ready                                    # See what's ready
bd update <id> --status in_progress         # Start working
# ... implement ...
bd close <id> --reason "Completed: <summary>"  # Done
bd ready                                    # Next task
```

**The `/beads-loop` command:**
- Runs `bd ready` to find tasks with no blockers
- Picks highest priority task
- Shows full task context with `bd show <id>`
- Implements using the self-contained description
- Closes with `bd close` when done
- **You mark OpenSpec manually** - edit tasks.md to change `- [ ]` to `- [x]`
- **Automatically continues** to next task (via stop hook)
- Stops when no ready tasks remain
- Archive with `openspec archive <name>` when complete

**Stop the loop:**
```bash
/cancel-beads    # Graceful stop, preserves progress
```

**Pro tips:**
- Use `--label` to filter to specific OpenSpec change
- Run `bd show <id>` anytime to see full task details
- Discover new work: `bd create "Found: <issue>" --discovered-from <current-id>`
- Check progress: `bd list -l "openspec:<change-name>"`

---

## The Self-Contained Bead Rule

Each bead must be **self-contained** - an agent must implement it with ONLY the bead description.

**BAD:**
```bash
bd create "Update stripe-price.entity.ts" -t task
```

**GOOD:**
```bash
bd create "Add description and features fields to stripe-price.entity.ts" \
  -t task -p 2 -l "openspec:billing-improvements" \
  -d "## Context Chain

**Spec Reference**: openspec/changes/billing-improvements/specs/billing/spec.md
**Plan Reference**: .claude/plans/billing-improvements-7x3m9-plan.md
**Task**: 2.1 from tasks.md

## Requirements
- Add 'description: string' field (nullable)
- Add 'features: string[]' field for feature list display

## Reference Implementation
\`\`\`typescript
@Column({ nullable: true })
description: string;

@Column('simple-array', { nullable: true })
features: string[];
\`\`\`

## Exit Criteria
- [ ] \`npm test -- stripe-price\` passes
- [ ] TypeScript compiles without errors

## Files to modify
- apps/api/src/billing/entities/stripe-price.entity.ts"
```

**Litmus test:** Could someone implement this with ONLY the bd description? If not, add more context.

**Context recovery:** If you lose context, use the back-references:
1. `bd show <id>` → find spec_reference + plan_reference
2. Read spec → requirements and scenarios
3. Read plan → full implementation code, exit criteria

---

## When to Use What

| Situation | Tool | Action |
|-----------|------|--------|
| New feature | SpecKit/OpenSpec | Create spec first |
| Spec approved | Both | Import to Beads, then implement |
| Bug fix, small task | Beads | `bd create` directly |
| Discovered during work | Beads | `bd create --discovered-from <parent>` |
| Feature complete | OpenSpec | `/openspec:archive` |

---

## The "Land the Plane" Protocol

When ending a session, you **MUST** complete ALL steps. Work is NOT complete until `git push` succeeds.

```bash
# 1. File remaining work
bd create "TODO: <description>" -t task -p 2

# 2. Run quality gates (tests, linters, builds)

# 3. Update tracking
bd close <id> --reason "Completed"
bd update <id> --add-note "Session end: <context>"

# 4. Sync and push (MANDATORY)
git pull --rebase
bd sync
git add -A && git commit -m "chore: session end" && git push

# 5. Verify
bd ready                 # Next session's work
git status               # Must be clean and pushed
```

**Critical Rules:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

---

## Handling Plan Changes

- **Early:** Rollback → edit spec → rebuild beads
- **Late:** Finish current work → create NEW spec for changes

---

## Label Conventions

```
openspec:<change-name>  - Links to OpenSpec change
spec:<spec-name>        - Links to spec file
discovered              - Found during other work
tech-debt               - Technical debt
blocked-external        - External blocker
```

---

## Configuration Examples

### CLAUDE.md

```markdown
## Issue Tracking

ALWAYS use `bd` (Beads). Every `bd create` MUST include `-d` with full context.

❌ bd create "Update file.ts" -t task
✅ bd create "Title" -t task -p 2 -d "## Requirements..."

## Working Style & Approach

**CRITICAL: Think First, Code Once**

When tackling any non-trivial task:
1. **ANALYZE THOROUGHLY FIRST** - Read ALL relevant code before changes
2. **MAP THE SYSTEM** - Identify dependencies and side effects
3. **CLARIFY REQUIREMENTS** - If ANYTHING is unclear, STOP and ASK
4. **DESIGN A COMPLETE SOLUTION** - Think through the approach first
5. **PRESENT THE PLAN** - Explain strategy before writing code
6. **IMPLEMENT CAREFULLY** - Follow the agreed plan
7. **STICK TO THE PLAN** - Don't pivot to quick fixes

### Absolutely Forbidden
- Making reactive changes without understanding root causes
- Fixing one bug and creating another (going in circles)
- Quick fixes that break other things
- Jumping to implementation before thorough analysis
```

### AGENTS.md

```markdown
## Beads Issue Tracking

**BEFORE ANY WORK**: Run `bd onboard` if you haven't already this session.

### When to Use Beads vs OpenSpec

| Situation | Tool | Action |
|-----------|------|--------|
| New feature/capability | OpenSpec | `/proposal-creator` or `/openspec:proposal` |
| Approved spec ready | Both | Import tasks to Beads, implement |
| Bug fix, small task | Beads | `bd create` directly |
| Discovered during work | Beads | `bd create --discovered-from <parent>` |
| Feature complete | OpenSpec | `/openspec:archive` |

### Daily Workflow

1. **Orient**: `bd ready --json` to see unblocked work
2. **Pick work**: Select highest priority ready issue
3. **Update status**: `bd update <id> --status in_progress`
4. **Implement**: Do the work
5. **Discover**: File new issues: `bd create "Found: <issue>" --discovered-from <id>`
6. **Complete**: `bd close <id> --reason "Implemented"`

### Converting OpenSpec Tasks to Beads

When an OpenSpec change is approved:
```bash
# Create epic for the change
bd create "<change-name>" -t epic -p 1 -l "openspec:<change-name>"

# For each task in tasks.md, create a child issue with FULL CONTEXT
bd create "<task description>" -t task -l "openspec:<change-name>" \
  -d "## Spec Reference
openspec/changes/<change>/spec.md

## Requirements
- <copy key points from spec>

## Acceptance Criteria
- <how to verify done>

## Files to modify
- <specific file paths>"
```

After closing each bead, manually edit tasks.md to mark `[x]`.
When all tasks complete, run `openspec archive <name>`.
```

---

## IDE Integration

```bash
# Claude Code - installs SessionStart/PreCompact hooks
bd setup claude

# Cursor IDE - creates .cursor/rules/beads.mdc
bd setup cursor

# Aider - creates .aider.conf.yml
bd setup aider

# Verify
bd setup claude --check
```

---

## Protected Branches

For repos with protected `main` branch:

```bash
bd init --branch beads-sync
bd daemon --start --auto-commit
```

Beads commits to `beads-sync` branch, merge to `main` via PR when ready.

---

## Resources

- [Beads GitHub](https://github.com/steveyegge/beads)
- [Original Reddit Post](https://www.reddit.com/r/ClaudeCode/comments/1q182tf/testing_cc_with_openspec_and_beads/) — nicoracarlo's workflow
- [Installing bd](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md)
- [Protected Branches](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md)

---

## Next Steps

- Want a simpler approach? See [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md)
- Need spec validation without beads? See [WORKFLOW-SPEC.md](WORKFLOW-SPEC.md)
- Back to main guide: [GUIDE.md](GUIDE.md)
