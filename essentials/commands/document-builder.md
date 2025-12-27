---
allowed-tools: Task, TaskOutput, Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: [--type=TYPE] <path>
description: Generate comprehensive documentation from project/code analysis following documentation standards (project)
---

Generate comprehensive, professional documentation by analyzing project structure, code, and APIs. The slash command orchestrates analysis while the document-builder-default agent analyzes code and generates documentation following established templates and best practices.

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY analyzes and creates documentation.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the document FILE directly, not in chat.

**Quality Process**: The agent applies systematic code analysis and 6 validation passes to ensure documents score ≥40/50 across 5 dimensions.

## Arguments

1. **--type=TYPE** (optional): Document type to generate
   - `readme` - Project README.md (default if not specified)
   - `api` - API reference documentation
   - `architecture` - Architecture documentation
   - `contributing` - Contributing guidelines
   - `changelog` - Changelog/release notes template
   - `guide` - User or developer guide

2. **path**: File path, directory path, or "." for entire project
   - Examples: `.`, `src/`, `src/api/`, `src/api/handlers.py`

## Instructions

### Step 1: Parse and Validate Arguments

Parse `$ARGUMENTS` to extract:
1. Document type (from `--type=TYPE` flag, defaults to `readme`)
2. Target path (file, directory, or `.` for project root)

**Validation:**
```bash
# Verify path exists
ls <path>

# If path is a file, verify it's readable
# If path is a directory, verify it contains files
```

- If path missing or invalid: Report error and stop
- If unsupported document type: Report error with valid types
- If arguments malformed: Report usage example

### Step 2: Determine Scope and Document Type

Based on arguments, determine:

```
Scope Analysis:
- Target: [file | directory | project root]
- Document type: [README | API | ARCHITECTURE | CONTRIBUTING | CHANGELOG | GUIDE]
- Primary language: [detect from file extensions]
- Project type: [library | application | API | CLI | framework]
```

**Auto-detection rules:**
- If `--type` not specified: Default to README
- If path is single file: Generate focused documentation for that file/module
- If path is directory: Generate documentation for that subsection
- If path is `.`: Generate project-level documentation

### Step 3: Generate Output File Path

Create output file path based on document type:

```bash
# Generate 5-char random hash
HASH=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

**Naming patterns:**
- README: `.claude/plans/document-builder-README-{hash5}.md`
- API: `.claude/plans/document-builder-API-{hash5}.md`
- ARCHITECTURE: `.claude/plans/document-builder-ARCHITECTURE-{hash5}.md`
- CONTRIBUTING: `.claude/plans/document-builder-CONTRIBUTING-{hash5}.md`
- CHANGELOG: `.claude/plans/document-builder-CHANGELOG-{hash5}.md`
- GUIDE: `.claude/plans/document-builder-GUIDE-{hash5}.md`

### Step 4: Launch Document Builder Agent

**CRITICAL**: The SLASH COMMAND orchestrates. The agent ONLY analyzes code and creates documentation.

Launch `document-builder-default` agent **in background** using Task tool with `run_in_background: true`:

```
Analyze the project/code and generate comprehensive documentation following documentation standards.

Document Type: <type>
Target Path: <path>
Output File: <generated file path>

## Your Task

You are ONLY responsible for analyzing code and creating documentation. You do NOT orchestrate or interact with the user.

SYSTEMATIC PROCESS:

1. PROJECT ANALYSIS:
   - Read CLAUDE.md, README.md, package.json, pyproject.toml, etc.
   - Detect project type, language, framework
   - Identify architecture patterns
   - Extract dependencies and tech stack

2. CODE STRUCTURE ANALYSIS:
   - Use Glob to find all relevant files
   - Use Grep to extract exports, classes, functions, APIs
   - Build complete code structure map
   - Identify entry points, main modules, utilities

3. API/INTERFACE EXTRACTION:
   - Extract all public APIs, functions, classes
   - Document function signatures, parameters, return types
   - Extract docstrings and comments
   - Identify usage patterns

4. DOCUMENTATION GENERATION:
   - Apply appropriate template for document type
   - Generate content based on code analysis (NOT assumptions)
   - Include code examples extracted from tests or usage
   - Follow documentation standards for the language/framework

5. REFLECTION CHECKPOINT:
   - Verify all content is backed by code evidence
   - Ensure no placeholders or "TODO" sections
   - Validate completeness against template

6. QUALITY VALIDATION (6 passes):
   - Pass 1: Initial draft from analysis
   - Pass 2: Structural validation against template
   - Pass 3: Anti-pattern scan (no vague language)
   - Pass 4: Accuracy check (all code references valid)
   - Pass 5: Quality scoring (≥40/50)
   - Pass 6: Final review

7. WRITE DOCUMENTATION FILE:
   - Write complete documentation to output file
   - Include metadata and quality scores

Return only:
OUTPUT_FILE: <path>
STATUS: CREATED
QUALITY_SCORE: <score>/50

DO NOT interact with user. The slash command handles all communication.
```

Use `subagent_type: "document-builder-default"` when invoking the Task tool.

### Step 5: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the document-builder agent to complete.

Collect agent output:
- Output file path
- Status (CREATED)
- Quality score

### Step 6: Report Results

After agent completes, output:

```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: DOCUMENTATION GENERATED
═══════════════════════════════════════════════════════════════

Document Type: [README | API | ARCHITECTURE | etc.]
Target: [path analyzed]
Output File: [file path]

Quality Score: [X]/50

Analysis Summary:
- Files analyzed: [count]
- APIs documented: [count]
- Classes documented: [count]
- Functions documented: [count]

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Review documentation: [output file path]
2. Move to project: mv [output file] ./[final location]
3. Commit: git add [file] && git commit -m "Add [type] documentation"

═══════════════════════════════════════════════════════════════
```

## Workflow Diagram

```
/document-builder [--type=TYPE] <path>
    │
    ▼
┌─────────────────────────────────┐
│ Parse arguments                 │
│ Validate path exists            │
│ Determine document type & scope │
└─────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch document-builder-default                  │◄── run_in_background: true
│ (analyze and create docs ONLY)                   │
│                                                  │
│  PHASE 1: Project Analysis                       │
│    - Read project files, detect type/language    │
│    - Extract tech stack, dependencies            │
│                                                  │
│  PHASE 2: Code Structure Analysis                │
│    - Glob all files, Grep for APIs/exports       │
│    - Build complete structure map                │
│                                                  │
│  PHASE 3: API/Interface Extraction               │
│    - Extract all public APIs with signatures     │
│    - Document parameters, return types           │
│    - Extract usage examples from code            │
│                                                  │
│  PHASE 4: Documentation Generation               │
│    - Apply template for document type            │
│    - Generate content from analysis              │
│    - Include extracted code examples             │
│                                                  │
│  PHASE 4.5: Reflection Checkpoint (ReAct)        │
│    - Verify evidence-based content               │
│    - Check completeness, no TODOs                │
│                                                  │
│  PHASE 5: Quality Validation (6 passes)          │
│    - Pass 1: Initial draft                       │
│    - Pass 2: Structural validation               │
│    - Pass 3: Anti-pattern scan                   │
│    - Pass 4: Accuracy check                      │
│    - Pass 5: Quality scoring (≥40/50)            │
│    - Pass 6: Final review                        │
│                                                  │
│  PHASE 6: Write Documentation                    │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for completion
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report results with │
│ quality score       │◄── minimal output
└─────────────────────┘
```

## Key Architecture Points

1. **Slash Command Orchestrates**: The command file handles argument parsing and orchestration
2. **Agent Only Analyzes**: The agent analyzes code and creates documentation, no user interaction
3. **Evidence-Based**: All documentation generated from actual code analysis, not assumptions
4. **Template-Driven**: Uses established templates for each document type
5. **Quality Validation**: 6-pass validation ensures high-quality output
6. **No Iteration**: Single-pass generation (not iterative refinement like prompt-builder)

## Error Handling

| Scenario | Action |
|----------|--------|
| Path missing or invalid | Report error with correct path format, stop |
| Unsupported document type | Report error with valid types, stop |
| No files found in path | Report error, suggest different path |
| Agent fails | Report error with agent output |
| Analysis incomplete | Agent reports what's missing, still generates best-effort documentation |
| Low quality score (<40/50) | Agent refines and re-validates automatically |

## Example Usage

```bash
# Generate README for entire project
/document-builder .

# Generate README with explicit type flag
/document-builder --type=readme .

# Generate API documentation for specific directory
/document-builder --type=api src/api/

# Generate architecture documentation
/document-builder --type=architecture .

# Generate contributing guidelines
/document-builder --type=contributing .

# Generate API docs for single file
/document-builder --type=api src/api/handlers.py

# Generate developer guide
/document-builder --type=guide .
```

## Document Templates

Each document type follows a specific template:

### README Template
- Project title and description (from package.json/pyproject.toml)
- Features (extracted from code analysis)
- Installation (from package manager files)
- Quick Start (from examples or tests)
- API Overview (top-level exports)
- Configuration (from config files)
- Contributing & License

### API Template
- Overview
- Authentication (if detected)
- Endpoints/Functions (all public APIs)
- Request/Response schemas (from type definitions)
- Error codes (from error handling code)
- Code examples (from tests)

### ARCHITECTURE Template
- System Overview
- Architecture Diagram (ASCII art from structure)
- Component Breakdown (from directory structure)
- Data Flow (from imports/dependencies)
- Technology Stack (detected technologies)
- Design Patterns (identified patterns)

### CONTRIBUTING Template
- Development Setup (from package manager)
- Code Style (from linter configs)
- Testing (from test files)
- Pull Request Process
- Code Review Guidelines

### CHANGELOG Template
- Version format structure
- Change categories (Added, Changed, Fixed, etc.)
- Example entries

### GUIDE Template
- Getting Started
- Core Concepts (from main modules)
- Common Tasks (from common usage patterns)
- Troubleshooting (from error handling)
- FAQ

## When to Use Document Builder

**Use `/document-builder` when:**
- Starting a new project and need initial documentation
- Adding documentation to existing undocumented code
- Updating documentation after major refactoring
- Creating standardized documentation across projects
- Need comprehensive API documentation
- Want architecture documentation generated from code

**Don't use when:**
- Documentation already exists and just needs minor updates (use editor)
- Need custom documentation that doesn't fit templates
- Project is too small to warrant formal documentation
