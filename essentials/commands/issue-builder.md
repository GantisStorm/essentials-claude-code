---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <plan-file-path> [--resume]
description: Break down a plan into granular issues and orchestrate iterative implementation (project)
---

Break down implementation plans into trackable issues and orchestrate user-driven iterative implementation. Creates a comprehensive issues.json file that decomposes the plan into logical, atomic work units with COMPLETE implementation details, code snippets, architectural context, requirements, and constraints embedded in each issue. Issues are fully self-contained so file-editor agents never need to reference the plan. Then manages implementation one issue at a time with full verification.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the issues file directly, not in chat.

**KEY FEATURE**: Issues extract and embed ALL detail from the plan including:
- Complete code snippets (can be hundreds of lines per file)
- Full implementation details verbatim from plan
- All architectural context and relationships
- All requirements (with R-IDs) and constraints (with C-IDs)
- Testing strategies and risk mitigations
- External documentation and API details

This makes issues completely self-contained for implementation.

## Arguments

- **plan-file-path**: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
- **--resume** (optional): Resume from existing issues file instead of creating new issues.json

## Instructions

### Step 1: Parse Arguments and Determine Mode

Parse `$ARGUMENTS` to extract:
1. Plan file path
2. Mode flag (--resume or default to decompose+orchestrate)

**Mode Detection:**
- If `--resume` flag present: RESUME mode - Load existing `issues-{hash5}.json` and resume orchestration
- Otherwise: DECOMPOSE+ORCHESTRATE mode - Create issues.json THEN automatically enter orchestration loop

**Validation:**
- Verify plan file exists (use Bash: `ls <plan-path>`)
- For DECOMPOSE mode: Verify plan status is "READY FOR IMPLEMENTATION"
- For RESUME mode: Verify `issues-{hash5}.json` exists for this plan

### Step 2: Launch Issue Builder in Background

Launch the `issue-builder-default` agent **in the background** using the Task tool with `run_in_background: true`:

**For DECOMPOSE+ORCHESTRATE mode:**
```
Break down the implementation plan into granular, trackable issues, then IMMEDIATELY enter the iterative orchestration loop to implement them one by one with user approval.

Plan file: <plan-file-path>
Mode: DECOMPOSE+ORCHESTRATE

## Instructions

PHASE 1: DECOMPOSITION (create issues.json)

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

PHASE 2: ORCHESTRATION LOOP (immediately after creating issues.json)

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
     e. Update issues.json with completion status
     f. Move to next issue

6. CRITICAL RULES:
   - Create issues.json THEN immediately start orchestration (don't wait for user)
   - ONE issue at a time (never parallel issue execution)
   - User approval required for EACH issue (use AskUserQuestion)
   - File-editors get ALL details from issue JSON, not from plan
   - Issues are self-contained with complete implementation specs
   - Verify completion before moving to next
   - Update issues.json after every status change
   - NO state-modifying git commands

Report back with minimal output: issues created, orchestration results, issues file path.
```

**For RESUME mode:**
```
Resume iterative implementation from existing issues file.

Plan file: <plan-file-path>
Mode: RESUME

## Instructions

1. FIND ISSUES FILE:
   - Extract plan hash from plan filename
   - Load: .claude/plans/issues-{plan-hash5}.json
   - Validate JSON structure and integrity

2. ANALYZE STATE:
   - Parse completion status (completed/pending/failed/deferred)
   - Identify next issue to implement
   - Validate dependencies are met
   - Check for blockers

3. ORCHESTRATOR LOOP:
   - Resume from next incomplete issue
   - Same workflow as DECOMPOSE mode (steps 5a-5f above)
   - Update issues.json as you progress

4. HANDLE FAILURES:
   - If failed issues block others: ask user how to proceed
   - If all issues blocked: report and stop

Report back with minimal output: resume summary, issues file path.
```

Use `subagent_type: "issue-builder-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the issue-builder agent to complete.

The agent will handle the entire orchestration loop internally, presenting issues to the user via AskUserQuestion and spawning file-editor agents as approved.

### Step 4: Report Summary

After the agent completes, provide a minimal summary:

```
## Issue Builder Summary

### Mode: [DECOMPOSE | RESUME]

**Plan**: [plan file path]
**Issues File**: .claude/plans/issues-{hash5}.json

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
- Resume if needed: /issue-builder <plan-path> --resume
- Commit when satisfied

**Issues file saved**: .claude/plans/issues-{hash5}.json
```

## Workflow Diagram

```
/issue-builder <plan> [--resume]
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
    │   │ Launch issue-builder-default            │◄── run_in_background: true
    │   │                                         │
    │   │  1. Read plan                           │
    │   │  2. Build dependency graph              │
    │   │  3. Create issues.json                  │
    │   │  4. Enter orchestrator loop:            │
    │   │     ├─► Present issue (AskUserQuestion) │
    │   │     ├─► User approves?                  │
    │   │     ├─► Spawn file-editors              │
    │   │     ├─► Verify completion               │
    │   │     ├─► Update issues.json              │
    │   │     └─► Next issue                      │
    │   └─────────────────────────────────────────┘
    │
    └──[RESUME]─────────────────────────┐
                                        │
        ┌─────────────────────────────────────────┐
        │ Launch issue-builder-default            │◄── run_in_background: true
        │                                         │
        │  1. Load issues-{hash5}.json            │
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
| User aborts orchestration | Save state to issues.json, report progress |
| File-editor fails | Mark issue as failed, ask user how to proceed |

## Example Usage

```bash
# Create issues from plan and start implementation
/issue-builder .claude/plans/oauth2-authentication-a3f9e-plan.md

# Resume from existing issues file
/issue-builder .claude/plans/oauth2-authentication-a3f9e-plan.md --resume

# After interruption, resume where you left off
/issue-builder .claude/plans/payment-refactor-7k2m1-plan.md --resume
```

## When to Use Issue Builder vs Direct Editor

**Use Issue Builder (`/issue-builder`) when:**
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

## Issues File Structure

The issues file provides:
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
