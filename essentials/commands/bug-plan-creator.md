---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <any-input>
description: Deep bug investigation with architectural fix plan generation - works with any executor (loop or swarm)
context: fork
model: opus
---

# Bug Investigation & Architectural Fix Planning

Investigate bugs from any input - error logs, stack traces, user reports. Creates an architectural fix plan with exact code specifications.

**Use the right tool:**
- **Bug fixes** → `/bug-plan-creator` (this command)
- **New features/enhancements** → `/plan-creator`
- **Code quality improvements** → `/code-quality-plan-creator`

**Note**: Only view-only git commands allowed (no state modifications).

## Arguments

Takes any input:
- Error logs: `"TypeError: 'NoneType' at auth.py:45"`
- Stack traces: `"$(cat stacktrace.txt)"`
- Log files: `./logs/error.log`
- User reports: `"Login fails when user has no profile"`
- Diagnostic instructions: `"Check docker logs for api-service"`

**Tip:** Use `/prompt-creator "bug: ./logs/error.log <description>"` first to analyze logs and create a structured bug description, then pass both the description and original logs here.

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS`:
- If file path → use Read tool to load contents
- If inline text → extract error signals
- If diagnostic instructions → execute commands:
  - Docker logs: `docker logs <container> --tail 500`
  - Process logs: `journalctl -u <service>`

### Step 2: Launch Agent

Launch background agent with gathered context:

```
Investigate bug and create fix plan:

<all gathered logs, errors, context>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:bug-plan-creator-default"
run_in_background: true
prompt: "Investigate bug and create fix plan:\n\n<gathered context>"
```

Wait with TaskOutput (block: true).

### Step 3: Report Result

```
## Bug Investigation Complete

**Plan**: .claude/plans/bug-{id}-{hash5}-plan.md
**Severity**: [Critical/High/Medium/Low]
**Root Cause Confidence**: [High/Medium/Low]

Root Cause: [file:line] - [brief description]

Next Steps:
1. Review the fix plan
2. Execute directly (loop or swarm are interchangeable):
   - `/plan-loop <plan-path>` or `/plan-swarm <plan-path>`
3. Or convert to prd.json/beads first:
   - `/tasks-converter <plan-path>` → `/tasks-loop` or `/tasks-swarm`
   - `/beads-converter <plan-path>` → `/beads-loop` or `/beads-swarm`
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
