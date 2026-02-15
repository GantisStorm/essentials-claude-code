---
allowed-tools: Task, AskUserQuestion
argument-hint: "<file1> [file2] ... [fileN]"
description: LSP-powered architectural code quality analysis - works with any executor (loop or swarm)
context: fork
model: opus
---

# Architectural Code Quality Planning (LSP-Powered)

Analyze code quality using Claude Code's built-in LSP for semantic understanding. Generates architectural improvement plans.

**Use the right tool:**
- **Code quality improvements** → `/code-quality-plan-creator` (this command)
- **New features/enhancements** → `/plan-creator`
- **Bug fixes** → `/bug-plan-creator`

## Arguments

File paths to analyze (one agent per file):
- Single file: `/code-quality-plan-creator src/services/auth_service`
- Multiple files: `/code-quality-plan-creator src/agent src/hitl src/app`
- Glob pattern: `/code-quality-plan-creator agent/*`

## Instructions

### Step 1: Parse Input

Parse `$ARGUMENTS` to extract file list. Validate each path exists.

### Step 2: Ask Clarifying Questions

Use AskUserQuestion to gather missing context. Ask only what's unclear — skip questions the user already answered in their input.

**Questions to consider** (ask 1-4 based on what's missing):

- **Focus**: What kind of improvements matter most? (performance, readability, security, maintainability, all)
- **Constraints**: Any patterns or conventions to enforce? Any refactoring that's off-limits?
- **Priority**: Any known pain points or areas of concern in these files?
- **Exit criteria**: How will we verify improvements? Specific lint rules, test commands, or benchmarks?

**If the input is already detailed enough** (clear files, obvious focus area), skip this step entirely and go straight to Step 3.

### Step 3: Launch Agents

For EACH file, launch background agent with enriched context:

```
Analyze code quality: <file-path>

<clarifying context from user answers, if any>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:code-quality-plan-creator-default"
run_in_background: true
prompt: "<assembled prompt with file path and context>"
```

**Launch ALL agents in a single message for parallel execution.** Output a status message like "Analyzing N files..." and **end your turn**. The system wakes you when agents finish.

### Step 4: Report Results

```
## Code Quality Analysis Complete (LSP-Powered)

| File | Current | Projected | Issues | Changes Required |
|------|---------|-----------|--------|------------------|
| [path] | 6.8/10 | 9.2/10 | [N] | Yes |

Plans: .claude/plans/code-quality-*.md

Next Steps:
1. Review plan files
2. Execute directly:
   - `/plan-loop <plan-path>` (sequential)
   - `/plan-swarm <plan-path>` (parallel subagents)
   - `/plan-team <plan-path>` (Agent Teams with contracts)
3. Or convert to prd.json/beads first:
   - `/tasks-converter <plan-path>` → `/tasks-loop` or `/tasks-swarm`
   - `/beads-converter <plan-path>` → `/beads-loop` or `/beads-swarm`
```

## Example Usage

```bash
/code-quality-plan-creator src/agent src/hitl src/app
/code-quality-plan-creator agent/*
/code-quality-plan-creator src/services/auth_service
```
