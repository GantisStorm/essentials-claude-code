---
allowed-tools: Task, Bash, Read, AskUserQuestion
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

Takes any input — error info, file paths, reference material:
- Error logs: `"TypeError: 'NoneType' at auth.py:45"`
- Stack traces: `"$(cat stacktrace.txt)"`
- Log files: `./logs/error.log`
- User reports: `"Login fails when user has no profile"`
- Diagnostic instructions: `"Check docker logs for api-service"`
- Reference files: pass a code map, design doc, or any file as additional context

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS`:
- If file path → use Read tool to load contents
- If inline text → extract error signals
- If diagnostic instructions → execute commands:
  - Docker logs: `docker logs <container> --tail 500`
  - Process logs: `journalctl -u <service>`

### Step 2: Ask Clarifying Questions

Use AskUserQuestion to gather missing context. Ask only what's unclear — skip questions the user already answered in their input.

**Questions to consider** (ask 1-4 based on what's missing):

- **Reproduction**: Can you reproduce this? Always, intermittent, or specific conditions?
- **Timeline**: When did this start? Any recent changes (deploys, config, dependencies)?
- **Impact**: What's affected? Any workarounds currently in use?
- **Environment**: Any relevant environment details? (OS, versions, prod vs dev, config differences)

**If the input is already detailed enough** (clear error, obvious reproduction, sufficient context from logs), skip this step entirely and go straight to Step 3.

### Step 3: Launch Agent

Assemble the enriched prompt from gathered logs/errors + clarifying answers. Launch background agent:

```
Investigate bug and create fix plan:

<all gathered logs, errors, context>

<clarifying context from user answers, if any>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:bug-plan-creator-default"
run_in_background: true
prompt: "<assembled prompt with all context>"
```

Output a status message like "Investigating bug..." and **end your turn**. The system wakes you when the agent finishes.

### Step 4: Report Result

```
## Bug Investigation Complete

**Plan**: .claude/plans/bug-{id}-{hash5}-plan.md
**Severity**: [Critical/High/Medium/Low]
**Root Cause Confidence**: [High/Medium/Low]

Root Cause: [file:line] - [brief description]

Next Steps:
1. Review the fix plan
2. Execute directly:
   - `/plan-loop <plan-path>` (sequential)
   - `/plan-swarm <plan-path>` (parallel subagents)
   - `/plan-team <plan-path>` (Agent Teams with contracts)
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
