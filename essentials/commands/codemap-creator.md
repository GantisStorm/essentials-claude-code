---
allowed-tools: Task, TaskOutput
argument-hint: "<root_dir> [--ignore <patterns>]"
description: Generate hierarchical code map from any directory as root, with nested tree structure (project)
context: fork
---

# Code Map Creator

Generate a hierarchical code map using Claude Code's built-in LSP tools. Maps functions, classes, variables, and imports in a nested tree structure from any specified root directory.

## Built-in LSP Operations

- `documentSymbol` - Get all symbols in a document
- `findReferences` - Verify symbol usage
- `goToDefinition` - Find symbol definitions

## Arguments

- **Root directory** (required): Starting point for the tree
  - `/codemap-creator src/` → maps from `src/` as root
  - `/codemap-creator backend/services` → maps from `services/` as root
  - `/codemap-creator .` → maps entire project as root

- **Ignore patterns** (optional): Skip files/directories
  - `/codemap-creator src/ --ignore "*.test.ts,node_modules"`

## Hierarchical Output

The codemap shows a nested tree structure from your chosen root:

```
root_dir/
├── subdir1/
│   ├── file1.ts
│   │   └── symbols: [class UserService, function getUser...]
│   └── nested/
│       └── file2.ts
│           └── symbols: [interface Config...]
├── subdir2/
│   └── file3.ts
│       └── symbols: [function helper...]
└── index.ts
    └── symbols: [export *, function main...]
```

## Instructions

### Step 1: Parse Input

Parse `$ARGUMENTS`:
1. **Root directory** (required, first argument)
   - If not provided, default to `.` (current directory)
   - Validate directory exists
2. **Ignore patterns** (optional `--ignore`)
   - Comma-separated patterns to skip

### Step 2: Launch Agent

Launch `codemap-creator-default`:

```
Generate a hierarchical code map using built-in LSP tools.

Root Directory: <root_dir>
Ignore Patterns: <patterns or "none">

The map should be a NESTED TREE STRUCTURE where:
- Root directory is the top-level node
- Each subdirectory is a child node
- Each file contains its symbols
- Parent→child relationships are explicit

Phases:
1. TREE DISCOVERY - Build directory tree from root
2. SYMBOL EXTRACTION (LSP) - documentSymbol for each file
3. REFERENCE VERIFICATION (LSP) - findReferences for public symbols
4. HIERARCHY ASSEMBLY - Nest files under their parent directories
5. GENERATE SUMMARY - Totals per directory level
6. WRITE MAP - .claude/maps/code-map-{root}-{hash5}.json

Return:
- Map file path
- Tree statistics (directories, files, symbols per level)
- Verification status
```

Use `subagent_type: "codemap-creator-default"` and `run_in_background: true`.

### Step 3: Report Result

```
## Hierarchical Code Map Created (LSP)

**Root**: <root_dir>
**Map**: .claude/maps/code-map-{name}-{hash5}.json

### Tree Structure

| Level | Directories | Files | Symbols |
|-------|-------------|-------|---------|
| 0 (root) | - | X | X |
| 1 | X | X | X |
| 2 | X | X | X |

### Totals

| Metric | Count |
|--------|-------|
| Directories | X |
| Files | X |
| Classes | X |
| Functions | X |

Next: Read the map file for hierarchical code navigation.
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Root directory not found | Report error, suggest valid paths |
| No files in tree | Report empty, suggest different root |
| LSP fails for file | Log error, mark file, continue |

## Example Usage

```bash
/codemap-creator src/
/codemap-creator backend/services
/codemap-creator frontend/components --ignore "*.test.tsx,*.stories.tsx"
/codemap-creator .
```
