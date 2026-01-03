---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep
argument-hint: [plan-path-or-description]
description: Convert plans, context, or descriptions into validated OpenSpec proposals (project)
---

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
│  │     • DO NOT SUMMARIZE - copy verbatim                  │  │
│  │                                                         │  │
│  │  2. EXPLORE CODEBASE                                    │  │
│  │     • Read project.md, existing specs                   │  │
│  │     • Search related code with rg/ls                    │  │
│  │                                                         │  │
│  │  3. CREATE PROPOSAL.MD                                  │  │
│  │     • plan_reference (path to source plan)              │  │
│  │     • Full scope tracking (all items from plan)         │  │
│  │     • In scope / deferred items                         │  │
│  │                                                         │  │
│  │  4. CREATE DESIGN.MD                                    │  │
│  │     • plan_reference                                    │  │
│  │     • Reference Implementation (FULL code from plan)    │  │
│  │     • Migration Patterns (COMPLETE before/after)        │  │
│  │     • Interfaces (EXACT, unchanged)                     │  │
│  │     • ASCII diagrams (EXACT copies)                     │  │
│  │                                                         │  │
│  │  5. CREATE TASKS.MD                                     │  │
│  │     • plan_reference                                    │  │
│  │     • Exit Criteria (EXACT commands from plan)          │  │
│  │     • Manual verification steps                         │  │
│  │                                                         │  │
│  │  6. CREATE SPECS/**/*.MD                                │  │
│  │     • plan_reference                                    │  │
│  │     • R1, R2, R3 → scenarios (2+ per requirement)       │  │
│  │                                                         │  │
│  │  7. VALIDATE                                            │  │
│  │     • openspec validate <id> --strict                   │  │
│  │     • Verify plan content preserved                     │  │
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

## Input Mapping

How different inputs map to OpenSpec structure:

| Input Section | → OpenSpec File | Content |
|---------------|-----------------|---------|
| Plan path | proposal.md | plan_reference (for recovery) |
| Summary/Task | proposal.md | Overview, motivation |
| Architecture | design.md | Decisions, patterns |
| Implementation Steps | tasks.md | Ordered task list |
| Requirements | specs/*/spec.md | ADDED/MODIFIED/REMOVED |
| Files to Modify | tasks.md + specs | File references |
| Exit Criteria | tasks.md | Verification steps |

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

## Integration with Workflows

This command bridges the gap between planning and OpenSpec:

```
/plan-creator <task>
    │
    ▼
.claude/plans/*-plan.md
    │
    ▼
/proposal-creator <plan-path>    ← THIS COMMAND
    │
    ▼
openspec/changes/<id>/
    │
    ▼
/openspec:apply <id>
```
