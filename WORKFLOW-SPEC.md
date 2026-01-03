# 4-Stage Workflow: Spec-Driven with SpecKit or OpenSpec

[Spec Kit](https://github.com/github/spec-kit) and [OpenSpec](https://github.com/Fission-AI/OpenSpec) provide structured specification workflows with human validation checkpoints before implementation.

**Best for:** Medium features needing stakeholder review, complex features with architectural decisions, team collaboration.

---

## Why Spec-Driven?

| Approach | Benefit |
|----------|---------|
| **Direct implementation** | Fast but no validation checkpoint |
| **Spec-driven** | Human reviews specs before any code is written |
| **With validation** | Catches misunderstandings early, reduces rework |

---

## The 4-Stage Workflow

```
┌───────────────────────────────────────────────────────────────────────────┐
│                       PLANNING PHASE (Human Control)                      │
│                                                                           │
│  ┌───────────────────┐   ┌───────────────────┐   ┌─────────────────────┐  │
│  │ STAGE 1: ANALYSIS │   │ STAGE 2: PLAN     │   │ STAGE 3: SPEC &     │  │
│  │                   │   │                   │   │ VALIDATION          │  │
│  │ "ultrathink and   │ → │ /plan-creator     │ → │                     │  │
│  │  traverse..."     │   │                   │   │ SpecKit:            │  │
│  │                   │   │ Agent: plan-      │   │  /speckit.specify   │  │
│  │                   │   │ creator-default   │   │  /speckit.plan      │  │
│  │                   │   │                   │   │  /speckit.tasks     │  │
│  │                   │   │                   │   │                     │  │
│  │                   │   │                   │   │ OpenSpec:           │  │
│  │                   │   │                   │   │  /proposal-creator  │  │
│  └───────────────────┘   └───────────────────┘   └─────────────────────┘  │
│                                                          │                │
│                              NO ←── "Is spec correct?" ──┴──→ YES         │
│                              ↓                                 ↓          │
│                          iterate                           proceed        │
└───────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ↓
┌───────────────────────────────────────────────────────────────────────────┐
│                           EXECUTION PHASE                                 │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ STAGE 4: IMPLEMENT                                                  │  │
│  │                                                                     │  │
│  │ SpecKit:                        │  OpenSpec with /spec-loop:        │  │
│  │  • Work through .specify/tasks/ │  ┌─────────────────────────────┐  │  │
│  │  • Each task is self-contained  │  │ Loop (via stop hook):       │  │  │
│  │                                 │  │  1. Read tasks.md           │  │  │
│  │                                 │  │  2. Implement next task     │  │  │
│  │                                 │  │  3. Mark [x] in tasks.md    │  │  │
│  │                                 │  │  4. Repeat until all [x]    │  │  │
│  │                                 │  └─────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
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

## Stage 2: Plan Creation

Create an architectural plan with `/plan-creator`:

```
/plan-creator Add user authentication with JWT tokens
```

---

## Stage 3: Spec & Validation (CRITICAL)

Generate and validate specifications:

- **SpecKit:** `/speckit.specify` → `/speckit.plan` → `/speckit.tasks`
- **OpenSpec:** `/proposal-creator` (from plan file) or `/openspec:proposal` (manual)

Then thoroughly validate. **Skipping = trouble.**

1. Read the generated specs - Understand what Claude understood
2. Check for misunderstandings - Does it match your mental model?
3. Verify completeness - Are edge cases covered?
4. Fix until satisfied - Iterate on the spec before any code

> "Skipping this validation part is like asking for troubles." - nicoracarlo

---

## Stage 4: Execution

Implement the spec with iterative loops:

- **SpecKit:** Work through `.specify/tasks/` breakdown
- **OpenSpec:** `/spec-loop <change-id>` iterates until all tasks complete

---

## SpecKit Workflow

```bash
# Initialize in your project
npx specify init

# Generate spec from your plan
/speckit.specify   # Creates .specify/spec.md

# Create technical plan
/speckit.plan      # Creates .specify/plan.md

# Generate tasks
/speckit.tasks     # Creates task breakdown
```

**Generated artifacts:**
- `.specify/spec.md` - Product specification with user stories and requirements
- `.specify/plan.md` - Technical implementation plan
- `.specify/tasks/` - Task breakdown for implementation

---

## OpenSpec Workflow

```bash
# Initialize in your project
openspec init

# Create proposal from plan file (recommended)
/proposal-creator .claude/plans/feature-xyz-plan.md

# Or create proposal from description
/proposal-creator Add OAuth2 authentication with Google

# Or create manually
/openspec:proposal

# Implement with iterative loop
/spec-loop <change-id>

# The loop will:
# 1. Read proposal.md, design.md, tasks.md
# 2. Create todos from tasks.md
# 3. Implement each task
# 4. Mark [x] in tasks.md when complete
# 5. Continue until all tasks are [x]

# Archive when complete
/openspec:archive    # Archives completed changes
```

**Generated artifacts:**
- `openspec/changes/<name>/proposal.md` - Change proposal document
- `openspec/changes/<name>/tasks.md` - Implementation tasks (synced by `/spec-loop`)
- `openspec/changes/<name>/specs/` - Spec deltas showing requirement changes

### How /spec-loop Works

The `/spec-loop` command provides the same iterative benefits as `/implement-loop`:

1. **Reads the spec** - Parses proposal.md, design.md (if exists), and tasks.md
2. **Creates todos** - Each task in tasks.md becomes a tracked todo
3. **Implements tasks** - Works through tasks sequentially
4. **Syncs tasks.md** - Marks `[x]` in tasks.md as each task completes
5. **Loops until done** - Continues until all tasks are marked `[x]`

**Stop the loop:**
```bash
/cancel-spec-loop    # Graceful stop, preserves progress in tasks.md
```

### Context Chain: Plan → Spec

When using `/proposal-creator` from a plan file, a chain of back-references is created:

```
Plan (SOURCE OF TRUTH)
 │
 │  Contains: Full implementation code, exit criteria, migration patterns
 │
 └──▶ OpenSpec
       ├── proposal.md: plan_reference (for recovery)
       ├── design.md: Reference Implementation (FULL code from plan)
       ├── tasks.md: Exit Criteria (EXACT commands from plan)
       └── specs/*.md: Requirements with scenarios
```

**Context Recovery:** When context is compacted during `/spec-loop`:
1. Read tasks.md to see what's done/pending
2. Find `plan_reference` in proposal.md
3. Read source plan for full implementation code and exit criteria

---

## When to Use Which

| Situation | Tool | Reason |
|-----------|------|--------|
| GitHub-centric workflow | SpecKit | Integrates with GitHub ecosystem |
| Need spec deltas/diffs | OpenSpec | Shows exactly what requirements change |
| Team collaboration | Either | Both support shared specs |
| Quick prototyping | OpenSpec | Lighter weight |
| Enterprise projects | SpecKit | More structured artifacts |

---

## Scaling Up: When Specs Aren't Enough

If your spec-driven implementation starts showing hallucinations or context issues:

| Symptom | Solution |
|---------|----------|
| AI starts making things up mid-implementation | Plan is too large for context |
| Loses track of what's done | Need persistent task tracking |
| Multi-session work needed | Beads provides session-independent memory |

**Solution:** Add Beads to the workflow. See [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md).

---

## Next Steps

- Plan too large for one session? See [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md)
- Want the simpler approach? See [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md)
- Back to main guide: [GUIDE.md](GUIDE.md)
