---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <any-input>
description: Deep bug investigation with architectural fix plan generation - detailed enough to feed directly into /implement-loop, /tasks-creator, or /beads-creator
context: fork
model: opus
---

# Bug Investigation & Architectural Fix Planning

Investigate bugs from any input - error logs, stack traces, user reports. Creates an architectural fix plan with exact code specifications.

**Note**: Only view-only git commands allowed (no state modifications).

## Arguments

Takes any input:
- Error logs: `"TypeError: 'NoneType' at auth.py:45"`
- Stack traces: `"$(cat stacktrace.txt)"`
- Log files: `./logs/error.log`
- User reports: `"Login fails when user has no profile"`
- Diagnostic instructions: `"Check docker logs for api-service"`

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS`:
- If file path → use Read tool to load contents
- If inline text → extract error signals
- If diagnostic instructions → execute commands:
  - Docker logs: `docker logs <container> --tail 500`
  - Process logs: `journalctl -u <service>`

### Step 2: Launch Agent

Launch `bug-plan-creator-default` in background:

```
Investigate this bug and create an architectural fix plan.

## Input

<all gathered logs, errors, context>

## Requirements

- Produce a VERBOSE architectural fix plan suitable for /implement-loop, /tasks-creator, or /beads-creator
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
6. WRITE PLAN - To .claude/plans/bug-{id}-{hash5}-plan.md

Return:
- Root cause with confidence level
- Severity assessment
- Plan file path
- TOTAL CHANGES count
```

Use `subagent_type: "bug-plan-creator-default"` and `run_in_background: true`.

### Step 3: Report Result

```
## Bug Investigation Complete

**Plan**: .claude/plans/bug-{id}-{hash5}-plan.md
**Severity**: [Critical/High/Medium/Low]
**Root Cause Confidence**: [High/Medium/Low]

Root Cause: [file:line] - [brief description]

Next Steps:
1. Review the fix plan
2. `/implement-loop <plan-path>` - Direct implementation (80% of tasks)
3. `/tasks-creator <plan-path>` → `/tasks-loop` or RalphTUI - prd.json format
4. `/beads-creator <plan-path>` → `/beads-loop` or RalphTUI - For large fixes
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
/bug-plan-creator "TypeError: 'NoneType' at auth.py:45" "Login fails with no profile"
/bug-plan-creator ./logs/error.log "API returns 500 on POST /users"
/bug-plan-creator "$(cat stacktrace.txt)" "Crash on submit"
/bug-plan-creator "ConnectionError: timeout" "Run 'docker logs db --tail 100'"
```
