---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <log-dump> <user-report>
description: Deep bug investigation with log analysis and automatic fix implementation (project)
---

Investigate bugs by analyzing error logs and user reports, performing deep code analysis, and automatically dispatching `file-editor-default` agents to implement targeted fixes.

**IMPORTANT**: The bug-scout NEVER runs git commands that modify state (commit, add, checkout, reset, revert). Only view-only git commands allowed (diff, status, log, blame). All changes remain uncommitted for user review.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the plan FILE directly, not in chat.

## Arguments

1. **Log dump**: Error logs, stack traces, or path to a log file
2. **User report**: Description of the issue, expected vs actual behavior, and any diagnostic instructions (e.g., "check docker logs for api-service", "review PID 12345 output")

## Instructions

### Step 1: Parse and Gather Input

Parse `$ARGUMENTS` to extract the log dump and user report.

**Process the log dump:**
- If it's a file path, use the Read tool to load the log contents
- If it's inline text, extract the error signals directly

**Process the user report:**
- Extract the problem description and expected behavior
- Identify any diagnostic instructions (Docker logs, PID checks, specific commands)
- Execute any requested diagnostic commands using Bash:
  - Docker logs: `docker logs <container> --tail 500`
  - Process logs: `journalctl -u <service>` or check `/var/log/`
  - Custom commands as specified by the user

### Step 2: Launch Bug Scout in Background

Launch the `bug-scout-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Investigate the following bug and create a precise fix plan.

## Log Dump

<paste the error logs/stack traces here>

## User Report

<paste the user's problem description, expected behavior, and any diagnostic findings>

## Investigation Instructions

Perform a comprehensive bug investigation following your systematic process with reflection checkpoints:

**Core Principles**: Evidence-based, systematic investigation with ReAct reasoning loops and self-critique at each phase.

0. ERROR SIGNAL EXTRACTION
   - Parse error message, stack trace, error codes
   - Extract relevant timestamps and context
   - Identify the failure point and error type

1. PROJECT CONTEXT GATHERING
   - Read CLAUDE.md, README.md for project conventions
   - Use git log/blame to identify recent changes (view-only)
   - Understand error handling patterns

2. CODE PATH TRACING
   - Identify entry point
   - Map complete call chain to failure
   - Track data flow through the path

**2.5. REFLECTION CHECKPOINT (ReAct Loop)**
   - Verify call chain completeness
   - Confirm evidence sufficiency
   - Validate suspicious section identification
   - Document decision to proceed

3. LINE-BY-LINE DEEP ANALYSIS
   - Mark suspicious code sections
   - Analyze every line in suspect areas
   - Apply bug pattern detection (null checks, bounds, types, etc.)

4. REGRESSION ANALYSIS LOOP
   - Map recent changes to affected code
   - Test each regression hypothesis
   - Confirm root cause with evidence

**4.5. REFLECTION CHECKPOINT (ReAct Loop)**
   - Validate root cause confidence (High/Medium/Low)
   - Verify evidence is conclusive
   - Identify all contributing factors
   - Document confidence level and justification

5. FIX PLAN GENERATION
   - Select minimal vs comprehensive fix strategy
   - Specify exact changes with file:line locations
   - Include before/after code examples

6. WRITE PLAN TO FILE
   - Write plan to .claude/plans/bug-scout-<identifier>-<hash5>-plan.md (with 5-char hash)
   - Include TOTAL CHANGES count
   - Format for file-editor-default consumption
   - **Quality Score**: Rate investigation on 6 dimensions (Error Signal Extraction, Code Path Tracing, Line-by-Line Depth, Regression Analysis, Root Cause Confidence, Fix Precision)

IMPORTANT: Your output MUST include:
- Root cause identification with confidence level
- Severity assessment (Critical/High/Medium/Low)
- Exact file:line locations for all fixes
- **TOTAL CHANGES**: N (exact number of changes)
- Plan file path for automatic file-editor dispatch

Write the complete plan to `.claude/plans/` and report back with minimal output.
```

Use `subagent_type: "bug-scout-default"` when invoking the Task tool.

### Step 3: Wait for Investigation Completion

Use `TaskOutput` with `block: true` to wait for the bug-scout agent to complete.

From the agent's output, extract:
1. The plan file path (e.g., `.claude/plans/bug-scout-auth-error-4k2m7-plan.md` with 5-char hash)
2. Severity level
3. Root cause confidence
4. Files to edit
5. Total changes count

### Step 4: Risk Validation Gate

Before spawning file-editors, validate the investigation:

**If Severity is CRITICAL or Root Cause Confidence is LOW:**
- Display the summary to the user
- Show the root cause hypothesis
- Ask for explicit confirmation before proceeding

**If Severity is HIGH/MEDIUM/LOW and Confidence is HIGH/MEDIUM:**
- Proceed automatically
- Include findings in final report

**Risk Validation Template:**
```
Investigation Summary: [severity]

Root Cause (Confidence: [level]):
[Brief description]

Files to Modify:
1. [file1]: [change summary]
2. [file2]: [change summary]

Proceed with fix implementation? [Y/N]
```

### Step 5: Auto-Spawn File Editors

If the scout identified files to edit or create, launch `file-editor-default` agents **in the background** for each file:

```
Execute the bug fix plan on your assigned file.

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

For each completed editor, collect:
- File path
- Changes implemented (count)
- Regression check status
- Issues or warnings

### Step 7: Verify ALL Fixes Were Implemented (CRITICAL)

**This step ensures no fixes are missed.** For each file that was edited:

1. **Compare change counts**:
   - `TOTAL CHANGES` from bug-scout-default's plan file
   - `CHANGES COMPLETED` reported by file-editor-default

2. **If counts don't match** (editor made fewer changes than planned):
   - Read the plan file to identify which specific changes were missed
   - Re-dispatch a file-editor-default agent with ONLY the missed changes
   - Wait for completion and verify again

3. **Verification loop**: Continue until ALL files have:
   - CHANGES COMPLETED == TOTAL CHANGES from plan file

4. **Track verification status**:
   ```
   | File | Fixes Identified | Fixes Completed | Status |
   |------|------------------|-----------------|--------|
   | [path] | 3 | 3 | Complete |
   | [path] | 2 | 1 | Missing 1 - Re-dispatching |
   ```

**Example re-dispatch prompt for missed fixes:**
```
Complete the remaining bug fixes for this file.

Plan file: <plan-file-path>
File: <file-path>

## Missing Fixes (from original investigation)

The following fixes were identified but NOT implemented:

1. **[Missed Fix Title]** (line X-Y)
   - Problem: [description]
   - Fix: [exact change to make]

## Instructions

Implement ONLY the missing fixes listed above. These were part of the original
investigation but were not completed in the first pass.

Report back with confirmation that each missing fix has been applied.
```

### Step 8: Post-Implementation Verification

After all file-editor agents complete, run verification:

```bash
# Run project linters, formatters, and type checkers
# (check CLAUDE.md or project documentation for specific commands)
```

If the investigation identified specific test cases:
- Note which tests should now pass
- Suggest running those tests

### Step 9: Report Summary

After all agents complete and verification runs, provide a comprehensive summary:

```
## Bug Scout Investigation & Fix Summary

### Investigation Phase

**Error Investigated**: [brief description]
**Severity**: [Critical/High/Medium/Low]
**Root Cause Confidence**: [High/Medium/Low]
**Scout Agent**: Completed

### Root Cause

**Location**: [file:line]
**Problem**: [description]
**Evidence**: [key evidence that confirmed the cause]

### Implementation Phase

**Files Modified**: [count]
**Editor Agents**: [count] completed

| File | Status | Changes Made | Regression |
|------|--------|--------------|------------|
| [path] | Complete | [count] changes | Clean |
| [path] | Complete | [count] changes | Clean |

### Fix Verification Results

| File | Fixes Identified | Fixes Completed | Re-dispatches | Status |
|------|------------------|-----------------|---------------|--------|
| [path] | 3 | 3 | 0 | All Complete |
| [path] | 2 | 2 | 1 | All Complete (after retry) |

### Changes Summary

| Fix | File | Lines | Description |
|-----|------|-------|-------------|
| 1 | [path] | [lines] | [what was fixed] |
| 2 | [path] | [lines] | [what was fixed] |

### Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| Linter | /X | [any issues] |
| Formatter | /X | [any issues] |
| Type checker | /X | [any issues] |

### Suggested Tests to Run

Based on the bug fix, verify with:
- [ ] [Test command or manual verification step]
- [ ] [Additional verification]

### Next Steps

- Run project code quality checks (refer to CLAUDE.md)
- Review changes with `git diff`
- Run relevant tests
- Commit if satisfied

### Rollback Instructions (for user)

Bug Scout does NOT run git checkout. User can revert with:
- `git diff [file1] [file2] ...` - review specific files
- `git checkout -- [file1] [file2] ...` - revert specific files
- `git checkout -- .` - revert all changes
```

## Workflow Diagram

```
/bug-scout <log-dump> <user-report>
    │
    ▼
┌─────────────────────┐
│ Parse arguments:    │
│ - Log dump          │
│ - User report       │
└─────────────────────┘
    │
    ├──[Log file path?]──► Read file contents
    │
    ├──[Diagnostic instructions?]──► Execute requested commands
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch bug-scout-default in background      │◄── run_in_background: true
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ TaskOutput (block)                          │◄── Wait for investigation
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Parse results:      │
│ - Plan file path    │
│ - Root cause        │
│ - Files to fix      │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Risk Validation     │
│ Gate                │
└─────────────────────┘
    │
    ├──[CRITICAL or LOW confidence]──► Ask user confirmation
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch file-editor-default agents           │◄── run_in_background: true
│ (one per file needing fixes, parallel)      │
│                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Editor 1 │ │ Editor 2 │ │ ... N    │     │
│  │ (file1)  │ │ (file2)  │ │          │     │
│  └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ TaskOutput (block) for each editor          │◄── Wait for all edits
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ VERIFY ALL FIXES IMPLEMENTED                │◄── CRITICAL STEP
│                                             │
│  For each file:                             │
│  - Compare: Fixes Identified vs Completed   │
│  - If mismatch: Re-dispatch for missed      │
│  - Loop until all fixes verified            │
└─────────────────────────────────────────────┘
    │
    ├── Mismatch? ──► Re-dispatch file-editor
    │                  for missed fixes only
    │                  │
    │                  ▼
    │                 Loop back to verify
    │
    ▼ (All verified)
┌─────────────────────┐
│ Post-Implementation │◄── linters, type checker
│ Verification        │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report comprehensive│◄── Include rollback instructions
│ summary             │
└─────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Log file doesn't exist | Report error, stop |
| Diagnostic command fails | Report error, continue with available data |
| Scout agent fails | Report error, provide partial findings |
| No bug found in code | Report external/config causes, no editors spawned |
| File-editor fails | Report failure, continue with other files |
| **Fixes incomplete** | Re-dispatch editor with missed fixes only |
| **Re-dispatch fails** | Report specific missed fixes, mark for manual review |
| Low confidence finding | Ask user before proceeding |
| All editors fail | Report comprehensive error summary |

## Example Usage

```bash
# Basic: error log + user description
/bug-scout "TypeError: 'NoneType' object at auth_handler.py:45" "Login fails when user has no profile"

# With log file + detailed report
/bug-scout ./logs/error.log "API returns 500 on POST /users. Expected 201. Check docker logs for api-service"

# Stack trace + reproduction steps
/bug-scout "$(cat stacktrace.txt)" "Crash after clicking submit. Check PID 12345 for memory issues"

# Inline logs + diagnostic instructions
/bug-scout "ConnectionError: timeout after 30s" "Database queries hanging. Run 'docker logs db-service --tail 100' to check"

# Multiple error signals + context
/bug-scout "KeyError: 'user_id' at line 89" "Registration broke after last deploy. Expected new users to be created. Check git log for recent auth changes"
```

## Integration with Project Tools

After `/bug-scout` completes, run the project's verification:

```bash
# Run project quality checks (refer to CLAUDE.md for specific commands)
# Run relevant tests to verify the fix
# Review changes with git diff
```

## Severity Levels Reference

| Severity | Description | Auto-proceed? |
|----------|-------------|---------------|
| Critical | System crash, data loss, security vulnerability | Ask user |
| High | Feature broken, significant impact | Auto if confidence HIGH |
| Medium | Degraded functionality, workaround exists | Auto |
| Low | Minor issue, cosmetic, edge case | Auto |

## Root Cause Confidence Levels

| Confidence | Meaning | Required Evidence |
|------------|---------|-------------------|
| High | Definitive root cause found | Stack trace + code analysis + reproduction |
| Medium | Probable cause identified | Code analysis + pattern match |
| Low | Speculative cause | Limited evidence, needs verification |

## Bug Pattern Quick Reference

Common patterns the scout checks:

| Pattern | Description | Typical Fix |
|---------|-------------|-------------|
| Null Pointer | Accessing None/null value | Add null check before access |
| Off-by-One | Index out of bounds | Adjust loop/index boundaries |
| Type Mismatch | Wrong type at runtime | Add type validation/conversion |
| Resource Leak | Unclosed file/connection | Add proper cleanup/context manager |
| Race Condition | Concurrent access issue | Add synchronization/locking |
| Unhandled Exception | Missing error handling | Add try/catch with proper handling |
| Validation Gap | Missing input validation | Add input checks at entry point |
