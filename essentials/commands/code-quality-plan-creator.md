---
allowed-tools: Task, TaskOutput
argument-hint: "<file1> [file2] ... [fileN]"
description: LSP-powered architectural code quality analysis - generates comprehensive improvement plans for /implement-loop or OpenSpec
model: opus
context: fork
---

# Architectural Code Quality Planning (LSP-Powered)

Analyze code quality using **Claude Code's built-in LSP** for semantic code understanding and generate comprehensive **architectural improvement plans**. For large quality improvements that require structural changes, architectural planning with full context produces dramatically better results.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the code quality report FILE directly, not in chat.

## Why Architectural Quality Plans with LSP?

Architectural code quality analysis with full context produces dramatically better results:
- **Bird's eye view** - Understand the full codebase before analyzing
- **Complete information** - Read all relevant files, not just a few lines
- **Separated phases** - Discovery first, then analysis with full context
- **Mapped relationships** - Detect all dependencies between classes

**Architectural quality plans specify**:
- Exact code changes with before/after examples
- How improvements integrate with existing patterns (verified via LSP)
- Dependencies between fixes (discovered via call hierarchy)
- Exit criteria verification

**LSP Advantages**:
- Semantic code navigation (understands code structure)
- Accurate dead code detection (zero references verified)
- Cross-file reference checking
- Language-aware analysis

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

**Built-in LSP Operations Used**:
- `documentSymbol` — Get all symbols in a document
- `findReferences` — Find all references to a symbol
- `goToDefinition` — Find where a symbol is defined
- `incomingCalls`/`outgoingCalls` — Build call hierarchy

## What Good Architectural Quality Plans Include

1. **Clear Issue Specification (LSP-Verified)**
   - Exact location of quality issues (file:line)
   - Symbol references and call hierarchy
   - Unused elements verified via findReferences

2. **Architectural Improvement Specification**
   - Exact code changes with before/after
   - How changes align with project patterns
   - Dependencies verified via LSP call graph
   - Pattern consistency requirements

3. **Implementation Steps**
   - Ordered fix sequence with LSP-verified dependencies
   - Testing requirements
   - Verification commands

4. **Exit Criteria**
   - Quality score target (≥9.1/10)
   - Test commands that must pass
   - Linting/formatting verification

## Arguments

File paths to analyze (one agent spawned per file):
- Single file: `/code-quality-plan-creator src/services/auth_service`
- Multiple files: `/code-quality-plan-creator src/agent src/hitl src/app`
- Glob pattern: `/code-quality-plan-creator agent/*`

## Instructions

### Step 1: Parse and Validate Input

Parse `$ARGUMENTS` to extract the list of files to analyze.

Validate each file path exists before proceeding. If a file doesn't exist, report it and skip.

### Step 2: Launch Architectural Analysis Agents in Background

For EACH file in the list, launch a `code-quality-plan-creator` agent **in the background** using the Task tool with `run_in_background: true`:

```
Create a comprehensive architectural quality improvement plan with maximum depth and verbosity using built-in LSP.

File to analyze: <file-path>

Requirements:
- Produce a VERBOSE architectural plan suitable for /implement-loop or OpenSpec
- Use LSP tools for semantic code understanding
- Include complete improvement specifications (not just what to change, but HOW)
- Specify exact code structures and pattern alignments
- Provide ordered improvement steps with LSP-verified dependencies
- Include exit criteria with verification commands
- Target quality score: ≥9.1/10

Perform a comprehensive code quality analysis following your 7-phase process with built-in LSP:

0. CONTEXT GATHERING (Do this FIRST using built-in):
   - Use Glob to locate CLAUDE.md, README.md, devguides/style guides
   - Use Grep to find files that IMPORT this file (consumers)
   - Use Glob to find sibling files in the same directory
   - Use Glob to locate test files
   - Summarize project coding standards and patterns from related files

1. CODE ELEMENT EXTRACTION (using LSP) - Use documentSymbol and goToDefinition to catalog:
   - All classes, functions, methods, interfaces
   - Symbol kinds, line ranges, signatures
   - Complete symbol hierarchy with depth=2

2. SCOPE & VISIBILITY ANALYSIS (using LSP):
   - Use findReferences for each public element
   - Identify unused elements (zero references found)
   - Cross-reference with consumer usage from Phase 0

3. CALL HIERARCHY MAPPING (using LSP):
   - Build call graph using findReferences
   - Find entry points (no callers)
   - Find orphaned code (dead code with no callers)

4. QUALITY ISSUE IDENTIFICATION - Including:
   - Code smells (complexity, design, naming, duplication)
   - SOLID principles violations (SRP, OCP, LSP, ISP, DIP)
   - DRY/KISS/YAGNI violations
   - Security vulnerability patterns (OWASP-aligned) using Grep
   - Technical debt estimation
   - Cognitive complexity measurement
   - PROJECT STANDARDS COMPLIANCE (from context gathered in Phase 0)
   - CROSS-FILE CONSISTENCY (patterns match siblings/consumers)
   - LSP-verified unused public API elements

5. ARCHITECTURAL IMPROVEMENT PLAN GENERATION - Prioritized fixes with before/after examples

6. WRITE PLAN FILE - Write to .claude/plans/code-quality-plan-creator-{filename}-{hash5}-plan.md (with 5-char hash)

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

This provides all information needed for implementation.
```

Use `subagent_type: "code-quality-plan-creator"` for each Task tool invocation.

**Launch ALL agents in a single message** with `run_in_background: true` to enable parallel execution.

### Step 3: Wait for Specialist Completion

Use `TaskOutput` with `block: true` to wait for each code-quality-plan-creator agent to complete.

For each completed agent, collect:
- File path
- Quality score
- Issues found (by priority)
- LSP analysis stats
- Implementation recommendation (Changes Required: Yes/No)
- Plan file path
- List of changes to implement

### Step 4: Present Implementation Options

From each agent's output, extract:
1. The file path analyzed
2. The plan file path (e.g., `.claude/plans/code-quality-plan-creator-filename-3m8k5-plan.md` with 5-char hash)
3. Whether changes are required (`Changes Required: Yes/No`)
4. Quality scores, issue counts, and LSP statistics

Present the analysis results and implementation options to the user:

```
## Architectural Code Quality Planning Complete (LSP-Powered)

### Analysis Results

**Tool Used**: built-in LSP (semantic code navigation)

| File | Current Score | Projected Score | Issues | LSP Symbols | Changes Required |
|------|---------------|-----------------|--------|-------------|------------------|
| [path1] | 6.8/10 | 9.2/10 | [count] | [count] | Yes |
| [path2] | 8.5/10 | 9.3/10 | [count] | [count] | Yes |
| [path3] | 9.5/10 | - | 0 | [count] | No (already clean) |

**Files Needing Changes**: [count]
**Files Already Clean**: [count]
**Total Issues Found**: [count]

### LSP Analysis Statistics

**Total Symbols Analyzed**: [count across all files]
**Total References Checked**: [count]
**Unused Elements Found via LSP**: [count]
**Dead Code Identified via LSP**: [count]

### Plan Contains
- Issue specifications with LSP-verified locations
- Architectural improvements with code structure
- Implementation steps with LSP-verified dependencies
- Exit Criteria with verification script

### Plan Files Generated

- `.claude/plans/code-quality-plan-creator-file1-{hash5}-plan.md`
- `.claude/plans/code-quality-plan-creator-file2-{hash5}-plan.md`

### Next Steps

1. Review the architectural plan files in `.claude/plans/`
2. Implement using one of:
   - `/implement-loop <plan-path>` - Iterative implementation with exit criteria verification
   - [OpenSpec](https://github.com/Fission-AI/OpenSpec) - `/proposal-creator <plan-path>` → `/spec-loop <change-id>`
3. For large plans exceeding context limits: `/beads-creator` → `/beads-loop` for atomic task tracking that survives session boundaries
4. After implementation: Run linters/formatters/type checkers
```

## Workflow Diagram

> **Note**: This is a simplified view. The agent performs 7 detailed phases internally with ReAct reflection checkpoints.

```
/code-quality-plan-creator <file1> <file2> ...
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR STEP 1: PARSE & VALIDATE                         │
│                                                               │
│  • Validate file paths exist                                  │
│  • Expand glob patterns                                       │
│  • Build file list for analysis                               │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR STEP 2: LAUNCH AGENTS (PARALLEL)                 │
│                                                               │
│  Agent: code-quality-plan-creator (one per file)       │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 0: CONTEXT GATHERING                        │  │
│  │  • Glob: CLAUDE.md, README.md, DEVGUIDE.md         │  │
│  │  • Grep: Find files importing target      │  │
│  │  • Glob: Find sibling files for pattern comparison  │  │
│  │  • Extract project coding standards                     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 1: CODE ELEMENT EXTRACTION (LSP)            │  │
│  │  • read_file: Read complete file contents               │  │
│  │  • documentSymbol (depth=2): Catalog symbols      │  │
│  │  • goToDefinition: Analyze each symbol in detail           │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 2: SCOPE & VISIBILITY ANALYSIS (LSP)        │  │
│  │  • findReferences for each public element     │  │
│  │  • Identify unused elements (zero references)           │  │
│  │  • Cross-reference with consumer usage                  │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 3: CALL HIERARCHY MAPPING (LSP)             │  │
│  │  • Build call graph via findReferences        │  │
│  │  • Find entry points (no callers)                       │  │
│  │  • Find orphaned/dead code (no callers)                 │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 3.5: REFLECTION CHECKPOINT (ReAct)          │  │
│  │  • Verify element mapping completeness                  │  │
│  │  • Confirm scope analysis accuracy                      │  │
│  │  • Validate call hierarchy correctness                  │  │
│  │  • Check context alignment with project standards       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 4: QUALITY ISSUE IDENTIFICATION             │  │
│  │  • 11 quality dimensions (SOLID, DRY, KISS, YAGNI...)   │  │
│  │  • Cognitive/Cyclomatic complexity measurement          │  │
│  │  • Grep for security patterns (OWASP)     │  │
│  │  • Project standards compliance check                   │  │
│  │  • Advanced metrics (Halstead, ABC, CBO, LCOM, RFC)     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 4.5: REFLECTION CHECKPOINT (ReAct)          │  │
│  │  • Verify all 11 dimensions checked                     │  │
│  │  • Confirm evidence quality with LSP references         │  │
│  │  • Eliminate false positives against project context    │  │
│  │  • Validate improvement feasibility                     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 5: IMPROVEMENT PLAN GENERATION              │  │
│  │  • Prioritize issues by impact                          │  │
│  │  • Generate before/after code examples                  │  │
│  │  • Calculate projected score after fixes                │  │
│  │  • Ensure projected score ≥9.1/10                       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 6: WRITE PLAN FILE                          │  │
│  │  → .claude/plans/code-quality-plan-creator-      │  │
│  │    {filename}-{hash5}-plan.md                           │  │
│  │                                                         │  │
│  │  Plan includes:                                         │  │
│  │  • Status/Mode headers                                  │  │
│  │  • Files (canonical list)                               │  │
│  │  • Code Context, External Context (with Purpose notes)  │  │
│  │  • Risk Analysis (technical, integration, rollback)     │  │
│  │  • Architectural Narrative (with Stakeholders)          │  │
│  │  • LSP Analysis Summary                                 │  │
│  │  • Implementation Plan (per-file with TOTAL CHANGES)    │  │
│  │  • Testing Strategy                                     │  │
│  │  • Success Metrics                                      │  │
│  │  • Exit Criteria                                        │  │
│  │  • Post-Implementation Verification                     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASE 7: REPORT TO ORCHESTRATOR                   │  │
│  │  • Minimal output (plan file path, scores, stats)       │  │
│  │  • User reviews plan FILE directly                      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR STEP 3: COLLECT RESULTS                          │
│                                                               │
│  • TaskOutput (block: true) for each agent                    │
│  • Gather plan file paths and scores                          │
│  • Collect LSP analysis statistics                            │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR STEP 4: REPORT RESULTS                           │
│                                                               │
│  Output per file:                                             │
│  • Plan file path                                             │
│  • Quality score (current → projected)                        │
│  • Total changes required                                     │
│  • LSP analysis statistics                                    │
│  • Next steps: /implement-loop or OpenSpec         │
└───────────────────────────────────────────────────────────────┘
```

## Example Usage

```bash
# Architectural quality plan with LSP for multiple files
/code-quality-plan-creator src/agent src/hitl src/app

# Analyze entire directory (use glob expansion)
/code-quality-plan-creator agent/*

# Single file architectural analysis with LSP
/code-quality-plan-creator src/services/auth_service
```
