---
allowed-tools: Task, TaskOutput
argument-hint: [directory] [--ignore <patterns>]
description: Generate comprehensive code maps with Serena LSP for symbol tracking and reference verification (project)
---

Generate a comprehensive code map using Serena LSP tools. Maps all functions, classes, variables, and imports with verification tracking.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the code map JSON file directly, not in chat.

## Arguments

- `[directory]` - Directory path to map (optional, defaults to `.` for entire project)
- `--ignore <patterns>` - Comma-separated patterns to ignore (optional, e.g., `--ignore "*.test.ts,__pycache__,node_modules"`)

## Instructions

### Step 1: Parse and Validate Input

Parse `$ARGUMENTS` to extract:
1. Target directory path (default to `.` if not provided)
2. Optional ignore patterns (`--ignore`)

**Default Behavior**: If no directory specified, map the entire project from root including all subfolders and modules.

**Ignore Patterns**: Can be file names, directory names, or glob patterns (e.g., `*.test.ts`, `__pycache__`, `node_modules`, `dist`).

Validate the directory exists before proceeding. If it doesn't exist, report the error.

### Step 2: Launch Code Map Agent

Launch the `codemap-creator-serena` agent using the Task tool:

```
Generate a comprehensive code map for the specified directory using Serena LSP tools.

Target directory: <directory-path or "." for root>
Ignore patterns: <patterns or "none">

Create a complete code map following the 7-phase process:

1. FILE DISCOVERY (Do this FIRST using Serena):
   - Use list_dir(relative_path="<directory>", recursive=true) to find all files
   - Apply ignore patterns to filter out unwanted files/directories
   - Build complete file manifest with total count

2. SYMBOL EXTRACTION (using LSP) for each file:
   - Use get_symbols_overview(relative_path="file", depth=2) to extract symbols
   - Catalog: imports, variables, constants, classes (with methods), functions
   - Track check_status: pending → in_progress → completed

3. REFERENCE VERIFICATION (using LSP):
   - Use find_referencing_symbols for key public symbols
   - Verify exports are actually used
   - Document findings in notes array

4. DEPENDENCY MAPPING:
   - Identify import sources (stdlib, third-party, local)
   - Find consumer files using search_for_pattern
   - Build dependency relationships

5. GENERATE SUMMARY:
   - Calculate totals (files, classes, functions, variables)
   - Group by package/directory
   - Add package descriptions

6. WRITE MAP FILE:
   - Write to .claude/maps/code-map-{directory}-{hash5}.json
   - Use 5-character hash for uniqueness
   - Create directory if needed

7. REPORT OUTPUT:
   - Statistics summary
   - Packages discovered
   - Serena verification stats
   - Map file path

OUTPUT FORMAT:

Your output MUST include:
- Total files mapped and verified counts
- Symbol counts (classes, functions, variables, imports)
- Package breakdown with descriptions
- Serena verification statistics
- The map file path

The JSON map must follow this exact structure:

{
  "generated_at": "YYYY-MM-DD",
  "description": "Complete codebase map with Serena LSP verification",
  "target_directory": "<directory>",
  "ignore_patterns": ["<pattern1>", "<pattern2>"],
  "serena_config": {
    "instructions": "...",
    "serena_tools_to_use": [...],
    "total_files": N,
    "files_completed": N,
    "files_pending": N,
    "files_in_progress": N,
    "files_with_errors": N
  },
  "files": {
    "path/to/file.py": {
      "check_status": "completed",
      "last_checked": "ISO-timestamp",
      "serena_checks": {
        "symbols_verified": true,
        "references_checked": true,
        "dependencies_mapped": true
      },
      "notes": [{...}],
      "imports": ["..."],
      "variables": [{"name": "...", "kind": "..."}],
      "classes": [{"name": "...", "kind": "Class", "methods": [...]}],
      "functions": [{"name": "...", "kind": "Function"}]
    }
  },
  "summary": {
    "total_files": N,
    "total_classes": N,
    "total_functions": N,
    "packages": {...}
  }
}
```

Use `subagent_type: "codemap-creator-serena"` for the Task tool invocation.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the codemap-creator-serena agent to complete.

Collect:
- Map file path
- Statistics (files, symbols, packages)
- Verification status
- Any errors encountered

### Step 4: Present Results

Present the code map results to the user:

```
## Code Map Generation Complete (Serena LSP)

### Map Statistics

**Target Directory**: [directory or "." (entire project)]
**Ignore Patterns**: [patterns or "none"]
**Map File**: `.claude/maps/code-map-[name]-[hash5].json`

| Metric | Count |
|--------|-------|
| Total Files | X |
| Files Verified | X |
| Classes | X |
| Functions | X |
| Variables | X |
| Imports | X |

### Packages Discovered

| Package | Files | Description |
|---------|-------|-------------|
| [name] | X | [description] |

### Serena Verification

| Check | Status |
|-------|--------|
| Symbols Verified | X files |
| References Checked | X files |
| Dependencies Mapped | X files |

### Next Steps

1. **View the map**: Read `.claude/maps/code-map-[name]-[hash5].json`
2. **Use for navigation**: Reference the map for code exploration
3. **Update later**: Re-run to refresh after code changes
```

## Workflow Diagram

```
/codemap-creator [directory] [--ignore <patterns>]
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: PARSE & VALIDATE                                      │
│                                                               │
│  • Parse directory argument (default: ".")                    │
│  • Parse --ignore patterns (e.g., "*.test.ts,node_modules")   │
│  • Validate directory exists                                  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: LAUNCH AGENT                                          │
│                                                               │
│  Agent: codemap-creator-serena                                │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  1. FILE DISCOVERY                                      │  │
│  │     • list_dir (recursive) to find all files            │  │
│  │     • Apply ignore patterns                             │  │
│  │     • Build file manifest                               │  │
│  │                                                         │  │
│  │  2. SYMBOL EXTRACTION                                   │  │
│  │     • get_symbols_overview for each file                │  │
│  │     • Extract imports, classes, functions, variables    │  │
│  │     • Track check_status: pending → in_progress → done  │  │
│  │                                                         │  │
│  │  3. REFERENCE VERIFICATION                              │  │
│  │     • find_referencing_symbols for public symbols       │  │
│  │     • Mark verified_used or potentially_unused          │  │
│  │                                                         │  │
│  │  4. DEPENDENCY MAPPING                                  │  │
│  │     • Track import sources                              │  │
│  │     • search_for_pattern for consumers                  │  │
│  │                                                         │  │
│  │  5. SUMMARY GENERATION                                  │  │
│  │     • Calculate totals (files, classes, functions)      │  │
│  │     • Group by package                                  │  │
│  │                                                         │  │
│  │  6. WRITE JSON MAP                                      │  │
│  │     → .claude/maps/code-map-{dir}-{hash5}.json          │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: COLLECT RESULTS                                       │
│                                                               │
│  • TaskOutput (block: true) wait for completion               │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 4: REPORT RESULTS                                        │
│                                                               │
│  Output:                                                      │
│  • Map file path                                              │
│  • Statistics (files, classes, functions, imports)            │
│  • Packages discovered                                        │
│  • Serena verification stats                                  │
└───────────────────────────────────────────────────────────────┘
```

## Example Usage

```bash
# Map entire project (default)
/code-map

# Map specific directory
/code-map src/

# Map with ignore patterns
/code-map --ignore "*.test.ts,__pycache__,node_modules"

# Map specific directory with ignore patterns
/code-map src/ --ignore "*.spec.ts,dist,coverage"

# Map entire project ignoring common patterns
/code-map . --ignore "node_modules,__pycache__,.git,dist,build"
```

## Use Cases

**Code Navigation:**
- Quickly find where classes/functions are defined
- Understand package structure
- Identify entry points

**Refactoring Planning:**
- See all symbols in a file before modifying
- Check references before renaming
- Identify unused code

**Documentation:**
- Generate API documentation from map
- Create architecture diagrams
- Onboard new team members

**Code Review:**
- Understand scope of changes
- Verify all symbols are used
- Check for orphaned code

## Map File Format

The generated JSON map includes:

```json
{
  "generated_at": "2025-12-30",
  "description": "Complete codebase map...",
  "target_directory": "src/",
  "ignore_patterns": ["*.test.ts", "node_modules"],

  "serena_config": {
    "instructions": "How to use this map for verification...",
    "serena_tools_to_use": ["get_symbols_overview", "find_referencing_symbols", ...],
    "total_files": 32,
    "files_completed": 32,
    "files_pending": 0,
    "files_in_progress": 0,
    "files_with_errors": 0
  },

  "files": {
    "package/module.py": {
      "check_status": "completed",
      "last_checked": "2025-12-30T00:00:00Z",
      "serena_checks": {
        "symbols_verified": true,
        "references_checked": true,
        "dependencies_mapped": true
      },
      "notes": [
        {"type": "verified_used", "count": 5, "reason": "All exports have references"}
      ],
      "imports": ["from pathlib import Path", ...],
      "variables": [{"name": "CONSTANT", "kind": "Constant"}],
      "classes": [{"name": "MyClass", "kind": "Class", "methods": ["__init__", "run"]}],
      "functions": [{"name": "helper", "kind": "Function"}]
    }
  },

  "summary": {
    "total_files": 32,
    "total_classes": 52,
    "total_functions": 95,
    "packages": {
      "agent": {"files": 13, "description": "Agent core logic and CLI"},
      "common": {"files": 5, "description": "Shared types and utilities"}
    }
  }
}
```

## Advantages of Serena LSP Mapping

**Accuracy:**
- Language server understands syntax and semantics
- Correct symbol kind identification (class vs function vs variable)
- Proper method extraction from classes

**Verification:**
- `find_referencing_symbols` validates symbol usage
- Identifies truly unused code
- Tracks verification status per file

**Comprehensive:**
- All symbol types captured
- Import tracking
- Dependency mapping
- Entire project or specific directory support
