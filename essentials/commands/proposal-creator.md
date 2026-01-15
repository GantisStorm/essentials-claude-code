---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep
argument-hint: "[plan-path-or-description]"
description: Convert plans, context, or descriptions into validated OpenSpec proposals (project)
model: opus
context: fork
---

# Proposal Creator

Convert architectural plans, current context, or task descriptions into validated OpenSpec change proposals.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the OpenSpec files directly.

## Arguments

Takes **any input**:
- Plan file path: `.claude/plans/auth-feature-3k7f2-plan.md`
- Task description: `"Add OAuth2 authentication with Google login"`
- No argument: uses current conversation context

If no input provided, prompts user to describe the change.

## Instructions

### Step 1: Validate Environment

```bash
# Check openspec is installed
openspec version 2>&1 | head -1

# Check openspec is initialized
ls openspec/project.md 2>/dev/null && echo "OpenSpec initialized" || echo "Not initialized"
```

If not installed: "Install OpenSpec: https://github.com/Fission-AI/OpenSpec"
If not initialized: "Run: openspec init"

### Step 2: Detect Input Type and Parse

**CRITICAL:** Determine input type and extract all relevant context.

**If plan file path provided** (matches `.claude/plans/*.md` or similar):
```bash
# Read the full plan file
cat <plan-path>
```

Extract from plan:
- Task description → proposal.md overview
- Architecture section → design.md
- Implementation steps → tasks.md
- Requirements → specs/*/spec.md
- Files to modify → technical context

**If task description provided** (text without file path):
Use the description as the basis for the proposal. The agent will explore the codebase to gather context.

**If no input** (empty $ARGUMENTS):
Ask user: "What change would you like to propose?"

### Step 3: Determine Change ID

Generate a unique verb-led change-id:
- Use kebab-case
- Start with action verb: `add-`, `update-`, `fix-`, `refactor-`, `remove-`
- Be descriptive but concise
- Examples: `add-oauth2-authentication`, `fix-session-timeout`, `refactor-payment-processing`

### Step 4: Launch Agent

Launch `proposal-creator-default` in background:

```
Create OpenSpec proposal from input with full context.

Input Type: <plan-file | description | context>
Plan Path: <path to plan file - REQUIRED if plan-file input>
Change ID: <generated change-id>

## Source Content (if plan file)

<full plan content - COMPLETE, not excerpted>

## CRITICAL: Preserve All Plan Details

When converting a plan, you MUST preserve:
- **Reference Implementation**: Full code from plan → design.md (COMPLETE, not summarized)
- **Exit Criteria**: Exact verification commands → tasks.md (VERBATIM)
- **Migration Patterns**: Before/after code → design.md (COMPLETE)
- **TypeScript Interfaces**: Exact types → design.md (UNCHANGED)
- **ASCII Diagrams**: Architecture diagrams → design.md (EXACT copy)
- **Plan Reference**: Path to source plan → ALL files (for recovery)
- **Risk Analysis**: Technical/Integration risks → design.md, Rollback Strategy → design.md
- **Stakeholders**: Primary/Secondary → proposal.md Impact section
- **Testing Strategy**: Unit/Integration tests → tasks.md + specs scenarios
- **Success Metrics**: Functional criteria, quality metrics → tasks.md
- **Post-Implementation Verification**: Automated checks, validation → tasks.md

## Process

1. ANALYZE INPUT - Extract ALL sections from plan (use PLAN EXTRACTION CHECKLIST)
2. EXPLORE CODEBASE - Understand current implementation
3. CREATE PROPOSAL - proposal.md with plan_reference, motivation, full scope tracking
4. CREATE DESIGN - design.md with Reference Implementation (FULL code), Migration Patterns
5. CREATE TASKS - tasks.md with Exit Criteria (EXACT commands from plan)
6. CREATE SPECS - specs/*/spec.md with R1, R2, R3 → scenarios
7. VALIDATE - openspec validate <change-id> --strict
8. VERIFY - Check all plan content preserved

Return:
CHANGE_ID: <id>
OUTPUT_PATH: openspec/changes/<id>/
PLAN_REFERENCE: <plan-path>
FILES_CREATED: <count>
VALIDATION: PASSED|FAILED
STATUS: CREATED
```

Use `subagent_type: "proposal-creator-default"` and `run_in_background: true`.

Wait with TaskOutput (block: true).

### Step 5: Report Result

```
===============================================================
OPENSPEC PROPOSAL CREATED
===============================================================

Change: <change-id>
Path: openspec/changes/<change-id>/
Plan Reference: <plan-path> (if from plan)

Files Created:
  • proposal.md - Overview, motivation, plan_reference
  • design.md - Decisions, Reference Implementation, Migration Patterns
  • tasks.md - Implementation steps, Exit Criteria (exact commands)
  • specs/<area>/spec.md - Requirements with scenarios

Validation: PASSED

Plan Content Preserved:
  • Reference Implementation: FULL code in design.md
  • Exit Criteria: EXACT commands in tasks.md
  • Migration Patterns: COMPLETE before/after in design.md
  • Interfaces: UNCHANGED TypeScript types
  • plan_reference: In all files for recovery
  • Risk Analysis: Technical/Integration risks in design.md
  • Rollback Strategy: Decision tree in design.md
  • Stakeholders: Primary/Secondary in proposal.md Impact
  • Testing Strategy: Unit/Integration tests in tasks.md + specs
  • Success Metrics: Functional/Quality/Acceptance in tasks.md
  • Post-Implementation: Verification steps in tasks.md

===============================================================
NEXT STEPS
===============================================================

1. Review: openspec show <change-id>
2. Convert to beads: /beads-creator openspec/changes/<change-id>/
3. Or implement directly: /spec-loop <change-id>

===============================================================
```

## Workflow Diagram

```
/proposal-creator [input]
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: VALIDATE ENVIRONMENT                                  │
│                                                               │
│  • Check openspec installed                                   │
│  • Check openspec initialized                                 │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: DETECT INPUT TYPE                                     │
│                                                               │
│  Plan file path:          Description:        Empty:          │
│   • Read FULL plan         • Use as basis      • Ask user     │
│   • Extract ALL sections   • Explore codebase                 │
│   • Save plan_path         • No plan_ref                      │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: LAUNCH AGENT                                          │
│                                                               │
│  Agent: proposal-creator-default                              │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES (with plan back-references):               │  │
│  │                                                         │  │
│  │  1. ANALYZE INPUT (EXTRACT EVERYTHING)                  │  │
│  │     • Use PLAN EXTRACTION CHECKLIST                     │  │
│  │     • Extract ALL code, diagrams, exit criteria         │  │
│  │     • Extract NEW sections: Risk Analysis, Testing      │  │
│  │       Strategy, Success Metrics, Post-Implementation    │  │
│  │     • DO NOT SUMMARIZE - copy verbatim                  │  │
│  │                                                         │  │
│  │  2. EXPLORE CODEBASE                                    │  │
│  │     • Read project.md, existing specs                   │  │
│  │     • Search related code with rg/ls                    │  │
│  │                                                         │  │
│  │  3. CREATE PROPOSAL.MD                                  │  │
│  │     • plan_reference (path to source plan)              │  │
│  │     • Status (READY FOR IMPLEMENTATION)                 │  │
│  │     • Full scope tracking (all items from plan)         │  │
│  │     • In scope / deferred items                         │  │
│  │     • Stakeholders in Impact section                    │  │
│  │                                                         │  │
│  │  4. CREATE DESIGN.MD                                    │  │
│  │     • plan_reference                                    │  │
│  │     • Mode (informational vs directional)               │  │
│  │     • Reference Implementation (FULL code from plan)    │  │
│  │     • Migration Patterns (COMPLETE before/after)        │  │
│  │     • Interfaces (EXACT, unchanged)                     │  │
│  │     • ASCII diagrams (EXACT copies)                     │  │
│  │     • Risk Analysis (Technical/Integration Risks)       │  │
│  │     • Rollback Strategy (with decision tree)            │  │
│  │                                                         │  │
│  │  5. CREATE TASKS.MD                                     │  │
│  │     • plan_reference                                    │  │
│  │     • Exit Criteria (EXACT commands from plan)          │  │
│  │     • Manual verification steps                         │  │
│  │     • Testing Strategy (Unit/Integration/Existing)      │  │
│  │     • Success Metrics (Functional/Quality/Acceptance)   │  │
│  │     • Post-Implementation Verification                  │  │
│  │                                                         │  │
│  │  6. CREATE SPECS/**/*.MD                                │  │
│  │     • plan_reference                                    │  │
│  │     • R1, R2, R3 → scenarios (2+ per requirement)       │  │
│  │     • Test scenarios from Testing Strategy              │  │
│  │                                                         │  │
│  │  7. VALIDATE                                            │  │
│  │     • openspec validate <id> --strict                   │  │
│  │     • Verify plan content preserved                     │  │
│  │     • Verify new format sections extracted              │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 4: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Change ID, path, plan_reference                            │
│  • Files created with plan content preserved                  │
│  • Validation status                                          │
│  • Next: /beads-creator or /spec-loop                         │
└───────────────────────────────────────────────────────────────┘

## Chain of Back-References

Plan (SOURCE OF TRUTH)
 │
 ├──▶ proposal.md: plan_reference → enables recovery
 │
 ├──▶ design.md: plan_reference + Reference Implementation
 │    (FULL code from plan, not summarized)
 │
 ├──▶ tasks.md: plan_reference + Exit Criteria
 │    (EXACT verification commands from plan)
 │
 └──▶ specs/*.md: plan_reference + requirements line numbers
```

## Error Handling

| Scenario | Action |
|----------|--------|
| OpenSpec not installed | "Install OpenSpec: https://github.com/Fission-AI/OpenSpec" |
| OpenSpec not initialized | "Run: openspec init" |
| Plan file not found | Report error, suggest correct path |
| Empty input | Ask user for description |
| Validation fails | Report issues, agent attempts to fix |
| Change ID exists | Append suffix: `add-auth-2` |

## Example Usage

```bash
# From architectural plan
/proposal-creator .claude/plans/auth-feature-3k7f2-plan.md

# From description
/proposal-creator Add OAuth2 authentication with Google login

# From current context (after discussing feature)
/proposal-creator

# Then continue with OpenSpec workflow
openspec show add-oauth2-authentication
/openspec:apply add-oauth2-authentication
```

## Input Mapping

How different inputs map to OpenSpec structure:

| Input Section | → OpenSpec File | Content |
|---------------|-----------------|---------|
| Plan path | proposal.md | plan_reference (for recovery) |
| Status/Mode | proposal.md / design.md | Plan status, implementation mode |
| Summary/Task | proposal.md | Overview, motivation |
| Architecture | design.md | Decisions, patterns |
| Implementation Steps | tasks.md | Ordered task list |
| Requirements | specs/*/spec.md | ADDED/MODIFIED/REMOVED |
| Files to Modify | tasks.md + specs | File references |
| Exit Criteria | tasks.md | Verification steps |
| Risk Analysis | design.md | Technical/Integration risks, rollback strategy |
| Stakeholders | proposal.md | Impact section (primary/secondary) |
| Testing Strategy | tasks.md + specs | Unit/Integration tests, existing tests to update |
| Success Metrics | tasks.md | Functional criteria, quality metrics, acceptance checklist |
| Post-Implementation | tasks.md | Automated checks, validation steps, stakeholder notification |

## Auto-Decomposition

The agent **automatically** decomposes large plans - no user prompt needed.

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Subsystems | >2 unrelated areas | Auto-split by subsystem |
| Total lines | >2000 lines | Auto-split by feature |
| Dependencies | Complex ordering | Auto-split with depends_on |

### Decomposition Output

When the agent auto-decomposes a large plan:
```
===============================================================
OPENSPEC PROPOSALS CREATED (DECOMPOSED)
===============================================================

Parent Plan: .claude/plans/large-feature-plan.md

Proposals Created:
  1. add-auth-backend (openspec/changes/add-auth-backend/)
     - Scope: Authentication service, JWT handling
     - Tasks: 5
  2. add-auth-frontend (openspec/changes/add-auth-frontend/)
     - Scope: Login UI, session management
     - Tasks: 4
     - Depends on: add-auth-backend
  3. add-auth-tests (openspec/changes/add-auth-tests/)
     - Scope: Integration tests, E2E tests
     - Tasks: 3
     - Depends on: add-auth-backend, add-auth-frontend

Dependency Graph:
  add-auth-backend ─┬─▶ add-auth-frontend ─┬─▶ add-auth-tests
                    └───────────────────────┘

Next Steps (choose one):

Option A - Beads (recommended for multi-spec):
  /beads-creator openspec/changes/add-auth-backend/ openspec/changes/add-auth-frontend/ openspec/changes/add-auth-tests/
  /beads-loop

Option B - Sequential spec-loop:
  /spec-loop add-auth-backend
  /spec-loop add-auth-frontend
  /spec-loop add-auth-tests

===============================================================
```

## Step Mode (Default)

Step mode pauses after creating proposal(s) for human review.

**After creating proposal(s), you MUST use AskUserQuestion to pause.**

```
Use AskUserQuestion with:
- question: "Proposal(s) created. What would you like to do?"
- header: "Next step"
- options:
  - label: "Continue (Recommended)"
    description: "Proceed to /spec-loop or /beads-creator"
  - label: "Stop"
    description: "End here for manual review"
```

Use `--auto` flag to skip pauses and proceed directly to next step.

## Integration with Workflows

This command bridges the gap between planning and OpenSpec. Works with plans from **any planner**:

```
/plan-creator <task>           ┐
/bug-plan-creator <error>      ├─▶ .claude/plans/*-plan.md
/code-quality-plan-creator     ┘
    │
    ▼
/proposal-creator <plan-path>    ← THIS COMMAND
    │
    ├─── [small/medium] ────────▶ Single proposal
    │                                  │
    └─── [large: AUTO-DECOMPOSE] ──▶ Multiple proposals
                                       │
    ▼                                  ▼
openspec/changes/<id>/          openspec/changes/<id-1>/
    │                           openspec/changes/<id-2>/
    ▼                                  │
/spec-loop <id>    or    /beads-creator → /beads-loop
```
