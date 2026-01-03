---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep
argument-hint: <spec-path>
description: Convert OpenSpec/SpecKit specs to self-contained Beads issues (project)
---

Convert OpenSpec or SpecKit specifications into self-contained Beads issues, automating Stage 4 of the 5-stage workflow.

**IMPORTANT**: Keep orchestrator output minimal. User reviews beads with `bd ready` directly.

## Arguments

Required:
- `<spec-path>` - Path to OpenSpec change directory or SpecKit .specify directory
  - OpenSpec: `openspec/changes/<change-name>/`
  - SpecKit: `.specify/`

## Instructions

### Step 1: Validate Environment

```bash
# Check bd is installed
bd version

# Check bd is initialized
bd ready 2>&1 | head -1
```

If not installed: "Install bd: https://github.com/steveyegge/beads"
If not initialized: "Run: bd init"

### Step 2: Detect Spec Type and Read ALL Files

**CRITICAL:** Read ALL spec files to extract full context for self-contained beads.

**For OpenSpec** (path contains `openspec/changes/`):
```bash
# Read in order - each provides different context
cat <path>/proposal.md      # Overview, motivation
cat <path>/design.md        # Technical decisions, CODE PATTERNS
cat <path>/tasks.md         # Phases and task list
# IMPORTANT: specs/*.md contain detailed requirements!
find <path>/specs -name "*.md" -exec cat {} \;
```

**For SpecKit** (path is `.specify/` or contains `.specify`):
```bash
cat .specify/spec.md        # User stories, requirements
cat .specify/plan.md        # Technical approach
cat .specify/tasks/*.md     # Individual task details
```

**Extract from each file:**
- Change/spec name
- Overview/summary
- **Requirements (copy verbatim, don't summarize)**
- **Code patterns/snippets from design.md**
- Implementation tasks with phases
- Acceptance criteria
- Files to modify with line numbers if known
- Dependencies between tasks

### Step 3: Launch Agent

Launch `beads-creator-default` in background:

```
Convert spec to Beads issues with full context chain.

Spec Type: <openspec or speckit>
Spec Path: <path>
Change Name: <extracted name>
Plan Reference: <plan_reference from proposal.md - EXTRACT THIS FIRST>

## Spec Content (with plan back-references)

<proposal.md content - includes plan_reference>
<design.md content - includes Reference Implementation, Migration Patterns>
<tasks.md content - includes Exit Criteria>
<specs/*.md content - includes requirements with scenarios>

## CRITICAL: Context Chain

Each bead MUST include BOTH:
- **Spec Reference**: Path to specs/*.md for requirements
- **Plan Reference**: Path to source plan for full implementation code

Each bead MUST include:
- **Requirements**: COPIED verbatim from specs/*.md (never "see spec")
- **Reference Implementation**: FULL code from design.md
- **Migration Patterns**: Before/after from design.md (if applicable)
- **Exit Criteria**: EXACT commands from tasks.md
- **Acceptance Criteria**: Testable conditions

## Process

1. EXTRACT PLAN REFERENCE - Get plan_reference from proposal.md
2. CREATE EPIC - Include context chain (spec + plan refs), Exit Criteria
3. PARSE TASKS - Extract tasks with numbers from tasks.md
4. CREATE BEADS - Each with dual back-references, full implementation code
5. SET DEPENDENCIES - Link related tasks
6. CREATE MAPPING - .beads-mapping.json with plan_reference
7. VERIFY - Run bd ready, verify context chain

Return:
EPIC_ID: <id>
PLAN_REFERENCE: <plan-path>
SPEC_PATH: <spec-path>
TASKS_CREATED: <count>
READY_COUNT: <count with no blockers>
STATUS: IMPORTED
```

Use `subagent_type: "beads-creator-default"` and `run_in_background: true`.

Wait with TaskOutput (block: true).

### Step 4: Report Result

```
===============================================================
BEADS CREATED FROM SPEC
===============================================================

Spec: <change-name>
Type: <OpenSpec or SpecKit>
Plan Reference: <plan-path>

Epic: <epic-id> - <title>
Tasks Created: <count>
Ready to Work: <count>

Context Chain:
  Bead → Spec → Plan (source of truth)

Each bead includes:
  • Spec Reference (requirements, scenarios)
  • Plan Reference (full implementation code)
  • Reference Implementation (FULL code from design.md)
  • Exit Criteria (EXACT commands from tasks.md)

===============================================================
NEXT STEPS
===============================================================

# See what's ready to implement
bd ready

# Start implementing with loop
/beads-loop --label openspec:<change-name>

# Context recovery (if needed)
bd show <id>           # Self-contained bead
cat <spec-path>        # Requirements and scenarios
cat <plan-path>        # Full implementation code

===============================================================
```

## Workflow Diagram

```
/beads-creator <spec-path>
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: VALIDATE                                              │
│                                                               │
│  • Check bd installed and initialized                         │
│  • Detect spec type (OpenSpec or SpecKit)                     │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: READ SPEC FILES (with plan back-references)           │
│                                                               │
│  OpenSpec:                    Extract:                        │
│   • proposal.md ─────────────▶ plan_reference                 │
│   • design.md ───────────────▶ Reference Implementation       │
│   • tasks.md ────────────────▶ Exit Criteria                  │
│   • specs/**/*.md ───────────▶ Requirements + Scenarios       │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: LAUNCH AGENT                                          │
│                                                               │
│  Agent: beads-creator-default                                 │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES (with context chain):                      │  │
│  │                                                         │  │
│  │  1. EXTRACT PLAN REFERENCE                              │  │
│  │     • Get plan_reference from proposal.md               │  │
│  │     • Enables: Bead → Spec → Plan chain                 │  │
│  │                                                         │  │
│  │  2. CREATE EPIC                                         │  │
│  │     • Include spec_path + plan_reference                │  │
│  │     • Include Exit Criteria (EXACT commands)            │  │
│  │     • Save epic ID for parent reference                 │  │
│  │                                                         │  │
│  │  3. CREATE CHILD BEADS (Self-Contained + Dual Refs)     │  │
│  │     • Use --parent <epic-id> for hierarchy              │  │
│  │     • Include Spec Reference + Plan Reference           │  │
│  │     • Copy requirements verbatim from specs             │  │
│  │     • Include Reference Implementation (FULL code)      │  │
│  │     • Include Migration Patterns (before/after)         │  │
│  │     • Include Exit Criteria (EXACT commands)            │  │
│  │     • Implementable with ONLY the description           │  │
│  │                                                         │  │
│  │  4. SET DEPENDENCIES                                    │  │
│  │     • Use --deps blocks:<id> inline                     │  │
│  │                                                         │  │
│  │  5. CREATE MAPPING FILE                                 │  │
│  │     • .beads-mapping.json with plan_reference           │  │
│  │     • Enables context recovery                          │  │
│  │                                                         │  │
│  │  6. VERIFY                                              │  │
│  │     • bd list -l "openspec:<change>"                    │  │
│  │     • Verify context chain in each bead                 │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 4: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Epic ID, plan_reference, spec_path                         │
│  • Task count with context chain verified                     │
│  • Next: /beads-loop or context recovery commands             │
└───────────────────────────────────────────────────────────────┘

## Context Chain

Plan (SOURCE OF TRUTH)
 │
 └──▶ OpenSpec (proposal.md has plan_reference)
       │
       └──▶ Beads (each has spec_ref + plan_ref)
             │
             └──▶ /beads-loop (recovers from plan if needed)
```

## Self-Contained Bead Rule

Each bead MUST be self-contained with dual back-references. An agent must implement it with ONLY the bead description.

**Template for each bead:**
```markdown
## Context Chain

**Spec Reference**: openspec/changes/<change>/specs/<area>/spec.md
**Plan Reference**: .claude/plans/<plan>-plan.md
**Task**: <N.N from tasks.md>

> For full context recovery, read the source plan.
> This bead is self-contained but references provide additional context.

## Requirements

<COPIED from specs/*.md - NEVER "see spec">
- <requirement 1 with full text>
- <requirement 2 with full text>

### Scenario: <from spec>
- GIVEN <context>
- WHEN <action>
- THEN <outcome>

## Reference Implementation

> From design.md Reference Implementation section

\`\`\`<language>
<FULL implementation code - DO NOT SUMMARIZE>
\`\`\`

## Migration Pattern (if applicable)

**BEFORE**:
\`\`\`<language>
<exact before code>
\`\`\`

**AFTER**:
\`\`\`<language>
<exact after code>
\`\`\`

## Acceptance Criteria

- [ ] <testable condition from requirements>
- [ ] <verification step>

## Exit Criteria

\`\`\`bash
<EXACT commands from tasks.md>
\`\`\`

## Files to Modify

- `<exact file path>`:<line numbers if known>
```

**Litmus test:** Could someone implement this with ONLY the bd description? If not, add more context.

**Context recovery:** If context is lost during `/beads-loop`:
1. `bd show <id>` - self-contained bead
2. Read spec_reference - requirements and scenarios
3. Read plan_reference - full implementation code

## Example Usage

```bash
# OpenSpec change
/beads-creator openspec/changes/refactor-bullmq-worker-reliability/

# SpecKit spec
/beads-creator .specify/

# Then start implementing
/beads-loop --label openspec:refactor-bullmq-worker-reliability

# Or manual execution
bd ready
bd update <id> --status in_progress
# ... implement ...
bd close <id> --reason "Completed"
```

## Error Handling

| Scenario | Action |
|----------|--------|
| bd not installed | "Install bd: https://github.com/steveyegge/beads" |
| bd not initialized | "Run: bd init" |
| Spec path not found | Report error, suggest correct path |
| No tasks.md found | Report error, spec incomplete |
| Empty tasks list | Report warning, nothing to import |
