---
allowed-tools: Task, TaskOutput, Glob, Read
argument-hint: "<dir1> [dir2] ... [dirN]"
description: Generate DEVGUIDE.md architectural documentation using LSP (project)
context: fork
model: opus
---

# Document Creator

Generate hierarchical architectural documentation (DEVGUIDE.md) using Claude Code's built-in LSP tools. Supports multiple directories with parallel agent execution.

## Built-in LSP Operations

- `documentSymbol` — Extract symbols from files
- `findReferences` — Map dependencies
- `goToDefinition` — Detailed symbol analysis

## Arguments

Directory paths to document (one agent per directory):
- Single directory: `/document-creator src/services/`
- Multiple directories: `/document-creator src/services src/components src/lib`
- No argument: analyzes current directory (`.`)

## Instructions

### Step 1: Parse Input

Parse `$ARGUMENTS` to extract directory list:
- Split arguments by spaces
- If empty → use current directory (`.`)
- Validate each path exists as a directory

### Step 2: Check for Rules

Check if `.claude/rules` directory exists at project root:

```
Use Glob(".claude/rules/*.md") to find rules files.

If rules exist:
- Read each rules file to understand frontmatter paths
- Pass relevant rules info to agents

If no rules exist:
- Note this for agents to suggest creating rules in DEVGUIDE
```

### Step 3: Determine Output Paths

For each directory:
- If no DEVGUIDE.md exists → `<target-dir>/DEVGUIDE.md`
- If exists → `<target-dir>/DEVGUIDE_2.md` (increment until unused)

### Step 4: Launch Agents

For EACH directory, launch background agent:

```
Generate DEVGUIDE: <directory-path>
Output: <determined path>
Rules: <exists/not found>
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:document-creator-default"
run_in_background: true
prompt: "Generate DEVGUIDE: <dir>\nOutput: <path>\nRules: <status>"
```

**Launch ALL agents in a single message for parallel execution.**

### Step 5: Collect Results

Use `TaskOutput` with `block: true` for each agent. Collect output paths and status.

### Step 6: Report Results

```
## DEVGUIDE Documentation Created (LSP)

| Directory | Output | Status |
|-----------|--------|--------|
| [dir1] | [output path] | CREATED |
| [dir2] | [output path] | CREATED |

Rules Status: [Found N rules / No rules folder found]

Next Steps:
1. Review generated documentation
2. Commit the DEVGUIDE files
3. [If no rules] Consider adding .claude/rules for this directory
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Path not found | Report error, continue with other paths |
| Path is file not directory | Report error, continue with other paths |
| Empty directory | Generate minimal guide |
| Agent fails | Report error, suggest retry |

## Example Usage

```bash
/document-creator
/document-creator src/services/
/document-creator src/services src/components src/lib
/document-creator backend/src frontend/src
```
