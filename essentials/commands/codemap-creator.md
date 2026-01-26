---
allowed-tools: Task, TaskOutput, Bash
argument-hint: "<root_dir> [--ignore <patterns>] | --update <codemap> [--diff | --mr <id>]"
description: Generate or update hierarchical code map from any directory as root, with nested tree structure (project)
context: fork
model: opus
---

# Code Map Creator

Generate or update a hierarchical code map using Claude Code's built-in LSP tools. Maps functions, classes, variables, and imports in a nested tree structure.

## Modes

### Create Mode (default)
Generate a new codemap from scratch:
```bash
/codemap-creator src/
/codemap-creator . --ignore "node_modules,dist"
```

### Update Mode
Update an existing codemap with only changed files:
```bash
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --diff
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --mr 123
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --pr 456
```

## Built-in LSP Operations

- `documentSymbol` - Get all symbols in a document
- `findReferences` - Verify symbol usage
- `goToDefinition` - Find symbol definitions
- `hover` - Get signatures and descriptions

## Arguments

### Create Mode
- **Root directory** (required): Starting point for the tree
  - `/codemap-creator src/` → maps from `src/` as root
  - `/codemap-creator backend/services` → maps from `services/` as root
  - `/codemap-creator .` → maps entire project as root

- **Ignore patterns** (optional): Skip files/directories
  - `/codemap-creator src/ --ignore "*.test.ts,node_modules"`

### Update Mode
- **--update <codemap>** (required): Path to existing codemap to update
- **--diff** (optional): Use `git diff` to find changed files (uncommitted + staged)
- **--mr <id>** (optional): Use GitLab MR to find changed files (via `glab`)
- **--pr <id>** (optional): Use GitHub PR to find changed files (via `gh`)

If no diff source specified with --update, defaults to --diff.

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

### Step 1: Parse Input and Detect Mode

Parse `$ARGUMENTS` to determine mode:

**Update Mode** (if `--update` present):
1. Extract codemap path after `--update`
2. Detect diff source:
   - `--diff` → use `git diff --name-only` + `git diff --staged --name-only`
   - `--mr <id>` → use `glab mr diff <id> --name-only`
   - `--pr <id>` → use `gh pr diff <id> --name-only`
   - Default to `--diff` if no source specified
3. Get list of changed files

**Create Mode** (default):
1. **Root directory** (required, first argument)
   - If not provided, default to `.` (current directory)
   - Validate directory exists
2. **Ignore patterns** (optional `--ignore`)
   - Comma-separated patterns to skip

### Step 2: Get Changed Files (Update Mode Only)

Run the appropriate command to get changed files:

```bash
# For --diff (default)
git diff --name-only && git diff --staged --name-only

# For --mr <id>
glab mr diff <id> --name-only

# For --pr <id>
gh pr diff <id> --name-only
```

Filter to only files within the codemap's root directory.

### Step 3: Launch Agent

**Create Mode:**
```
subagent_type: "essentials:codemap-creator-default"
run_in_background: true
prompt: "MODE: create\nRoot: <root_dir>\nIgnore: <patterns or none>"
```

**Update Mode:**
```
subagent_type: "essentials:codemap-creator-default"
run_in_background: true
prompt: "MODE: update\nCodemap: <codemap_path>\nChanged files:\n- file1.ts\n- file2.ts\n..."
```

Wait with TaskOutput (block: true).

### Step 4: Report Result

**Create Mode:**
```
## Hierarchical Code Map Created (LSP)

**Root**: <root_dir>
**Map**: .claude/maps/code-map-{name}-{hash5}.json

### Totals

| Metric | Count |
|--------|-------|
| Directories | X |
| Files | X |
| Symbols | X |
| Exported | X |

Next: Read the map file for hierarchical code navigation.
```

**Update Mode:**
```
## Code Map Updated (LSP)

**Map**: <codemap_path>
**Source**: git diff | MR #X | PR #X
**Files Updated**: X
**Files Added**: X
**Files Removed**: X

### Changes

| File | Action | Symbols |
|------|--------|---------|
| path/to/file.ts | updated | 5 |
| path/to/new.ts | added | 3 |
| path/to/old.ts | removed | - |

Next: Codemap is current with latest changes.
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Root directory not found | Report error, suggest valid paths |
| Codemap not found (update) | Report error, suggest create mode |
| No files in tree | Report empty, suggest different root |
| No changed files (update) | Report "already up to date" |
| glab/gh not installed | Report error, suggest install |
| MR/PR not found | Report error, check ID |
| LSP fails for file | Log error, mark file, continue |

## Example Usage

```bash
# Create mode
/codemap-creator src/
/codemap-creator backend/services
/codemap-creator frontend/components --ignore "*.test.tsx,*.stories.tsx"
/codemap-creator .

# Update mode - git diff (uncommitted changes)
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --diff

# Update mode - from MR/PR
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --mr 123
/codemap-creator --update .claude/maps/code-map-src-a3f9e.json --pr 456
```
