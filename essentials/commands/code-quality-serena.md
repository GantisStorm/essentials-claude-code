---
allowed-tools: Task, TaskOutput
argument-hint: <file1> [file2] ... [fileN]
description: Analyze code quality for files using Serena LSP and automatically implement improvements (project)
---

Analyze code quality for the specified files by spawning parallel `code-quality-serena` agents (using Serena LSP tools), then automatically dispatch `file-editor-default` agents to implement improvements.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the code quality report FILE directly, not in chat.

## Arguments

- File paths to analyze (one agent spawned per file)

## Instructions

### Step 1: Parse Arguments

Parse `$ARGUMENTS` to extract the list of files to analyze.

Validate each file path exists before proceeding. If a file doesn't exist, report it and skip.

### Step 2: Launch Quality Analyzers in Background

For EACH file in the list, launch a `code-quality-serena` agent **in the background** using the Task tool with `run_in_background: true`:

```
Analyze code quality for the specified file using Serena LSP tools.

File to analyze: <file-path>

Perform a comprehensive code quality analysis following your 7-phase process with Serena LSP:

0. CONTEXT GATHERING (Do this FIRST using Serena):
   - Use find_file to locate CLAUDE.md, README.md, devguides/style guides
   - Use search_for_pattern to find files that IMPORT this file (consumers)
   - Use list_dir to find sibling files in the same directory
   - Use find_file to locate test files
   - Summarize project coding standards and patterns from related files

1. CODE ELEMENT EXTRACTION (using LSP) - Use get_symbols_overview and find_symbol to catalog:
   - All classes, functions, methods, interfaces
   - Symbol kinds, line ranges, signatures
   - Complete symbol hierarchy with depth=2

2. SCOPE & VISIBILITY ANALYSIS (using LSP):
   - Use find_referencing_symbols for each public element
   - Identify unused elements (zero references found)
   - Cross-reference with consumer usage from Phase 0

3. CALL HIERARCHY MAPPING (using LSP):
   - Build call graph using find_referencing_symbols
   - Find entry points (no callers)
   - Find orphaned code (dead code with no callers)

4. QUALITY ISSUE IDENTIFICATION - Including:
   - Code smells (complexity, design, naming, duplication)
   - SOLID principles violations (SRP, OCP, LSP, ISP, DIP)
   - DRY/KISS/YAGNI violations
   - Security vulnerability patterns (OWASP-aligned) using search_for_pattern
   - Technical debt estimation
   - Cognitive complexity measurement
   - PROJECT STANDARDS COMPLIANCE (from context gathered in Phase 0)
   - CROSS-FILE CONSISTENCY (patterns match siblings/consumers)
   - LSP-verified unused public API elements

5. IMPROVEMENT PLAN GENERATION - Prioritized fixes with before/after examples

6. WRITE PLAN FILE - Write to .claude/plans/code-quality-serena-{filename}-{hash5}-plan.md (with 5-char hash)

7. OUTPUT FORMAT - Structured report for orchestrator with LSP stats

IMPORTANT: Your output MUST include:
- Project context summary (standards found, related files analyzed)
- LSP analysis stats (symbols found, references checked, unused elements)
- Quality scores with the 11-dimension scoring rubric
- Complexity metrics (cyclomatic, cognitive, maintainability index)
- Technical debt estimate in hours
- Security issues summary
- Project standards compliance summary
- Cross-file consistency findings
- The "Implementation Recommendation" section with:
  - Changes Required: Yes/No
  - File path
  - Plan file path
  - **Current Score**: X.XX/10
  - **Projected Score After Fixes**: X.XX/10 (MUST be ≥9.1)
  - **TOTAL CHANGES**: N (exact number of changes to implement)
  - Numbered list of changes to implement (1 through N)
  - Priority level
  - Complexity estimate

**MINIMUM SCORE REQUIREMENT**: If current score is below 9.1, you MUST identify
enough fixes to bring the projected score to 9.1 or higher.

This enables automatic dispatch to file-editor-default agents.
```

Use `subagent_type: "code-quality-serena"` for each Task tool invocation.

**Launch ALL agents in a single message** with `run_in_background: true` to enable parallel execution.

### Step 3: Wait for Analysis Completion

Use `TaskOutput` with `block: true` to wait for each code-quality-serena agent to complete.

For each completed agent, collect:
- File path
- Quality score
- Issues found (by priority)
- LSP analysis stats
- Implementation recommendation (Changes Required: Yes/No)
- Plan file path
- List of changes to implement

### Step 4: Parse Analysis Results

From each agent's output, extract:
1. The file path analyzed
2. The plan file path (e.g., `.claude/plans/code-quality-serena-filename-3m8k5-plan.md` with 5-char hash)
3. Whether changes are required (`Changes Required: Yes/No`)
4. Total fixes count and priority level

Group files by:
- **Needs Changes**: Files with `Changes Required: Yes` and a plan file path
- **Clean**: Files with `Changes Required: No`

### Step 5: Auto-Spawn File Editors for Files Needing Changes

For each file in the "Needs Changes" group, launch a `file-editor-default` agent **in the background**.

**CRITICAL**: Pass ONLY the plan file path. Do NOT paste plan contents - this avoids context pollution.

```
Execute the code quality plan on your assigned file.

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
   - `TOTAL CHANGES` from code-quality-serena's plan file (.claude/plans/code-quality-serena-*.md)
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
   | [path] | 6 | 6 | ✓ Complete |
   | [path] | 4 | 3 | ⚠ Missing 1 - Re-dispatching |
   ```

### Step 8: Report Comprehensive Summary

After all agents complete, provide a detailed summary:

```
## Code Quality Analysis & Implementation Summary (LSP-Powered)

### Analysis Phase

**Files Analyzed**: [count]
**Analysis Agents**: [count] code-quality-serena agents completed
**Tool Used**: Serena LSP (semantic code navigation)

| File | Quality Score | Issues Found | LSP Symbols | Changes Required |
|------|---------------|--------------|-------------|------------------|
| [path] | X/10 | [count] | [count] | Yes/No |

### LSP Analysis Statistics

**Total Symbols Analyzed**: [count across all files]
**Total References Checked**: [count]
**Unused Elements Found via LSP**: [count]
**Dead Code Identified via LSP**: [count]

### Implementation Phase

**Files Modified**: [count]
**Editor Agents**: [count] completed

| File | Status | Changes Made | Regression |
|------|--------|--------------|------------|
| [path] | ✓ Complete | [count] changes | Clean |

### Fix Verification Results

| File | Fixes Identified | Fixes Completed | Re-dispatches | Status |
|------|------------------|-----------------|---------------|--------|
| [path] | 6 | 6 | 0 | ✓ All Complete |

### Issue Summary by Priority

| Priority | Found | Fixed | Remaining |
|----------|-------|-------|-----------|
| Critical | X | X | X |
| High | X | X | X |
| Medium | X | X | X |
| Low | X | X | X |

### Issue Summary by Category

| Category | Found | Fixed | Remaining |
|----------|-------|-------|-----------|
| Code Smells | X | X | X |
| SOLID Violations | X | X | X |
| DRY/KISS/YAGNI | X | X | X |
| Security (OWASP) | X | X | X |
| Type Safety | X | X | X |
| Dead Code (LSP) | X | X | X |
| Unused Elements (LSP) | X | X | X |
| Project Standards | X | X | X |

### Quality Score Summary

| File | Before | After | Target (9.1) | Status |
|------|--------|-------|--------------|--------|
| [path] | 6.87 | 9.2 | 9.1 | ✓ Met |

**Files meeting 9.1 threshold**: [count]/[total]

### Overall Statistics

- **Total issues found**: [count]
- **Total issues fixed**: [count]
- **Total fixes verified**: [count] (must equal fixes identified)
- **Re-dispatch count**: [count] (files needing retry)
- **Files improved**: [count]
- **Files already clean**: [count]
- **Average quality score**: [X/10] (target: 9.1+)
- **LSP-powered analysis**: ✓ Semantic code navigation used
- **Unused public API found**: [count] (verified against consumers)

### Next Steps

- Run project linters, formatters, and type checkers (refer to CLAUDE.md)
- Review changes with `git diff`
- Commit if satisfied
```

## Workflow Diagram

```
/code-quality-serena <file1> <file2> ...
    │
    ▼
┌─────────────────────┐
│ Parse & validate    │
│ file arguments      │
└─────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch code-quality-serena agents (LSP)     │◄── run_in_background: true
│ (one per file, parallel)                    │
│                                             │
│  Uses: get_symbols_overview, find_symbol,  │
│         find_referencing_symbols,           │
│         search_for_pattern                  │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ TaskOutput (block) for each analyzer        │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Parse results       │
│ Extract plan paths  │
└─────────────────────┘
    │
    ├── Clean files ──► Skip
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch file-editor-default agents           │◄── Passes plan file path
│ (one per file needing changes, parallel)    │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ VERIFY ALL FIXES IMPLEMENTED                │
│ - Compare counts, re-dispatch if needed     │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report comprehensive│
│ summary with LSP    │
│ statistics          │
└─────────────────────┘
```

## Example Usage

```bash
# Analyze and fix multiple files with LSP
/code-quality-serena src/agent src/hitl src/app

# Analyze entire directory (use glob expansion)
/code-quality-serena agent/*

# Single file analysis with LSP
/code-quality-serena src/services/auth_service
```

## Integration with Project Tools

After `/code-quality-serena` completes, run the project's code quality checks:

```bash
# Run project linters, formatters, and type checkers
# (refer to CLAUDE.md or project documentation for specific commands)
```

## Advantages of LSP-Powered Analysis

**Semantic Code Navigation:**
- Accurate symbol discovery (classes, methods, functions, interfaces)
- Precise reference finding (who calls what)
- Language-aware analysis (understands code structure)

**Better Dead Code Detection:**
- LSP can verify if symbols have zero references
- Cross-file reference checking
- Accurate call hierarchy mapping

**Improved Accuracy:**
- Language server understands syntax and semantics
- Type-aware analysis
- Project-wide symbol resolution

**Speed:**
- LSP indexes code for fast lookups
- Parallel analysis with cached symbol data
- Efficient reference finding
