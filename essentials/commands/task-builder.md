---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <plan-file-path OR issues-file-path>
description: Break down a plan into granular issues and orchestrate iterative implementation (project)
---

Break down implementation plans into trackable issues and orchestrate user-driven iterative implementation. Creates a comprehensive tasks.json file that decomposes the plan into logical, atomic work units with COMPLETE implementation details, code snippets, architectural context, requirements, and constraints embedded in each issue. Issues are fully self-contained so file-editor agents never need to reference the plan. Then manages implementation one issue at a time with full verification.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the tasks file directly, not in chat.

**KEY FEATURE**: Issues extract and embed ALL detail from the plan including:
- Complete code snippets (can be hundreds of lines per file)
- Full implementation details verbatim from plan
- All architectural context and relationships
- All requirements (with R-IDs) and constraints (with C-IDs)
- Testing strategies and risk mitigations
- External documentation and API details

This makes issues completely self-contained for implementation.

## Arguments

**Two modes based on file type:**

1. **DECOMPOSE MODE** - Pass a plan file:
   - `<plan-file-path>`: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
   - Creates tasks.json and starts orchestration

2. **RESUME MODE** - Pass an tasks file:
   - `<issues-file-path>`: Path to existing tasks file (e.g., `.claude/plans/issues-a3f9e.json`)
   - Resumes from where it left off

## Instructions

### Step 1: Parse Arguments and Determine Mode

Parse `$ARGUMENTS` to extract the input file path.

**Mode Detection (based on file extension):**
- If file ends with `.md`: **DECOMPOSE mode** - Create tasks.json from plan and start orchestration
- If file ends with `.json` or contains `issues-`: **RESUME mode** - Load existing tasks.json and resume orchestration

**Validation:**
- Verify input file exists (use Bash: `ls <file-path>`)
- For DECOMPOSE mode: Verify plan status is "READY FOR IMPLEMENTATION"
- For RESUME mode: Verify JSON structure is valid tasks file

### Step 2: Launch Issue Builder in Background

Launch the `task-builder-default` agent **in the background** using the Task tool with `run_in_background: true`:

**For DECOMPOSE+ORCHESTRATE mode:**
```
Break down the implementation plan into granular, trackable issues, then IMMEDIATELY enter the iterative orchestration loop to implement them one by one with user approval.

Plan file: <plan-file-path>
Mode: DECOMPOSE+ORCHESTRATE

## Instructions

PHASE 1: DECOMPOSITION (create tasks.json)

1. PLAN ANALYSIS (COMPREHENSIVE EXTRACTION):
   - Read the plan file completely
   - Extract plan metadata (hash, title, files, requirements, constraints, quality scores)
   - Extract ALL architectural context (Task, Architecture, Relationships, Selected Context)
   - Extract ALL external context (API docs, library details, examples, best practices)
   - Extract ALL implementation notes (patterns, edge cases, guidance)
   - Extract ALL testing strategy details
   - Extract ALL risk analysis and mitigations
   - Build dependency graph of all file changes
   - Identify implementation layers

2. ISSUE DECOMPOSITION WITH FULL DETAIL EMBEDDING:
   - Break plan into logical, atomic issues
   - Strategy: layer-based (one issue per dependency layer) OR file-based OR feature-based
   - For EACH issue, embed COMPLETE details:
     * full_description: Multi-paragraph context (1000-3000 chars)
     * For each file:
       - Complete implementation_details from plan (500-5000+ chars)
       - ALL code_snippets from plan (can be hundreds of lines each)
       - Complete changes_list, purpose, dependencies, provides
     * requirements_addressed: ALL requirements with R-IDs
     * constraints_applicable: ALL constraints with C-IDs
     * architectural_context: Relevant architecture sections
     * implementation_notes: Patterns, guidance from plan
     * testing_strategy: Test requirements for this issue
     * risk_mitigations: Risks and how to mitigate
     * external_context: Relevant API docs and examples
   - Each issue must be:
     - Atomic: Independently implementable (within its layer)
     - Self-Contained: Has ALL detail needed, no plan reference required
     - Testable: Clear verification criteria
     - Reversible: Can be rolled back without breaking others
     - Traceable: Maps to specific plan requirements with IDs

3. CREATE COMPREHENSIVE ISSUES FILE:
   - Write to: .claude/plans/issues-{plan-hash5}.json
   - Use same 5-char hash from plan filename
   - Structure: version, plan_reference, issues array, completion_summary
   - Each issue contains 15+ fields with complete details
   - File-editor agents will receive ALL context from issues, never read plan

4. QUALITY SCORING:
   - Score decomposition on: atomicity, dependency accuracy, requirement coverage, verification clarity, granularity, self-containment
   - Minimum: 40/50 with no dimension <8
   - Revise if score too low

PHASE 2: ORCHESTRATION LOOP (immediately after creating tasks.json)

5. ENTER ORCHESTRATOR LOOP:
   - For each issue (in dependency order):
     a. Present issue to user with AskUserQuestion (options: implement/skip/view details/abort)
     b. If user approves: spawn file-editor-default agents for issue's files
        - Pass COMPLETE context from issue to each file-editor
        - Include: implementation_details, code_snippets, changes_list, purpose,
          dependencies, provides, architectural_context, implementation_notes,
          requirements, constraints, testing_strategy, risk_mitigations, external_context
        - File-editors receive EVERYTHING, never need to read plan
     c. Verify ALL changes completed (CHANGES COMPLETED == TOTAL CHANGES from plan)
     d. Re-dispatch if changes incomplete (with same complete context)
     e. Update tasks.json with completion status
     f. Move to next issue

6. CRITICAL RULES:
   - Create tasks.json THEN immediately start orchestration (don't wait for user)
   - ONE issue at a time (never parallel issue execution)
   - User approval required for EACH issue (use AskUserQuestion)
   - File-editors get ALL details from issue JSON, not from plan
   - Issues are self-contained with complete implementation specs
   - Verify completion before moving to next
   - Update tasks.json after every status change
   - NO state-modifying git commands

Report back with minimal output: issues created, orchestration results, tasks file path.
```

**For RESUME mode:**
```
Resume iterative implementation from existing tasks file.

Issues file: <issues-file-path>
Mode: RESUME

## Instructions

1. LOAD ISSUES FILE:
   - Read the provided tasks file: <issues-file-path>
   - Validate JSON structure and integrity
   - Extract plan_reference to know which plan this came from

2. ANALYZE STATE:
   - Parse completion status (completed/pending/failed/deferred)
   - Identify next issue to implement
   - Validate dependencies are met for next issue
   - Check for blockers

3. GET YOUR BEARINGS:
   - Report to user: "Resuming from [issues-file-path]"
   - Report: "[X] issues completed, [Y] remaining"
   - Report: "Next issue: ISS-XXX [title]"

4. ORCHESTRATOR LOOP:
   - Resume from next incomplete issue
   - Same workflow as DECOMPOSE mode (steps 5a-5f above)
   - Update tasks.json as you progress

5. HANDLE FAILURES:
   - If failed issues block others: ask user how to proceed
   - If all issues blocked: report and stop

Report back with minimal output: resume summary, tasks file path.
```

Use `subagent_type: "task-builder-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the task-builder agent to complete.

The agent will handle the entire orchestration loop internally, presenting issues to the user via AskUserQuestion and spawning file-editor agents as approved.

### Step 4: Report Summary

After the agent completes, provide a minimal summary:

```
## Issue Builder Summary

### Mode: [DECOMPOSE | RESUME]

**Plan**: [plan file path]
**Tasks File**: .claude/plans/tasks-{hash5}.json

### Results

**Total Issues**: [N]
**Completed**: [X] ([%]%)
**Failed**: [Y]
**Deferred**: [Z]
**Pending**: [W]

**Changes Completed**: [X] / [N] ([%]%)
**Requirements Met**: [X] / [N] ([%]%)

### Issues Summary

**Completed:**
- ISS-001: [title] ✓
- ISS-002: [title] ✓

**Failed:**
- ISS-XXX: [title] - [reason]

**Deferred:**
- ISS-YYY: [title]

**Blocked:**
- ISS-ZZZ: [title] - [blocked by ISS-XXX]

### Next Steps

- Review changes: git diff
- Run quality checks (see CLAUDE.md)
- Address failed/deferred issues
- Resume if needed: /task-builder <plan-path> --resume
- Commit when satisfied

**Issues file saved**: .claude/plans/tasks-{hash5}.json
```

## Workflow Diagram

```
/task-builder <plan> [--resume]
    │
    ▼
┌─────────────────────┐
│ Parse arguments     │
│ Determine mode      │
└─────────────────────┘
    │
    ├──[DECOMPOSE]──────────────────────┐
    │                                   │
    │   ┌─────────────────────────────────────────┐
    │   │ Launch task-builder-default            │◄── run_in_background: true
    │   │                                         │
    │   │  1. Read plan                           │
    │   │  2. Build dependency graph              │
    │   │  3. Create tasks.json                  │
    │   │  4. Enter orchestrator loop:            │
    │   │     ├─► Present issue (AskUserQuestion) │
    │   │     ├─► User approves?                  │
    │   │     ├─► Spawn file-editors              │
    │   │     ├─► Verify completion               │
    │   │     ├─► Update tasks.json              │
    │   │     └─► Next issue                      │
    │   └─────────────────────────────────────────┘
    │
    └──[RESUME]─────────────────────────┐
                                        │
        ┌─────────────────────────────────────────┐
        │ Launch task-builder-default            │◄── run_in_background: true
        │                                         │
        │  1. Load tasks-{hash5}.json            │
        │  2. Analyze completion state            │
        │  3. Find next issue                     │
        │  4. Resume orchestrator loop            │
        │     (same as DECOMPOSE steps above)     │
        └─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for agent completion
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report summary      │◄── Minimal output
└─────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file missing | Report error, stop |
| Plan not READY FOR IMPLEMENTATION | Report error, stop |
| Issues file missing (RESUME mode) | Report error, suggest running without --resume |
| Issues file corrupted | Report error, suggest regenerating |
| All issues blocked | Report blockers, ask user to resolve failed issues |
| User aborts orchestration | Save state to tasks.json, report progress |
| File-editor fails | Mark issue as failed, ask user how to proceed |

## Example Usage

```bash
# DECOMPOSE MODE: Create issues from plan and start implementation
/task-builder .claude/plans/oauth2-authentication-a3f9e-plan.md

# RESUME MODE: Resume from existing tasks file (NOTE: Pass the tasks.json, not the plan!)
/task-builder .claude/plans/issues-a3f9e.json

# After interruption or /compact, resume where you left off
/task-builder .claude/plans/issues-7k2m1.json
```

## When to Use Issue Builder vs Direct Editor

**Use Issue Builder (`/task-builder`) when:**
- Complex plans with >5 files
- Unclear dependencies between files
- You want incremental, reviewable progress
- You might need to pause and resume
- You want granular control over what gets implemented

**Use Direct Editor (`/editor`) when:**
- Simple plans with <5 files
- All files independent or dependencies clear
- You want batch implementation
- Single execution session expected

## Integration with Other Commands

Issue Builder works with plans created by:
- `/planner` - Implementation plans
- `/bug-scout` - Bug fix plans (if complex multi-file fixes)
- `/code-quality` - Quality improvement plans (if many files)

## Tasks File Structure

The tasks file provides:
- **Granular tracking**: Progress at issue level, not just file level
- **Dependency management**: Visual graph prevents implementation ordering mistakes
- **Resume capability**: If interrupted, resume exactly where you left off
- **Requirement traceability**: Every issue maps to specific plan requirements with R-IDs
- **Audit trail**: Complete history of what was implemented when
- **Self-contained specs**: Each issue has COMPLETE implementation details
- **No plan dependency**: File-editors never need to reference the plan file
- **Comprehensive context**: Issues embed all code snippets, architectural context, requirements, constraints, testing strategy, and risk mitigations

**Issue Size**: Issues are intentionally large and comprehensive (often 5-50KB each)
to provide complete implementation specifications. This eliminates the need for
file-editor agents to read or parse the plan file.

Located at: `.claude/plans/issues-{plan-hash5}.json`
