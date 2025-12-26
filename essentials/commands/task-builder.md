---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <plan-file-path OR tasks-file-path>
description: Break down a plan into granular tasks and orchestrate iterative implementation (project)
---

Break down implementation plans into trackable tasks and orchestrate user-driven iterative implementation. Creates a comprehensive tasks.json file that decomposes the plan into logical, atomic work units with COMPLETE implementation details, code snippets, architectural context, requirements, and constraints embedded in each task. Tasks are fully self-contained so file-editor agents never need to reference the plan. Then manages implementation one task at a time with full verification.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the tasks file directly, not in chat.

**KEY FEATURE**: Tasks extract and embed ALL detail from the plan including:
- Complete code snippets (can be hundreds of lines per file)
- Full implementation details verbatim from plan
- All architectural context and relationships
- All requirements (with R-IDs) and constraints (with C-IDs)
- Testing strategies and risk mitigations
- External documentation and API details

This makes tasks completely self-contained for implementation.

## Arguments

**Two modes based on file type:**

1. **DECOMPOSE MODE** - Pass a plan file:
   - `<plan-file-path>`: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
   - Creates tasks.json and starts orchestration

2. **RESUME MODE** - Pass an tasks file:
   - `<tasks-file-path>`: Path to existing tasks file (e.g., `.claude/plans/tasks-a3f9e.json`)
   - Resumes from where it left off

## Instructions

### Step 1: Parse Arguments and Determine Mode

Parse `$ARGUMENTS` to extract the input file path.

**Mode Detection (based on file extension):**
- If file ends with `.md`: **DECOMPOSE mode** - Create tasks.json from plan and start orchestration
- If file ends with `.json` or contains `tasks-`: **RESUME mode** - Load existing tasks.json and resume orchestration

**Validation:**
- Verify input file exists (use Bash: `ls <file-path>`)
- For DECOMPOSE mode: Verify plan status is "READY FOR IMPLEMENTATION"
- For RESUME mode: Verify JSON structure is valid tasks file

### Step 2: Launch task Builder in Background

Launch the `task-builder-default` agent **in the background** using the Task tool with `run_in_background: true`:

**For DECOMPOSE+ORCHESTRATE mode:**
```
Break down the implementation plan into granular, trackable tasks, then IMMEDIATELY enter the iterative orchestration loop to implement them one by one with user approval.

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

2. TASK DECOMPOSITION WITH FULL DETAIL EMBEDDING:
   - Break plan into logical, atomic tasks
   - Strategy: layer-based (one task per dependency layer) OR file-based OR feature-based
   - For EACH task, embed COMPLETE details:
     * full_description: Multi-paragraph context (1000-3000 chars)
     * For each file:
       - Complete implementation_details from plan (500-5000+ chars)
       - ALL code_snippets from plan (can be hundreds of lines each)
       - Complete changes_list, purpose, dependencies, provides
     * requirements_addressed: ALL requirements with R-IDs
     * constraints_applicable: ALL constraints with C-IDs
     * architectural_context: Relevant architecture sections
     * implementation_notes: Patterns, guidance from plan
     * testing_strategy: Test requirements for this task
     * risk_mitigations: Risks and how to mitigate
     * external_context: Relevant API docs and examples
   - Each task must be:
     - Atomic: Independently implementable (within its layer)
     - Self-Contained: Has ALL detail needed, no plan reference required
     - Testable: Clear verification criteria
     - Reversible: Can be rolled back without breaking others
     - Traceable: Maps to specific plan requirements with IDs

3. CREATE COMPREHENSIVE TASKS FILE:
   - Write to: .claude/plans/tasks-{plan-hash5}.json
   - Use same 5-char hash from plan filename
   - Structure: version, plan_reference, tasks array, completion_summary
   - Each task contains 15+ fields with complete details
   - File-editor agents will receive ALL context from tasks, never read plan

4. QUALITY SCORING:
   - Score decomposition on: atomicity, dependency accuracy, requirement coverage, verification clarity, granularity, self-containment
   - Minimum: 40/50 with no dimension <8
   - Revise if score too low

PHASE 2: ORCHESTRATION LOOP (immediately after creating tasks.json)

5. ENTER ORCHESTRATOR LOOP:
   - For each task (in dependency order):
     a. Present task to user with AskUserQuestion:
        - Options: [1] Implement this task, [2] Skip this task, [3] View complete details, [4] Pause/Compact, [5] Abort
        - Show: task ID, title, files count, changes count

     b. If user selects [1] Implement:
        - Spawn file-editor-default agents IN PARALLEL (one per file in the task)
        - Launch ALL in a SINGLE message with run_in_background: true
        - For EACH file, pass the plan file path and file path (like code-quality does)
        - File-editors read the plan file directly to get full context

     c. Wait for all file-editors to complete (use TaskOutput with block: true)

     d. Verify ALL changes completed:
        - For each file: CHANGES COMPLETED must equal TOTAL CHANGES from plan
        - If mismatch: re-dispatch file-editor for missed changes only
        - Loop until verified

     e. Run regression testing (if configured)

     f. Update tasks.json with completion status

     g. Move to next task

6. CRITICAL RULES:
   - Create tasks.json THEN immediately start orchestration
   - ONE task at a time (sequential task processing)
   - PARALLEL file-editors within each task (one per file)
   - User approval required for EACH task via AskUserQuestion
   - After each task: ask user to continue/pause/abort
   - File-editors read plan file directly (pass plan path, not contents)
   - Verify all changes before marking task complete
   - Update tasks.json after every status change
   - NO state-modifying git commands

Report back with minimal output: tasks created, orchestration results, tasks file path.
```

**For RESUME mode:**
```
Resume iterative implementation from existing tasks file.

Tasks file: <tasks-file-path>
Mode: RESUME

## Instructions

1. LOAD TASKS FILE:
   - Read the provided tasks file: <tasks-file-path>
   - Validate JSON structure and integrity
   - Extract plan_reference to know which plan this came from

2. ANALYZE STATE:
   - Parse completion status (completed/pending/failed/deferred)
   - Identify next task to implement
   - Validate dependencies are met for next task
   - Check for blockers

3. GET YOUR BEARINGS:
   - Report to user: "Resuming from [tasks-file-path]"
   - Report: "[X] tasks completed, [Y] remaining"
   - Report: "Next task: TSK-XXX [title]"

4. ORCHESTRATOR LOOP:
   - Resume from next incomplete task
   - Same workflow as DECOMPOSE mode (steps 5a-5f above)
   - Update tasks.json as you progress

5. HANDLE FAILURES:
   - If failed tasks block others: ask user how to proceed
   - If all tasks blocked: report and stop

Report back with minimal output: resume summary, tasks file path.
```

Use `subagent_type: "task-builder-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the task-builder agent to complete.

The agent will handle the entire orchestration loop internally, presenting tasks to the user via AskUserQuestion and spawning file-editor agents as approved.

### Step 4: Report Summary

After the agent completes, provide a minimal summary:

```
## Task Builder Summary

### Mode: [DECOMPOSE | RESUME]

**Plan**: [plan file path]
**Tasks File**: .claude/plans/tasks-{hash5}.json

### Results

**Total Tasks**: [N]
**Completed**: [X] ([%]%)
**Failed**: [Y]
**Deferred**: [Z]
**Pending**: [W]

**Changes Completed**: [X] / [N] ([%]%)
**Requirements Met**: [X] / [N] ([%]%)

### Tasks Summary

**Completed:**
- TSK-001: [title] ✓
- TSK-002: [title] ✓

**Failed:**
- TSK-XXX: [title] - [reason]

**Deferred:**
- TSK-YYY: [title]

**Blocked:**
- TSK-ZZZ: [title] - [blocked by TSK-XXX]

### Next Steps

- Review changes: git diff
- Run quality checks (see CLAUDE.md)
- Address failed/deferred tasks
- Resume if needed: /task-builder <tasks-path>
- Commit when satisfied

**Tasks file saved**: .claude/plans/tasks-{hash5}.json
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
    │   │     ├─► Present task (AskUserQuestion) │
    │   │     ├─► User approves?                  │
    │   │     ├─► Spawn file-editors              │
    │   │     ├─► Verify completion               │
    │   │     ├─► Update tasks.json              │
    │   │     └─► Next task                      │
    │   └─────────────────────────────────────────┘
    │
    └──[RESUME]─────────────────────────┐
                                        │
        ┌─────────────────────────────────────────┐
        │ Launch task-builder-default            │◄── run_in_background: true
        │                                         │
        │  1. Load tasks-{hash5}.json            │
        │  2. Analyze completion state            │
        │  3. Find next task                     │
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
| Tasks file missing (RESUME mode) | Report error, suggest running with plan file instead |
| Tasks file corrupted | Report error, suggest regenerating |
| All tasks blocked | Report blockers, ask user to resolve failed tasks |
| User aborts orchestration | Save state to tasks.json, report progress |
| File-editor fails | Mark task as failed, ask user how to proceed |

## Example Usage

```bash
# DECOMPOSE MODE: Create tasks from plan and start implementation
/task-builder .claude/plans/oauth2-authentication-a3f9e-plan.md

# RESUME MODE: Resume from existing tasks file (NOTE: Pass the tasks.json, not the plan!)
/task-builder .claude/plans/tasks-a3f9e.json

# After interruption or /compact, resume where you left off
/task-builder .claude/plans/tasks-7k2m1.json
```

## When to Use Task Builder vs Direct Editor

**Use Task Builder (`/task-builder`) when:**
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

Task Builder works with plans created by:
- `/planner` - Implementation plans
- `/bug-scout` - Bug fix plans (if complex multi-file fixes)
- `/code-quality` - Quality improvement plans (if many files)

## Tasks File Structure

The tasks file provides:
- **Granular tracking**: Progress at task level, not just file level
- **Dependency management**: Visual graph prevents implementation ordering mistakes
- **Resume capability**: If interrupted, resume exactly where you left off
- **Requirement traceability**: Every task maps to specific plan requirements with R-IDs
- **Audit trail**: Complete history of what was implemented when
- **Self-contained specs**: Each task has COMPLETE implementation details
- **No plan dependency**: File-editors never need to reference the plan file
- **Comprehensive context**: Tasks embed all code snippets, architectural context, requirements, constraints, testing strategy, and risk mitigations

**Task Size**: Tasks are intentionally large and comprehensive (often 5-50KB each)
to provide complete implementation specifications. This eliminates the need for
file-editor agents to read or parse the plan file.

Located at: `.claude/plans/tasks-{plan-hash5}.json`
