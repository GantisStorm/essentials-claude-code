---
allowed-tools: Task
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

For EACH file, launch agent:

```
Analyze code quality: <file-path>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:code-quality-plan-creator-default"
prompt: "Analyze code quality: <file-path>"
```

**Launch ALL agents in a single message for parallel execution.** Results return directly from each Task call.

### Step 3: Report Results

```
## Code Quality Analysis Complete (LSP-Powered)

| File | Current | Projected | Issues | Changes Required |
|------|---------|-----------|--------|------------------|
| [path] | 6.8/10 | 9.2/10 | [N] | Yes |

Plans: .claude/plans/code-quality-*.md

Next Steps:
1. Review plan files
2. Execute directly (loop or swarm are interchangeable):
   - `/plan-loop <plan-path>` or `/plan-swarm <plan-path>`
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
