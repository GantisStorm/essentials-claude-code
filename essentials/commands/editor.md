---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <plan-file-path> <file1> [file2] ... [fileN]
description: Execute a plan by spawning parallel file-editor agents for each file (project)
---

Execute the implementation plan by spawning parallel `file-editor-default` agents in the background and collecting results.

**IMPORTANT**: The editor NEVER runs git commands that modify state (commit, add, checkout, reset, revert). Only view-only git commands allowed (diff, status, log). All changes remain uncommitted for user review.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the changes FILE directly, not in chat.

## Arguments

- First argument: Path to the plan file in `.claude/plans/`
- Remaining arguments: File paths to edit (one agent spawned per file)

## Instructions

### Step 1: Parse and Validate Arguments

Parse `$ARGUMENTS` to extract:
1. The plan file path (first argument)
2. The list of files to edit (remaining arguments)

**Validation checks:**
- Verify plan file exists (use Bash: `ls <plan-path>`)
- Verify all target files exist (for edits) or parent directories exist (for creates)
- Report any missing files before proceeding

**IMPORTANT**: Do NOT read the entire plan file yourself. Pass the plan path directly to the agents to avoid polluting the orchestrator's context window.

### Step 2: Pre-Flight Conflict Check

Before launching editors, check for potential conflicts:
- If multiple files are in the same directory, note this (parallel edits to shared imports)
- If files have obvious dependencies (A imports B), note the order

### Step 3: Launch File Editors in Background

For EACH file in the list, launch a `file-editor-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Execute the implementation plan on your assigned file.

Plan file: <plan-file-path>
Your assigned file: <file-path>

Read the plan file first, find your file's section in the Implementation Plan, and implement ALL changes precisely.

**CRITICAL**: You MUST implement ALL changes listed in TOTAL CHANGES for your file.

When complete, report back with:
1. File path
2. **CHANGES COMPLETED**: [X] / [Y] (must match TOTAL CHANGES from plan)
3. Summary of each change made (numbered)
4. Regression check results
5. Any issues or warnings encountered

**If you cannot complete a change**, explain why but still attempt all others.
```

Use `subagent_type: "file-editor-default"` for each Task tool invocation.

**Launch ALL agents in a single message** with `run_in_background: true` to enable parallel execution.

### Step 4: Collect Results

Use `TaskOutput` with `block: true` to wait for each file-editor agent to complete.

For each completed agent, collect:
- File path
- `CHANGES COMPLETED: X/Y` count
- Changes implemented
- Security assessment
- Regression check status
- Issues or warnings
- Potential merge conflicts

### Step 4.5: Verify ALL Changes Were Implemented (CRITICAL)

**This step ensures no changes are missed.** For each file that was edited:

1. **Compare change counts**:
   - `TOTAL CHANGES` from the plan's per-file section
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

Implement ONLY the missing changes listed above.

Report back with `CHANGES COMPLETED: N/N` confirming all missing changes are done.
```

### Step 5: Run Aggregated Verification

After all agents complete, run verification across all files:

```bash
# Run project linters, formatters, and type checkers
# (check CLAUDE.md or project documentation for specific commands)
```

Collect results:
- Number of lint errors fixed
- Number of type errors found
- Any files that failed verification

### Step 6: Report Summary

After all agents complete and verification runs, provide a comprehensive summary:

```
## Editor Execution Summary

### Plan: [plan-file-path]

### Pre-Flight Validation
- Plan file: ✓ Found
- Target files: [count] found, [count] to create
- Potential conflicts: [list or "None"]

### Files Modified: [count] / [total]

| File | Status | Changes | Security | Regression |
|------|--------|---------|----------|------------|
| [path] | ✓ Complete | [brief summary] | ✓ Good | Clean |
| [path] | ✓ Complete | [brief summary] | ⚠ Review | Clean |
| [path] | ✗ Failed | [reason] | N/A | N/A |

### Aggregated Metrics

| Metric | Count |
|--------|-------|
| Files completed | X |
| Files failed | X |
| Lines added | X |
| Lines modified | X |
| Lines removed | X |
| Security issues found | X |
| Merge conflicts detected | X |

### Change Verification Results

| File | Planned | Completed | Re-dispatches | Status |
|------|---------|-----------|---------------|--------|
| [path] | 4 | 4 | 0 | ✓ All Complete |
| [path] | 6 | 6 | 1 | ✓ All Complete (after retry) |

### Verification Results

| Check | Status | Details |
|-------|--------|---------|
| Linter | ✓/✗ | [errors fixed / remaining] |
| Formatter | ✓/✗ | [files formatted] |
| Type checker | ✓/✗ | [error count] |

### Security Summary

| Assessment | Files |
|------------|-------|
| ✓ Good | [count] |
| ⚠ Needs Review | [count] - [list files] |
| ✗ Issues Found | [count] - [list files] |

### Issues Encountered
[List any issues from agents, or "None"]

### Potential Merge Conflicts
[List any conflicts detected by agents, or "None"]

### Rollback Instructions (for user)

Editor does NOT run git checkout. User can revert with:
- `git checkout -- [file1] [file2] ...` - revert specific files
- `git checkout -- .` - revert all changes

### Next Steps (for user)
- [ ] Review changes: `git diff`
- [ ] Address any security issues flagged above
- [ ] Resolve any type errors
- [ ] Run tests: `[project test command]`
- [ ] Commit when satisfied: `git add . && git commit -m "message"`
```

**NOTE**: Editor only uses view-only git commands (diff, status, log). User handles all git modifications.

## Workflow Diagram

```
/editor <plan> <file1> <file2> ...
    │
    ▼
┌─────────────────────┐
│ Parse & Validate    │◄── Verify plan and files exist
│ Arguments           │
└─────────────────────┘
    │
    ├──[Missing files?]──▶ STOP & Report
    │
    ▼
┌─────────────────────┐
│ Pre-Flight Conflict │◄── Check for potential conflicts
│ Check               │
└─────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Launch file-editors in parallel     │◄── run_in_background: true
│ (file-editor-default × N files)     │
│                                     │
│  ┌──────────┐ ┌──────────┐          │
│  │ Editor 1 │ │ Editor 2 │ ...      │
│  │ +Security│ │ +Security│          │
│  │ +Impact  │ │ +Impact  │          │
│  └──────────┘ └──────────┘          │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ TaskOutput (block) for each editor  │◄── Wait for completion
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Collect results     │◄── Aggregate security, conflicts
│ + Security summary  │
│ + Conflict summary  │
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
│ Aggregated          │◄── linter, formatter, type checker
│ Verification        │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report summary      │◄── Include rollback instructions
│ + Rollback info     │
└─────────────────────┘
```

## Error Handling

- **Plan file missing**: Report error immediately and stop
- **Target file missing** (for edit): Report which files are missing, stop if critical
- **File-editor fails**: Continue with other files, mark as failed in summary
- **All agents fail**: Report comprehensive error summary with diagnostics
- **Changes incomplete**: Re-dispatch editor with missed changes only, verify again
- **Re-dispatch fails**: Report specific missed changes, mark for manual review
- **Security issues found**: Flag in summary, recommend security review before user commits
- **Merge conflicts detected**: List in summary, provide resolution guidance
- **Verification fails**: Report specific errors, suggest fixes

## Rollback Guidance (for user reference)

Editor only uses view-only git commands. User handles all reversions:
1. Review changes: `git diff`
2. Revert individual files: `git checkout -- <file>`
3. Revert multiple files: `git checkout -- <file1> <file2> ...`
4. Revert all changes: `git checkout -- .`

**Editor will NOT run these commands** - only document them for user reference.

## Example Usage

```bash
# Execute a plan on multiple files
/editor .claude/plans/oauth2-plan.md src/auth/handler src/auth/middleware src/models/user

# Execute a plan on a single file
/editor .claude/plans/bugfix-plan.md src/services/payment
```
