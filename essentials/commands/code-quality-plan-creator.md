---
allowed-tools: Task, TaskOutput
argument-hint: "<file1> [file2] ... [fileN]"
description: LSP-powered architectural code quality analysis - generates comprehensive improvement plans for /implement-loop, /tasks-creator, or /beads-creator
context: fork
---

# Architectural Code Quality Planning (LSP-Powered)

Analyze code quality using Claude Code's built-in LSP for semantic understanding. Generates architectural improvement plans.

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

For EACH file, launch `code-quality-plan-creator-default` in background:

```
Create an architectural quality improvement plan using built-in LSP.

File: <file-path>

Requirements:
- Produce a VERBOSE architectural plan suitable for /implement-loop, /tasks-creator, or /beads-creator
- Use LSP tools for semantic code understanding
- Include complete improvement specifications (not just what, but HOW)
- Target quality score: ≥9.1/10
- Include exit criteria with verification commands

Phases:
0. CONTEXT GATHERING - CLAUDE.md, README, find consumers
1. CODE ELEMENT EXTRACTION (LSP) - documentSymbol, goToDefinition
2. SCOPE & VISIBILITY ANALYSIS (LSP) - findReferences for each public element
3. CALL HIERARCHY MAPPING (LSP) - Build call graph, find dead code
4. QUALITY ISSUE IDENTIFICATION - 11 dimensions, SOLID, security patterns
5. IMPROVEMENT PLAN GENERATION - Prioritized fixes with before/after
6. WRITE PLAN - .claude/plans/code-quality-{filename}-{hash5}-plan.md

Return:
- Current score, projected score
- LSP stats (symbols, references)
- Plan file path
- TOTAL CHANGES count
```

Use `subagent_type: "code-quality-plan-creator-default"` and `run_in_background: true`.

Launch ALL agents in a single message for parallel execution.

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
