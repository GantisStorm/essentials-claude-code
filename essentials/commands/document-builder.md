---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: [--mode=MODE] [OPTIONS] <path> [request]
description: Generate or edit architectural documentation following DEVGUIDE patterns (project)
---

Generate hierarchical architectural documentation (DEVGUIDE.md) or edit existing documentation. The slash command orchestrates while the document-builder-default agent analyzes code structure and generates/edits language-agnostic architectural guides.

**TWO MODES:**

1. **CREATE MODE** (default): Generate hierarchical DEVGUIDE.md files following architectural guide patterns
   - Analyzes code structure and extracts architectural patterns
   - Generates language-agnostic architectural guides at each directory level
   - Follows template structure: Overview → Sub-folder guides → Templates → Patterns → Best practices → Summary
   - Cross-references sub-folder guides

2. **EDIT MODE**: Edit existing documentation based on user requests
   - Takes path to existing document and user request
   - Applies changes while maintaining document structure
   - Similar to plugin-builder's iterative editing

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY analyzes and creates/edits documentation.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the document FILE directly, not in chat.

## Arguments

### Create Mode (default)

```bash
/document-builder <directory-path>
/document-builder --mode=create <directory-path>
```

- **directory-path**: Directory to analyze and generate DEVGUIDE.md for
  - Examples: `.`, `src/`, `src/services/`, `frontend/src/components/`
  - Generates DEVGUIDE.md in the target directory
  - Optionally generates hierarchical guides for sub-directories

### Edit Mode

```bash
/document-builder --mode=edit <document-path> "<user-request>"
```

- **document-path**: Path to existing DEVGUIDE.md or other documentation file
- **user-request**: Description of changes to make
  - Examples: "Add SSE pattern template", "Update service architecture section", "Add new component pattern"

## Instructions

### Step 1: Parse and Validate Arguments

Parse `$ARGUMENTS` to extract:
1. Mode (from `--mode=MODE` flag, defaults to `create`)
2. Target path (directory for create mode, file for edit mode)
3. User request (for edit mode only)

**Validation:**

For CREATE mode:
```bash
# Verify directory exists
ls -la <directory-path>
```

For EDIT mode:
```bash
# Verify document file exists
ls -la <document-path>
```

- If path missing or invalid: Report error and stop
- If mode invalid: Report error with valid modes (create, edit)
- If arguments malformed: Report usage example
- If edit mode but no user request: Report error, request required

### Step 2: Determine Mode and Scope

Based on arguments, determine:

**For CREATE Mode:**
```
Scope Analysis:
- Target Directory: [path]
- Primary language: [detect from file extensions in directory]
- Framework: [detect from dependencies/imports]
- Directory type: [services | components | api | lib | utils | etc.]
- Sub-directories: [list immediate sub-directories]
```

**For EDIT Mode:**
```
Edit Analysis:
- Document Path: [path to existing file]
- User Request: [changes requested]
- Document Type: [DEVGUIDE | README | etc.]
```

### Step 3: Generate Output File Path

Create output file path based on mode:

```bash
# Generate 5-char random hash
HASH=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

**For CREATE Mode:**
- `.claude/plans/document-builder-DEVGUIDE-{hash5}.md`

**For EDIT Mode:**
- `.claude/plans/document-builder-EDIT-{hash5}.md`

### Step 4: Launch Document Builder Agent

**CRITICAL**: The SLASH COMMAND orchestrates. The agent ONLY analyzes code and creates/edits documentation.

Launch `document-builder-default` agent **in background** using Task tool with `run_in_background: true`:

**For CREATE Mode:**

```
MODE: CREATE

Analyze the directory structure and code patterns to generate a hierarchical DEVGUIDE.md architectural guide.

Target Directory: <directory-path>
Output File: <generated file path>

## Your Task

Generate a language-agnostic architectural guide (DEVGUIDE.md) following the DEVGUIDE pattern:
- Overview of the directory's purpose and architecture
- Sub-folder guide links (if sub-directories exist)
- Code templates showing architectural patterns
- Design patterns and best practices
- Directory structure summary

You are ONLY responsible for analyzing code structure and creating the architectural guide. You do NOT orchestrate or interact with the user.

SYSTEMATIC PROCESS FOR CREATE MODE:

1. DIRECTORY ANALYSIS:
   - Analyze directory structure and file organization
   - Detect primary language/framework from file extensions
   - Identify directory type (services, components, api, lib, utils, etc.)
   - List immediate sub-directories for cross-referencing
   - Detect common architectural patterns in the code

2. CODE PATTERN EXTRACTION:
   - Use Glob to find all source files in directory
   - Use Grep to extract class/function/export patterns
   - Identify common code organization patterns
   - Extract structural templates (class structures, function patterns)
   - Find design patterns (providers, factories, hooks, etc.)

3. ARCHITECTURE IDENTIFICATION:
   - Identify architectural layers (if services: Core/Orchestrated/Internal)
   - Identify design patterns (Provider, Factory, SSE, etc.)
   - Extract common templates from existing code
   - Identify best practices from code structure

4. DEVGUIDE GENERATION:
   - Generate Overview section (directory purpose and architecture)
   - Generate Sub-folder Guides section (links to sub-directories)
   - Generate Templates section (code templates with comment dividers)
   - Generate Patterns section (architectural patterns identified)
   - Generate Best Practices section
   - Generate Directory Structure section
   - Generate Summary section

5. TEMPLATE FORMATTING:
   - Use language-agnostic pseudocode or detected language
   - Use comment dividers: // ============================================================================
   - Include section headers in templates
   - Show architectural structure, not implementation details

6. CROSS-REFERENCING:
   - Link to sub-directory DEVGUIDeS (e.g., [lib/api/DEVGUIDE.md](api/DEVGUIDE.md))
   - Reference related architectural patterns
   - Link to parent DEVGUIDE if not root

7. QUALITY VALIDATION:
   - Verify architectural focus (not code documentation)
   - Ensure language-agnostic templates
   - Check cross-references are valid
   - Verify all templates show architectural patterns

Return only:
OUTPUT_FILE: <path>
STATUS: CREATED
MODE: CREATE

DO NOT interact with user. The slash command handles all communication.
```

**For EDIT Mode:**

```
MODE: EDIT

Edit existing documentation based on user request.

Document Path: <document-path>
User Request: <user-request>
Output File: <generated file path>

## Your Task

Read the existing document, apply the requested changes, and maintain document structure and style.

You are ONLY responsible for editing the documentation. You do NOT orchestrate or interact with the user.

SYSTEMATIC PROCESS FOR EDIT MODE:

1. READ EXISTING DOCUMENT:
   - Read the complete existing document
   - Understand current structure and sections
   - Identify document type and style

2. ANALYZE USER REQUEST:
   - Parse user request for specific changes
   - Identify which sections need modification
   - Determine if new sections need to be added

3. APPLY CHANGES:
   - Make requested modifications to document
   - Add new sections if requested
   - Update cross-references if structure changes
   - Maintain existing formatting and style

4. VALIDATE EDITS:
   - Ensure changes match user request
   - Verify document structure maintained
   - Check formatting consistency
   - Validate cross-references still work

5. WRITE UPDATED DOCUMENT:
   - Write complete updated documentation to output file
   - Preserve metadata format

Return only:
OUTPUT_FILE: <path>
STATUS: UPDATED
MODE: EDIT

DO NOT interact with user. The slash command handles all communication.
```

Use `subagent_type: "document-builder-default"` when invoking the Task tool.

### Step 5: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the document-builder agent to complete.

Collect agent output:
- Output file path
- Status (CREATED or UPDATED)
- Mode (CREATE or EDIT)

### Step 6: Report Results

After agent completes, output based on mode:

**For CREATE Mode:**

```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: DEVGUIDE CREATED
═══════════════════════════════════════════════════════════════

Target Directory: [directory path]
Output File: [file path]

Structure:
- Overview: Architecture and purpose
- Sub-folder guides: [count] cross-references
- Templates: [count] code templates
- Patterns: [count] design patterns
- Best practices: Identified standards

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Review DEVGUIDE: [output file path]
2. Move to directory: mv [output file] [directory]/DEVGUIDE.md
3. Generate sub-folder guides: /document-builder [subdirectory]
4. Commit: git add [file] && git commit -m "Add DEVGUIDE for [directory]"

═══════════════════════════════════════════════════════════════
```

**For EDIT Mode:**

```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: DOCUMENTATION UPDATED
═══════════════════════════════════════════════════════════════

Original: [document path]
Output File: [file path]

Changes Applied:
[User request description]

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Review changes: [output file path]
2. Replace original: mv [output file] [original path]
3. Commit: git add [file] && git commit -m "Update documentation"

═══════════════════════════════════════════════════════════════
```

## Workflow Diagram

### CREATE Mode Workflow

```
/document-builder [--mode=create] <directory>
    │
    ▼
┌─────────────────────────────────┐
│ Parse arguments                 │
│ Validate directory exists       │
│ Detect mode (CREATE)            │
└─────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch document-builder-default (CREATE MODE)    │◄── run_in_background: true
│                                                  │
│  PHASE 1: Directory Analysis                     │
│    - Analyze directory structure                 │
│    - Detect language/framework                   │
│    - Identify directory type (services/etc.)     │
│    - List sub-directories                        │
│                                                  │
│  PHASE 2: Code Pattern Extraction                │
│    - Glob source files in directory              │
│    - Grep for class/function patterns            │
│    - Extract structural templates                │
│    - Find design patterns                        │
│                                                  │
│  PHASE 3: Architecture Identification            │
│    - Identify architectural layers               │
│    - Extract common patterns                     │
│    - Identify best practices                     │
│                                                  │
│  PHASE 4: DEVGUIDE Generation                    │
│    - Generate Overview                           │
│    - Generate Sub-folder guides section          │
│    - Generate Templates section                  │
│    - Generate Patterns section                   │
│    - Generate Best Practices section             │
│    - Generate Summary                            │
│                                                  │
│  PHASE 5: Quality Validation                     │
│    - Verify architectural focus                  │
│    - Check language-agnostic templates           │
│    - Validate cross-references                   │
│                                                  │
│  PHASE 6: Write DEVGUIDE                         │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report DEVGUIDE     │
│ created             │
└─────────────────────┘
```

### EDIT Mode Workflow

```
/document-builder --mode=edit <document-path> "request"
    │
    ▼
┌─────────────────────────────────┐
│ Parse arguments                 │
│ Validate document exists        │
│ Extract user request            │
└─────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch document-builder-default (EDIT MODE)      │◄── run_in_background: true
│                                                  │
│  PHASE 1: Read Existing Document                 │
│    - Read complete document                      │
│    - Understand structure                        │
│    - Identify document type                      │
│                                                  │
│  PHASE 2: Analyze User Request                   │
│    - Parse requested changes                     │
│    - Identify sections to modify                 │
│    - Plan new sections if needed                 │
│                                                  │
│  PHASE 3: Apply Changes                          │
│    - Make requested modifications                │
│    - Add new sections if requested               │
│    - Maintain formatting/style                   │
│                                                  │
│  PHASE 4: Validate Edits                         │
│    - Verify changes match request                │
│    - Check structure maintained                  │
│    - Validate cross-references                   │
│                                                  │
│  PHASE 5: Write Updated Document                 │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report document     │
│ updated             │
└─────────────────────┘
```

## Key Architecture Points

1. **Two Modes**: CREATE generates hierarchical DEVGUIDeS, EDIT modifies existing docs
2. **Slash Command Orchestrates**: Handles argument parsing and mode detection
3. **Agent Only Analyzes/Edits**: Agent does the work, no user interaction
4. **Architectural Focus**: CREATE mode generates architectural guides, not code documentation
5. **Language-Agnostic**: Templates are language-agnostic or adapt to detected language
6. **Hierarchical Structure**: DEVGUIDeS cross-reference sub-directory guides
7. **No Iteration**: Single-pass generation (not iterative refinement)

## Error Handling

| Scenario | Action |
|----------|--------|
| Path missing or invalid | Report error with correct path format, stop |
| Unsupported mode | Report error with valid modes (create, edit), stop |
| No files found in directory (CREATE) | Report error, suggest different directory |
| Document not found (EDIT) | Report error with correct file path, stop |
| Missing user request (EDIT) | Report error, request required for edit mode |
| Agent fails | Report error with agent output |
| Analysis incomplete | Agent reports what's missing, still generates best-effort guide |

## Example Usage

### CREATE Mode Examples

```bash
# Generate DEVGUIDE for current directory
/document-builder .

# Generate DEVGUIDE for services directory
/document-builder src/services/

# Generate DEVGUIDE for components directory
/document-builder frontend/src/components/

# Explicit create mode
/document-builder --mode=create src/lib/

# Generate hierarchical DEVGUIDeS for entire project
# (run for root, then each sub-directory)
/document-builder backend/
/document-builder backend/src/
/document-builder backend/src/services/
/document-builder backend/src/controllers/
```

### EDIT Mode Examples

```bash
# Add new section to existing DEVGUIDE
/document-builder --mode=edit src/services/DEVGUIDE.md "Add SSE pattern template"

# Update architecture section
/document-builder --mode=edit backend/DEVGUIDE.md "Update service architecture to include new orchestration pattern"

# Add new component pattern
/document-builder --mode=edit src/components/DEVGUIDE.md "Add skeleton component pattern with examples"

# Fix cross-references
/document-builder --mode=edit src/lib/DEVGUIDE.md "Update sub-folder guide links"
```

## DEVGUIDE Template Structure

The CREATE mode generates DEVGUIDeS following this structure:

### DEVGUIDE.md Template

```markdown
# [Directory Name] Architecture Guide

## Overview

[High-level description of directory purpose and architecture]
[Key architectural decisions and patterns]
[When to use code in this directory]

## Sub-folder Guides

- [subdirectory1/DEVGUIDE.md](subdirectory1/DEVGUIDE.md) - [Purpose]
- [subdirectory2/DEVGUIDE.md](subdirectory2/DEVGUIDE.md) - [Purpose]
- [subdirectory3/DEVGUIDE.md](subdirectory3/DEVGUIDE.md) - [Purpose]

## Templates

### [Pattern 1 Name]

[Description of when to use this pattern]

\`\`\`language
// ============================================================================
// IMPORTS AND TYPES
// ============================================================================

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

export class ExamplePattern {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  // ----------------------------------------------------------------------------
  // PRIMARY BUSINESS METHODS
  // ----------------------------------------------------------------------------

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================
}
\`\`\`

### [Pattern 2 Name]

[Template for second pattern...]

## Design Patterns

### [Design Pattern 1]

[Description and usage]

### [Design Pattern 2]

[Description and usage]

## Best Practices

1. **[Practice 1]**: [Description]
2. **[Practice 2]**: [Description]
3. **[Practice 3]**: [Description]

## Directory Structure

\`\`\`
directory-name/
├── subdirectory1/          # [Purpose]
├── subdirectory2/          # [Purpose]
├── file-pattern1.ext       # [Purpose]
└── file-pattern2.ext       # [Purpose]
\`\`\`

## Summary

[Brief summary of key takeaways]
[Links to related guides]
```

## When to Use Document Builder

**Use `/document-builder` (CREATE mode) when:**
- Setting up hierarchical architectural documentation for a project
- Documenting directory structure and architectural patterns
- Creating language-agnostic architectural guides
- Need to document design patterns used in code
- Want to establish coding standards based on existing patterns
- Building onboarding documentation for developers

**Use `/document-builder --mode=edit` when:**
- Need to add new sections to existing DEVGUIDeS
- Update architectural patterns after refactoring
- Fix or update cross-references between guides
- Add new templates or design patterns
- Update best practices section

**Don't use when:**
- Need API reference documentation (use other documentation tools)
- Need inline code comments or docstrings
- Documentation needs are very simple (a README is sufficient)
- Project doesn't follow architectural patterns
