---
allowed-tools: Task, TaskOutput
argument-hint: <task description>
description: Create a comprehensive implementation plan for a task, with grammar and spelling check on the task description (project)
---

Create a comprehensive implementation plan for the specified task, then automatically spawn file-editor agents to implement it.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the plan FILE directly, not in chat.

## Instructions

### Step 1: Grammar Check

Before launching the `planner-default` agent, first grammar and spell check the provided task description (`$ARGUMENTS`). Ensure the revised task description is clear, correct, and unambiguous.

### Step 2: Launch Planner in Background

Launch the `planner-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Create a comprehensive implementation plan for the following task:

<corrected and grammar-checked task description>

Write the plan to `.claude/plans/` following your standard format.

IMPORTANT: At the end of your plan, include a "Files to Edit" section listing all files that need changes.
```

Use `subagent_type: "planner-default"` when invoking the Task tool.

### Step 3: Wait for Plan Completion

Use `TaskOutput` with `block: true` to wait for the planner agent to complete. The planner will:
1. Investigate the codebase thoroughly
2. Research external documentation if needed
3. Create a detailed implementation plan in `.claude/plans/`
4. Return the plan file path and list of files to edit

### Step 4: Parse Planner Output

From the planner's output, extract:
1. The plan file path (e.g., `.claude/plans/feature-name-3k7f2-plan.md` with 5-char hash)
2. The list of files to edit/create from the "Files" section
3. The overall risk level from the "Risk Assessment Summary"
4. Any blockers that must be resolved

### Step 4.5: Risk Validation Gate

Before spawning file-editors, validate the risk assessment:

**If Risk Level is HIGH or CRITICAL:**
- Display the risk summary to the user
- Show high-priority risks and their mitigations
- Ask for explicit confirmation before proceeding
- If blockers exist, report them and stop

**If Risk Level is LOW or MEDIUM:**
- Proceed automatically
- Include risk summary in final report

**Risk Validation Template:**
```
⚠️ Risk Assessment: [LEVEL]

High-Priority Risks:
1. [Risk]: [Mitigation]
2. [Risk]: [Mitigation]

Blockers: [List or "None"]

Proceed with implementation? [Y/N]
```

### Step 5: Auto-Spawn File Editors

If the planner identified files to edit or create, **automatically launch `file-editor-default` agents in background** for each file:

```
Execute the implementation plan on your assigned file.

Plan file: <plan-file-path>
Your assigned file: <file-path>

Read the plan file first, find your file's section in the Implementation Plan. Your section will be marked either `[edit]` or `[create]`:
- For `[edit]`: Use the Edit tool to modify the existing file precisely
- For `[create]`: Use the Write tool to create a new, complete, functional file with all imports, types, implementation, and exports

Implement ALL changes precisely as specified in the plan.

**CRITICAL**: You MUST implement ALL changes listed in TOTAL CHANGES for your file.

When complete, report back with:
1. File path and action type (edit/create)
2. **CHANGES COMPLETED**: [X] / [Y] (must match TOTAL CHANGES from plan)
3. Summary of each change made (numbered)
4. Regression check results
5. Any issues encountered

**If you cannot complete a change**, explain why but still attempt all others.
```

Use `subagent_type: "file-editor-default"` for each Task tool invocation with `run_in_background: true`.

**Launch ALL file-editor agents in a single message** to enable parallel execution.

### Step 6: Collect Editor Results

Use `TaskOutput` with `block: true` to wait for each file-editor agent to complete.

Collect results from each agent:
- File path
- `CHANGES COMPLETED: X/Y` count
- Changes implemented
- Issues or warnings

### Step 6.5: Verify ALL Changes Were Implemented (CRITICAL)

**This step ensures no changes are missed.** For each file that was edited:

1. **Compare change counts**:
   - `TOTAL CHANGES` from planner-default's per-file section
   - `CHANGES COMPLETED` reported by file-editor-default

2. **If counts don't match** (editor made fewer changes than planned):
   - Re-read the plan file's per-file section
   - Identify which specific changes were missed
   - Re-dispatch a file-editor-default agent with ONLY the missed changes
   - Wait for completion and verify again

3. **Verification loop**: Continue until ALL files have:
   - CHANGES COMPLETED == TOTAL CHANGES from plan

4. **Track verification status**:
   ```
   | File | Planned | Completed | Status |
   |------|---------|-----------|--------|
   | [path] | 4 | 4 | ✓ Complete |
   | [path] | 6 | 5 | ⚠ Missing 1 - Re-dispatching |
   ```

**Example re-dispatch prompt for missed changes:**
```
Complete the remaining changes for this file.

Plan file: <plan-file-path>
File: <file-path>

## Missing Changes (from original plan)

The following changes were in the plan but NOT implemented:

1. **[Missed Change Title]** (line X-Y)
   - Description: [from plan]
   - Implementation details: [from plan]

## Instructions

Implement ONLY the missing changes listed above. These were part of the original
plan but were not completed in the first pass.

Report back with `CHANGES COMPLETED: N/N` confirming all missing changes are done.
```

### Step 7: Post-Implementation Verification

After all file-editor agents complete, run verification:

1. **Run automated checks:**
   - Run project linters, formatters, and type checkers as configured for the project
   - Check CLAUDE.md or project documentation for specific commands

2. **Run relevant tests** (if test paths specified in plan):
   - Run the project's test suite using the configured test runner
   - Focus on tests related to the modified files

3. **Validate against success criteria** from the plan's "Success Metrics" section

4. **Check for issues:**
   - If automated checks fail → Report specific failures
   - If tests fail → Report which tests and why
   - If success criteria not met → Report gaps

### Step 8: Report Summary

After all agents complete and verification runs, provide a summary:

```
## Implementation Summary

### Plan Created
- **Plan file**: [path]
- **Task**: [brief description]
- **Risk Level**: [Low/Medium/High]

### Files Modified/Created: [count]

| File | Action | Status | Changes |
|------|--------|--------|---------|
| [path] | edit | ✓ Complete | [brief summary] |
| [path] | create | ✓ Complete | [brief summary] |

### Change Verification Results

| File | Planned | Completed | Re-dispatches | Status |
|------|---------|-----------|---------------|--------|
| [path] | 4 | 4 | 0 | ✓ All Complete |
| [path] | 6 | 6 | 1 | ✓ All Complete (after retry) |

### Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| Linter | ✓/✗ | [any issues] |
| Formatter | ✓/✗ | [any issues] |
| Type checker | ✓/✗ | [any issues] |
| Tests | ✓/✗ | [pass/fail count] |

### Success Criteria

| Requirement | Status |
|-------------|--------|
| [Requirement 1] | ✓/✗ |
| [Requirement 2] | ✓/✗ |

### Next Steps
- [ ] Review changes with `git diff`
- [ ] Address any failing checks above
- [ ] Notify stakeholders: [list from plan]
- [ ] Commit if satisfied
```

## Workflow Diagram

```
/planner <task>
    │
    ▼
┌─────────────────────┐
│ Grammar check task  │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Launch planner      │◄── run_in_background: true
│ (planner-default)   │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for plan
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Parse files & risks │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Risk Validation     │◄── HIGH/CRITICAL? Ask user
│ Gate                │
└─────────────────────┘
    │
    ├──[Blockers?]──▶ STOP & Report
    │
    ▼
┌─────────────────────────────────────┐
│ Launch file-editors in parallel     │◄── run_in_background: true
│ (file-editor-default × N files)     │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for all editors
│ for each editor     │
└─────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ VERIFY ALL CHANGES IMPLEMENTED              │◄── CRITICAL STEP
│                                             │
│  For each file:                             │
│  - Compare: Planned vs Completed            │
│  - If mismatch: Re-dispatch for missed      │
│  - Loop until all changes verified          │
└─────────────────────────────────────────────┘
    │
    ├── Mismatch? ──► Re-dispatch file-editor
    │                  for missed changes only
    │                  │
    │                  ▼
    │                 Loop back to verify
    │
    ▼ (All verified)
┌─────────────────────┐
│ Post-Implementation │◄── linter, type checker, tests
│ Verification        │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report summary      │◄── Include verification results
└─────────────────────┘
```

## Error Handling

- **Planner fails**: Report error and stop
- **Risk level CRITICAL with blockers**: Report blockers and stop - do not proceed with implementation
- **Risk level HIGH**: Ask user for confirmation before proceeding
- **File-editor fails**: Continue with other files, report failure in summary
- **No files to edit**: Report plan created but no implementation needed
- **Changes incomplete**: Re-dispatch editor with missed changes only, verify again
- **Re-dispatch fails**: Report specific missed changes, mark for manual review
- **Verification fails**: Report specific failures, suggest fixes, do not auto-commit
- **Tests fail**: Report failing tests with details, suggest investigation

## Rollback Guidance

If implementation causes issues:
1. Check the plan's "Rollback Strategy" section
2. Use `git checkout -- <files>` to revert individual files
3. Use `git reset --hard HEAD~1` to revert entire commit (if already committed)
4. Follow the "Recovery Steps" from the plan
