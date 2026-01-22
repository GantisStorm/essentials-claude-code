---
allowed-tools: Task, TaskOutput
argument-hint: "<file1> [file2] ... [fileN]"
description: LSP-powered architectural code quality analysis - generates comprehensive improvement plans for /implement-loop, /tasks-creator, or /beads-creator
context: fork
model: opus
---

# Architectural Code Quality Planning (LSP-Powered)

Analyze code quality using Claude Code's built-in LSP for semantic understanding. Generates architectural improvement plans.

**Use the right tool:**
- **Code quality improvements** → `/code-quality-plan-creator` (this command)
- **New features/enhancements** → `/plan-creator`
- **Bug fixes** → `/bug-plan-creator`

## Built-in LSP Operations

- `documentSymbol` — Get all symbols in a document
- `findReferences` — Find all references to a symbol
- `goToDefinition` — Find where a symbol is defined
- `incomingCalls`/`outgoingCalls` — Build call hierarchy

## Arguments

File paths to analyze (one agent per file):
- Single file: `/code-quality-plan-creator src/services/auth_service`
- Multiple files: `/code-quality-plan-creator src/agent src/hitl src/app`
- Glob pattern: `/code-quality-plan-creator agent/*`

## Instructions

### Step 1: Parse Input

Parse `$ARGUMENTS` to extract file list. Validate each path exists.

### Step 2: Launch Agents

For EACH file, launch background agent:

```
Analyze code quality: <file-path>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:code-quality-plan-creator-default"
run_in_background: true
prompt: "Analyze code quality: <file-path>"
```

**Launch ALL agents in a single message for parallel execution.**

### Step 3: Collect Results

Use `TaskOutput` with `block: true` for each agent. Collect scores, stats, plan paths.

### Step 4: Report Results

```
## Code Quality Analysis Complete (LSP-Powered)

| File | Current | Projected | Issues | Changes Required |
|------|---------|-----------|--------|------------------|
| [path] | 6.8/10 | 9.2/10 | [N] | Yes |

Plans: .claude/plans/code-quality-*.md

Next Steps:
1. Review plan files
2. `/implement-loop <plan-path>` - Direct implementation (80% of tasks)
3. `/tasks-creator <plan-path>` → `/tasks-loop` or RalphTUI - prd.json format
4. `/beads-creator <plan-path>` → `/beads-loop` or RalphTUI - For large improvements
```

## Example Usage

```bash
/code-quality-plan-creator src/agent src/hitl src/app
/code-quality-plan-creator agent/*
/code-quality-plan-creator src/services/auth_service
```
