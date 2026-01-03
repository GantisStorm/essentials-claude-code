---
allowed-tools: Task, TaskOutput
argument-hint: [directory-or-files]
description: Generate DEVGUIDE.md architectural documentation using Serena LSP (project)
---

Generate hierarchical architectural documentation (DEVGUIDE.md) by analyzing code structure with Serena LSP tools.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the document FILE directly.

## Arguments

Takes **any input** (optional):
- Directory path: `src/services/`
- Multiple files: `src/auth.ts src/api.ts`
- No argument: analyzes current directory (`.`)

If no input provided, defaults to current directory.

## Instructions

### Step 1: Parse Input

Parse `$ARGUMENTS`:
- If directory path → analyze that directory
- If file paths → analyze those files (use parent directory for output)
- If empty → analyze current directory (`.`)

### Step 2: Determine Output Path

**Output Path Logic:**
- If no DEVGUIDE.md exists → `<target-dir>/DEVGUIDE.md`
- If DEVGUIDE.md exists → `<target-dir>/DEVGUIDE_2.md`
- If DEVGUIDE_2.md exists → `<target-dir>/DEVGUIDE_3.md`
- Continue incrementing until unused name found

### Step 3: Launch Agent

Launch `document-creator-serena` in background:

```
Generate DEVGUIDE.md architectural documentation using Serena LSP.

Target: <directory or files>
Output File: <determined path - DEVGUIDE.md or DEVGUIDE_N.md>

## Process

1. DIRECTORY ANALYSIS - Use list_dir to discover structure
2. SYMBOL EXTRACTION - Use get_symbols_overview for each file
3. PATTERN IDENTIFICATION - Use find_symbol for detailed analysis
4. REFERENCE MAPPING - Use find_referencing_symbols for dependencies
5. DEVGUIDE GENERATION - All sections with LSP-verified patterns
6. QUALITY VALIDATION

Return:
OUTPUT_FILE: <path>
STATUS: CREATED
```

Use `subagent_type: "document-creator-serena"` and `run_in_background: true`.

### Step 4: Report Result

```
===============================================================
DEVGUIDE CREATED (Serena LSP)
===============================================================

Target: [path]
Output File: [file path]

===============================================================
NEXT STEPS
===============================================================

1. Review: [output file]
2. Commit: git add && git commit

===============================================================
```

## Workflow Diagram

```
/document-creator [target]
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: PARSE INPUT                                           │
│                                                               │
│  • Parse directory path or file paths                         │
│  • Default to "." if empty                                    │
│  • Determine output path (DEVGUIDE.md or DEVGUIDE_N.md)       │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: LAUNCH AGENT                                          │
│                                                               │
│  Agent: document-creator-serena                               │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  1. DIRECTORY ANALYSIS                                  │  │
│  │     • list_dir to discover structure                    │  │
│  │     • Detect language and framework                     │  │
│  │     • Identify directory purpose                        │  │
│  │                                                         │  │
│  │  2. LSP SYMBOL EXTRACTION                               │  │
│  │     • get_symbols_overview for each file                │  │
│  │     • find_symbol for detailed analysis                 │  │
│  │     • Catalog code patterns                             │  │
│  │                                                         │  │
│  │  3. PATTERN IDENTIFICATION                              │  │
│  │     • Extract structural templates                      │  │
│  │     • Identify design patterns                          │  │
│  │     • find_referencing_symbols for dependencies         │  │
│  │                                                         │  │
│  │  4. DEVGUIDE GENERATION                                 │  │
│  │     • Overview, Templates, Patterns, Best Practices     │  │
│  │     • Directory structure with LSP annotations          │  │
│  │                                                         │  │
│  │  5. WRITE OUTPUT FILE                                   │  │
│  │     → {target}/DEVGUIDE.md (or DEVGUIDE_N.md)           │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Output file path                                           │
│  • Status: CREATED                                            │
│  • Next steps: Review, commit                                 │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Path not found | Report error, stop |
| Empty directory | Generate minimal guide |
| Agent fails | Report error, suggest retry |

## Example Usage

```bash
# Document current directory → ./DEVGUIDE.md
/document-creator

# Document specific directory → src/services/DEVGUIDE.md
/document-creator src/services/

# If DEVGUIDE.md exists → src/services/DEVGUIDE_2.md
/document-creator src/services/
```
