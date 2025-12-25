---
allowed-tools: Task, TaskOutput
argument-hint: <file1> [file2] ... [fileN]
description: Analyze code quality for files and automatically implement improvements (project)
---

Analyze code quality for the specified files by spawning parallel `code-quality-default` agents, then automatically dispatch `file-editor-default` agents to implement improvements.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the code quality report FILE directly, not in chat.

## Arguments

- File paths to analyze (one agent spawned per file)

## Instructions

### Step 1: Parse Arguments

Parse `$ARGUMENTS` to extract the list of files to analyze.

Validate each file path exists before proceeding. If a file doesn't exist, report it and skip.

### Step 2: Launch Quality Analyzers in Background

For EACH file in the list, launch a `code-quality-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Analyze code quality for the specified file.

File to analyze: <file-path>

Perform a comprehensive code quality analysis following your 7-phase process:

0. CONTEXT GATHERING (Do this FIRST):
   - Read CLAUDE.md, README.md, and any devguides/style guides
   - Find files that IMPORT this file (consumers) - use Grep
   - Find sibling files in the same directory - use Glob
   - Find test files for this module
   - Summarize project coding standards and patterns from related files

1. CODE ELEMENT EXTRACTION - Catalog all imports, globals, classes, functions, types
2. SCOPE & VISIBILITY ANALYSIS - Check private/public usage, detect unused elements
3. CALL HIERARCHY MAPPING - Build call graph, find orphaned code
4. QUALITY ISSUE IDENTIFICATION - Including:
   - Code smells (complexity, design, naming, duplication)
   - SOLID principles violations (SRP, OCP, LSP, ISP, DIP)
   - DRY/KISS/YAGNI violations
   - Security vulnerability patterns (OWASP-aligned)
   - Technical debt estimation
   - Data flow & taint analysis
   - Cognitive complexity measurement
   - PROJECT STANDARDS COMPLIANCE (from context gathered in Phase 0)
   - CROSS-FILE CONSISTENCY (patterns match siblings/consumers)
5. IMPROVEMENT PLAN GENERATION - Prioritized fixes with before/after examples
6. OUTPUT FORMAT - Structured report for orchestrator

IMPORTANT: Your output MUST include:
- Project context summary (standards found, related files analyzed)
- Quality scores with the 11-dimension scoring rubric
- Complexity metrics (cyclomatic, cognitive, maintainability index)
- Technical debt estimate in hours
- Security issues summary
- Project standards compliance summary
- Cross-file consistency findings
- The "Implementation Recommendation" section with:
  - Changes Required: Yes/No
  - File path
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

Use `subagent_type: "code-quality-default"` for each Task tool invocation.

**Launch ALL agents in a single message** with `run_in_background: true` to enable parallel execution.

### Step 3: Wait for Analysis Completion

Use `TaskOutput` with `block: true` to wait for each code-quality-default agent to complete.

For each completed agent, collect:
- File path
- Quality score
- Issues found (by priority)
- Implementation recommendation (Changes Required: Yes/No)
- List of changes to implement

### Step 4: Parse Analysis Results

From each agent's output, extract:
1. The file path analyzed
2. The plan file path (e.g., `.claude/plans/code-quality-filename-6k9f2-plan.md` with 5-char hash)
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
   - `TOTAL CHANGES` from code-quality-default's plan file
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

**Example re-dispatch prompt for missed fixes:**
```
Complete the remaining code quality fixes for this file.

File: <file-path>

## Missing Fixes (from original analysis)

The following fixes were identified but NOT implemented:

1. **[Missed Fix Title]** (line X-Y)
   - Problem: [description]
   - Fix: [exact change to make]

## Instructions

Implement ONLY the missing fixes listed above. These were part of the original
analysis but were not completed in the first pass.

Report back with confirmation that each missing fix has been applied.
```

### Step 8: Report Comprehensive Summary

After all agents complete, provide a detailed summary:

```
## Code Quality Analysis & Implementation Summary

### Analysis Phase

**Files Analyzed**: [count]
**Analysis Agents**: [count] completed

| File | Quality Score | Issues Found | Changes Required |
|------|---------------|--------------|------------------|
| [path] | X/10 | [count] | Yes/No |
| [path] | X/10 | [count] | Yes/No |

### Implementation Phase

**Files Modified**: [count]
**Editor Agents**: [count] completed

| File | Status | Changes Made | Regression |
|------|--------|--------------|------------|
| [path] | ✓ Complete | [count] changes | Clean |
| [path] | ✓ Complete | [count] changes | Clean |
| [path] | ⚠ Issues | [count] changes | [issues] |

### Fix Verification Results

| File | Fixes Identified | Fixes Completed | Re-dispatches | Status |
|------|------------------|-----------------|---------------|--------|
| [path] | 6 | 6 | 0 | ✓ All Complete |
| [path] | 4 | 4 | 1 | ✓ All Complete (after retry) |

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
| Dead Code | X | X | X |
| Project Standards | X | X | X |
| Cross-File Consistency | X | X | X |

### Project Standards Compliance

| File | Standards Score | Violations | Notes |
|------|-----------------|------------|-------|
| [path] | X% | [count] | [key issues] |

**Standards Sources**: CLAUDE.md, README.md, [other docs found]
**Related Files Analyzed**: [count] consumers, [count] siblings, [count] tests

### Complexity Metrics Summary

| File | Cyclomatic | Cognitive | Maintainability | Status |
|------|------------|-----------|-----------------|--------|
| [path] | X | X | X | ✓/✗ |

### Technical Debt Summary

| File | Debt (hours) | Debt Ratio | Priority |
|------|--------------|------------|----------|
| [path] | X.X | X% | P1-P4 |

**Total Technical Debt**: X hours
**Average Debt Ratio**: X%

### Quality Score Summary

| File | Before | After | Target (9.1) | Status |
|------|--------|-------|--------------|--------|
| [path] | 6.87 | 9.2 | 9.1 | ✓ Met |
| [path] | 8.5 | 9.3 | 9.1 | ✓ Met |
| [path] | 7.2 | 8.9 | 9.1 | ⚠ Below Target |

**Files meeting 9.1 threshold**: [count]/[total]

### Overall Statistics

- **Total issues found**: [count]
- **Total issues fixed**: [count]
- **Total fixes verified**: [count] (must equal fixes identified)
- **Re-dispatch count**: [count] (files needing retry)
- **Files improved**: [count]
- **Files already clean**: [count]
- **Average quality score**: [X/10] (target: 9.1+)
- **Total technical debt**: [X hours]
- **Security issues found**: [count]
- **SOLID violations**: [count]

### Next Steps

- Run project linters, formatters, and type checkers (refer to CLAUDE.md)
- Review changes with `git diff`
- Commit if satisfied
```

## Workflow Diagram

```
/code-quality <file1> <file2> <file3> ...
    │
    ▼
┌─────────────────────┐
│ Parse & validate    │
│ file arguments      │
└─────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch code-quality-default agents          │◄── run_in_background: true
│ (one per file, parallel)                    │
│                                             │
│  ┌────────────┐ ┌────────────┐ ┌────────┐   │
│  │ Analyzer 1 │ │ Analyzer 2 │ │ ... N  │   │
│  │ (file1)    │ │ (file2)    │ │        │   │
│  └────────────┘ └────────────┘ └────────┘   │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ TaskOutput (block) for each analyzer        │◄── Wait for all analyses
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Parse results       │
│ Group by needs      │
│ changes / clean     │
└─────────────────────┘
    │
    ├── Clean files ──► Skip (no action needed)
    │
    ▼
┌─────────────────────────────────────────────┐
│ Launch file-editor-default agents           │◄── run_in_background: true
│ (one per file needing changes, parallel)    │
│                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Editor 1 │ │ Editor 2 │ │ ... N    │     │
│  │ (file1)  │ │ (file2)  │ │          │     │
│  └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ TaskOutput (block) for each editor          │◄── Wait for all edits
└─────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────┐
│ VERIFY ALL FIXES IMPLEMENTED                │◄── CRITICAL STEP
│                                             │
│  For each file:                             │
│  - Compare: Fixes Identified vs Completed   │
│  - If mismatch: Re-dispatch for missed      │
│  - Loop until all fixes verified            │
└─────────────────────────────────────────────┘
    │
    ├── Mismatch? ──► Re-dispatch file-editor
    │                  for missed fixes only
    │                  │
    │                  ▼
    │                 Loop back to verify
    │
    ▼ (All verified)
┌─────────────────────┐
│ Aggregate results   │
│ from all agents     │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report comprehensive│
│ summary             │
└─────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| File doesn't exist | Skip file, report in summary |
| Analyzer agent fails | Report error, continue with other files |
| Editor agent fails | Report failure, continue with other files |
| No files need changes | Report all clean, skip editor phase |
| All agents fail | Report comprehensive error summary |
| **Fixes incomplete** | Re-dispatch editor with missed fixes only |
| **Score below 9.1** | Analyzer must add more fixes until projected ≥9.1 |
| **Re-dispatch fails** | Report specific missed fixes, mark for manual review |

## Example Usage

```bash
# Analyze and fix multiple files
/code-quality src/agent src/hitl src/app

# Analyze entire directory (use glob expansion)
/code-quality agent/*

# Single file analysis
/code-quality src/services/auth_service
```

## Integration with Project Tools

After `/code-quality` completes, run the project's code quality checks:

```bash
# Run project linters, formatters, and type checkers
# (refer to CLAUDE.md or project documentation for specific commands)
```

This ensures all changes pass the project's quality gates.

## Quality Thresholds Reference

The analysis uses these default thresholds to flag issues:

### Complexity Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Cyclomatic Complexity | ≤10 | 11-20 | >20 |
| Cognitive Complexity | ≤15 | 16-25 | >25 |
| Maintainability Index | ≥65 | 40-64 | <40 |
| Nesting Depth | ≤4 | 5-6 | >6 |
| Function Length (lines) | ≤50 | 51-100 | >100 |
| Parameters per Function | ≤5 | 6-7 | >7 |

### Quality Score Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Code Organization | 12% | Structure, modularity, separation of concerns |
| Naming Quality | 10% | Clear, consistent, meaningful names |
| Scope Correctness | 10% | Proper public/private usage, no leakage |
| Type Safety | 12% | Complete type hints, correct types |
| No Dead Code | 8% | No unused imports, functions, variables |
| No Duplication (DRY) | 8% | No copy-paste, extracted helpers |
| Error Handling | 10% | Proper exceptions, no silent failures |
| Modern Patterns | 5% | Modern language features, best practices |
| SOLID Principles | 10% | SRP, OCP, LSP, ISP, DIP compliance |
| Security (OWASP) | 10% | No injection, secrets, vulnerabilities |
| Cognitive Complexity | 5% | Readable, understandable code flow |

### SOLID Principles Quick Reference

| Principle | Description | Common Violations |
|-----------|-------------|-------------------|
| **S**ingle Responsibility | One reason to change | God classes, mixed concerns |
| **O**pen/Closed | Open for extension, closed for modification | if/switch chains for types |
| **L**iskov Substitution | Subtypes must be substitutable | Changed method contracts |
| **I**nterface Segregation | Many specific interfaces | Fat interfaces, unused methods |
| **D**ependency Inversion | Depend on abstractions | Concrete dependencies in logic |

### Security Patterns (OWASP Top 10 Aligned)

| Category | What to Check |
|----------|---------------|
| Injection | SQL/Command/Path injection, unsanitized input |
| Broken Auth | Hardcoded secrets, weak sessions |
| Data Exposure | Sensitive data in logs, unencrypted storage |
| XXE | Unsafe XML parsing |
| Broken Access Control | Missing permission checks |
| Misconfiguration | Debug mode, default credentials |
| XSS | Unescaped output |
| Insecure Deserialization | Unsafe serialization, eval-like constructs |
| Vulnerable Components | Outdated dependencies |
| Logging & Monitoring | Missing audit trails |

## Advanced Usage

### Analyzing with Specific Focus

You can ask for focused analysis in your prompt:

```bash
# Security-focused analysis
/code-quality src/api  # Will include OWASP security scan

# Performance-focused (add to your prompt)
"Analyze with focus on performance and complexity metrics"
```

### Interpreting Technical Debt

Technical debt is estimated in hours and categorized:

| Debt Type | Description | Priority |
|-----------|-------------|----------|
| Code Debt | Poor quality code needing cleanup | Medium |
| Design Debt | Architectural issues requiring refactoring | High |
| Test Debt | Missing or inadequate test coverage | Medium |
| Documentation Debt | Missing or outdated documentation | Low |

**Debt Ratio** = (Debt Hours / Development Hours) × 100
- < 5%: Healthy
- 5-10%: Manageable
- 10-20%: Concerning
- > 20%: Critical
