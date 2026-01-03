---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <any-input>
description: Deep bug investigation with architectural fix plan generation - detailed enough to feed directly into /implement-loop, Spec Kit, or OpenSpec
---

# Bug Investigation & Architectural Fix Planning

Investigate bugs by analyzing any input - error logs, stack traces, user reports, or descriptions. Creates a comprehensive **architectural fix plan** with exact code specifications.

**IMPORTANT**: Never runs git commands that modify state. Only view-only git commands allowed.

## Why Architectural Fix Plans?

Architectural bug investigation with full context produces dramatically better results:
- **Bird's eye view** - Understand the full codebase before planning fixes
- **Complete information** - Trace all relevant code paths, not just a few lines
- **Separated phases** - Investigation first, then fix planning with full context
- **Mapped relationships** - Detect all dependencies that could cause regressions

**Architectural fix plans specify**:
- Exact code changes with file:line locations
- Root cause analysis with evidence
- Regression test requirements
- Exit criteria verification

## What Good Architectural Fix Plans Include

1. **Clear Root Cause Specification**
   - Exact location of the bug (file:line)
   - Evidence chain proving the cause
   - Contributing factors

2. **Architectural Fix Specification**
   - Exact code changes to make
   - How the fix integrates with existing code
   - Dependencies and relationships
   - Regression prevention measures

3. **Implementation Steps**
   - Ordered fix sequence
   - Test additions required
   - Verification commands

4. **Exit Criteria**
   - Commands that must pass
   - Test cases that verify the fix
   - Regression tests

## Arguments

Takes **any input**:
- Error logs: `"TypeError: 'NoneType' at auth.py:45"`
- Stack traces: `"$(cat stacktrace.txt)"`
- Log files: `./logs/error.log`
- User reports: `"Login fails when user has no profile"`
- Diagnostic instructions: `"Check docker logs for api-service"`
- Any combination of the above

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS`:
- If file path, use Read tool to load contents
- If inline text, extract error signals
- If diagnostic instructions, execute commands:
  - Docker logs: `docker logs <container> --tail 500`
  - Process logs: `journalctl -u <service>`
  - Custom commands as specified

### Step 2: Launch Bug Investigation Agent

Launch `bug-plan-creator-default` in background:

```
Investigate this bug and create an architectural fix plan with maximum depth and verbosity.

## Input

<all gathered logs, errors, context>

## Requirements

- Produce a VERBOSE architectural fix plan suitable for /implement-loop, Spec Kit, or OpenSpec
- Include complete fix specifications (not just what to change, but HOW)
- Specify exact code structures and integration points
- Provide ordered fix steps with dependencies
- Include regression test requirements
- Include exit criteria with verification commands

## Investigation Phases

0. ERROR SIGNAL EXTRACTION - Parse error, stack trace, codes
1. PROJECT CONTEXT - Read CLAUDE.md, git log/blame (view-only)
2. CODE PATH TRACING - Entry point to failure
3. LINE-BY-LINE ANALYSIS - Mark suspicious code
4. REGRESSION ANALYSIS - Recent changes impact
5. ARCHITECTURAL FIX PLAN - Exact file:line changes with integration details
6. WRITE PLAN - To .claude/plans/bug-plan-creator-{id}-{hash5}-plan.md

Return:
- Root cause with confidence level
- Severity assessment
- Plan file path
- TOTAL CHANGES count
```

Use `subagent_type: "bug-plan-creator-default"` and `run_in_background: true`.

### Step 3: Report Result

```
## Bug Investigation & Architectural Fix Plan Complete

**Plan File**: .claude/plans/bug-plan-creator-{id}-{hash5}-plan.md
**Severity**: [Critical/High/Medium/Low]
**Root Cause Confidence**: [High/Medium/Low]

### Root Cause

**Location**: [file:line]
**Problem**: [brief]
**Evidence**: [key evidence]

### Plan Contains
- Root cause specification with evidence
- Architectural fix with code structure
- Implementation steps with dependencies
- Exit Criteria with verification script

### Files to Fix

| File | Changes |
|------|---------|
| [path] | [count] |

### Next Steps

1. Review the architectural fix plan
2. Implement using one of:
   - `/implement-loop <plan-path>` - Iterative implementation with exit criteria verification
   - [Spec Kit](https://github.com/github/spec-kit) - `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
   - [OpenSpec](https://github.com/Fission-AI/OpenSpec) - `/openspec:proposal` → `/openspec:apply` → `/openspec:archive`
3. For large plans exceeding context limits: Add [Beads](https://github.com/grapeot/beads) for atomic task tracking that survives session boundaries
4. Run tests to verify fix and regression tests
```

## Workflow Diagram

```
/bug-plan-creator <error-description|log-file|command>
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: PROCESS INPUT                                         │
│                                                               │
│  • Load log files if path provided                            │
│  • Run diagnostic commands if specified                       │
│  • Parse error messages and stack traces                      │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: LAUNCH AGENT                                          │
│                                                               │
│  Agent: bug-plan-creator-default                              │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  1. EVIDENCE COLLECTION                                 │  │
│  │     • Analyze error messages and stack traces           │  │
│  │     • Identify affected files and functions             │  │
│  │                                                         │  │
│  │  2. ROOT CAUSE ANALYSIS                                 │  │
│  │     • Read relevant source files                        │  │
│  │     • Trace execution paths                             │  │
│  │     • Identify the actual bug location                  │  │
│  │                                                         │  │
│  │  3. FIX PLAN GENERATION                                 │  │
│  │     • Determine fix strategy                            │  │
│  │     • Specify exact code changes                        │  │
│  │     • Include regression test requirements              │  │
│  │                                                         │  │
│  │  4. WRITE PLAN FILE                                     │  │
│  │     → .claude/plans/bug-fix-{desc}-{hash5}-plan.md      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Plan file path                                             │
│  • Root cause summary                                         │
│  • Files to modify                                            │
│  • Next steps: /implement-loop                                │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Log file missing | Report error, continue with other data |
| Diagnostic fails | Report error, continue |
| Low confidence | Highlight, recommend review |
| No bug found | Report external/config causes |

## Example Usage

```bash
# Error log + description
/bug-plan-creator "TypeError: 'NoneType' at auth.py:45" "Login fails with no profile"

# Log file + report
/bug-plan-creator ./logs/error.log "API returns 500 on POST /users"

# Stack trace
/bug-plan-creator "$(cat stacktrace.txt)" "Crash on submit"

# With diagnostic instructions
/bug-plan-creator "ConnectionError: timeout" "Run 'docker logs db --tail 100'"
```
