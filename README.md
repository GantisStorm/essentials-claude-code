# Essentials for Claude Code

A comprehensive multi-agent orchestration framework for Claude Code. Features deep planning, bug investigation, code quality analysis (standard and LSP-powered), and parallel file editing capabilities.

## Core Concept: Multi-Agent Workflows

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                           ESSENTIALS FRAMEWORK                                        │
│                                                                                       │
│  USER COMMANDS                    ANALYSIS AGENTS                 EXECUTION AGENTS   │
│  ──────────────                   ───────────────                 ────────────────   │
│                                                                                       │
│  ┌─────────────────┐              ┌──────────────────┐                               │
│  │   /planner      │──────────────│ planner-default  │                               │
│  │                 │              │ (investigate +   │                               │
│  │ Architecture +  │              │  create plan)    │                               │
│  │ Implementation  │              └────────┬─────────┘                               │
│  └─────────────────┘                       │                                         │
│                                            │ creates plan file                       │
│                                            │ .claude/plans/                          │
│                                            ▼                                         │
│  ┌─────────────────┐              ┌──────────────────┐           ┌────────────────┐ │
│  │   /editor       │──────────────│  Reads Plan File │──────────►│ file-editor    │ │
│  │                 │              │                  │  parallel │ (file1)        │ │
│  │ Execute Plans   │              │ .claude/plans/   │──────────►│ file-editor    │ │
│  │ on Files        │              │ *-plan.md        │  spawns  │ (file2)        │ │
│  └─────────────────┘              └──────────────────┘──────────►│ file-editor    │ │
│                                                                   │ (file3)        │ │
│                                                                   └────────────────┘ │
│  ┌─────────────────┐              ┌──────────────────┐                               │
│  │  /bug-scout     │──────────────│ bug-scout-       │                               │
│  │                 │              │ default          │                               │
│  │ Investigate +   │              │ (logs → fix      │──┐                            │
│  │ Fix Bugs        │              │  plan)           │  │ auto-spawns                │
│  └─────────────────┘              └──────────────────┘  │ file-editors               │
│                                                          │                            │
│                                                          ▼                            │
│  ┌─────────────────┐              ┌──────────────────┐  │         ┌────────────────┐ │
│  │ /code-quality   │──────────────│ code-quality-    │  │         │ file-editor    │ │
│  │                 │              │ default          │  └────────►│ agents         │ │
│  │ Standard Tools  │              │ (Read/Glob/Grep) │  parallel │ (implement     │ │
│  │ Analysis        │              └──────────────────┘  execution │  fixes)        │ │
│  └─────────────────┘                                               └────────────────┘ │
│                                                          ▲                            │
│  ┌─────────────────┐              ┌──────────────────┐  │                            │
│  │/code-quality    │              │ code-quality-    │  │                            │
│  │     -serena     │──────────────│ serena           │  │                            │
│  │                 │              │ (LSP-powered     │──┘                            │
│  │ LSP Semantic    │              │  semantic        │                               │
│  │ Navigation      │              │  analysis)       │                               │
│  └─────────────────┘              └──────────────────┘                               │
│                                                                                       │
│  ┌─────────────────┐              ┌──────────────────┐                               │
│  │/prompt-builder  │──────────────│ prompt-builder-  │                               │
│  │                 │              │ default          │                               │
│  │ Vibe → Prompt   │              │ (iterative       │                               │
│  │                 │              │  refinement)     │                               │
│  └─────────────────┘              └──────────────────┘                               │
│                                                                                       │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

### 1. **Planner** (`/planner`)
Comprehensive architectural planning with multi-phase investigation:
- Codebase investigation with file:line references
- External documentation research (via MCP)
- Risk analysis and mitigation planning
- Per-file implementation instructions
- 7-pass revision process for quality assurance
- Auto-spawns file-editor agents for implementation

### 2. **Bug Scout** (`/bug-scout`)
Deep bug investigation and automatic fix implementation:
- Error signal extraction from logs/stack traces
- Code path tracing from entry to failure
- Line-by-line analysis of suspicious code
- Regression analysis to find what broke
- Precise fix plans with before/after code
- Auto-spawns file-editor agents to apply fixes

### 3. **Code Quality** (`/code-quality` and `/code-quality-serena`)

Two complementary approaches for comprehensive code analysis:

#### **Standard Analysis** (`/code-quality`)
Traditional file-based analysis with standard tools:
- Uses Read, Glob, Grep for code navigation
- 11-dimension quality scoring (SOLID, DRY, KISS, YAGNI, OWASP)
- Cognitive and cyclomatic complexity metrics
- Technical debt estimation
- Project standards compliance checking
- Auto-spawns file-editor agents to implement fixes
- Targets 9.1/10 minimum quality score

#### **LSP Semantic Analysis** (`/code-quality-serena`) ⭐ NEW
Advanced semantic code navigation using Serena LSP:
- **Accurate Symbol Discovery**: Language server understands code structure
  - Classes, methods, functions, interfaces with exact locations
  - Type-aware analysis with LSP symbol kinds
- **Precise Reference Tracking**: Who calls what, across the entire codebase
  - `find_referencing_symbols` for accurate call hierarchy
  - Cross-file reference checking
- **Better Dead Code Detection**: LSP verifies zero-reference symbols
  - Unused public API detection (verified against consumers)
  - Orphaned code identification
- **Project-Wide Context**: Semantic understanding beyond text search
  - Consumer usage analysis (files importing the target)
  - Sibling file consistency checking
- All standard features (SOLID, DRY, KISS, YAGNI, OWASP, 9.1/10 target)
- Same auto-fix workflow with file-editor agents

**When to Use Each:**
- **`/code-quality`**: Quick analysis, simpler projects, no LSP setup needed
- **`/code-quality-serena`**: Larger codebases, accurate refactoring, semantic accuracy matters

### 4. **File Editor** (`/editor`)
Parallel file modification from implementation plans:
- Reads plans from `.claude/plans/`
- Implements changes atomically and defensively
- Security checklist verification
- Regression loop to clean up artifacts
- Detailed change tracking and rollback documentation

### 5. **Prompt Builder** (`/prompt-builder`)
Iterative prompt engineering from vibe descriptions:
- Transforms rough ideas into structured prompts
- Anti-pattern elimination (no vague phrases)
- Multiple iteration support with user feedback
- Drafts saved to `.claude/plans/`

## Installation

### Step 1: Add the Marketplace

```bash
/plugin marketplace add GantisStorm/essentials-claude-code
```

### Step 2: Install the Plugin

```bash
/plugin install essentials@essentials-claude-code
```

Or enable in `.claude/settings.local.json`:

```json
{
  "enabledPlugins": {
    "essentials@essentials-claude-code": true
  }
}
```

### Step 3: Create Required Directories (in your project)

The agents need these directories in your project:

```bash
mkdir -p .claude/plans
mkdir -p .claude/skills
```

### Step 4: Create Project-Specific Code Quality Skill

Create `.claude/skills/code-quality.md` tuned to your project's tooling:

```markdown
# Code Quality

Run code quality checks for this project.

## Commands

```bash
# Linting and formatting
your-linter . --fix
your-formatter .

# Type checking
your-type-checker
```

## Configuration

- Line length: [your limit]
- Linter config: [your config file]
- Type checker config: [your config file]
```

This skill is referenced by the code-quality agents to run your project's specific quality checks.

### Step 5 (Optional): Set Up Serena LSP for Semantic Analysis

To use `/code-quality-serena`, you need Serena MCP configured:

1. **Install Serena MCP**: Follow [Serena installation docs](https://github.com/toolness/serena)
2. **Configure for your project**: Serena will use LSP servers for your languages
3. **Test**: Verify LSP is working with a simple symbol search

Once configured, `/code-quality-serena` will use semantic code navigation for more accurate analysis.

## Usage

### Planning & Implementation

```bash
# Create and execute an implementation plan
/planner Add OAuth2 authentication with Google login

# Execute a specific plan on files
/editor .claude/plans/oauth2-plan.md src/auth/handler src/auth/middleware
```

### Bug Investigation

```bash
# Investigate and fix a bug
/bug-scout "TypeError: 'NoneType' object at auth_handler.py:45" "Login fails when user has no profile"

# With log file
/bug-scout ./logs/error.log "API returns 500 on POST /users"
```

### Code Quality

```bash
# Standard analysis (Read/Glob/Grep)
/code-quality src/services/auth src/services/user src/models/user

# LSP semantic analysis (more accurate)
/code-quality-serena src/services/auth src/services/user src/models/user

# Single file analysis
/code-quality src/services/payment
/code-quality-serena src/services/payment
```

### Prompt Building

```bash
# Create a new prompt from a vibe
/prompt-builder "a prompt that reviews PRs for security issues"

# Refine based on feedback
"add more OWASP examples and focus on injection attacks"

# When satisfied
"done"
```

## Architecture

### Agent Hierarchy

```
Orchestrator Commands
├── /planner
│   ├── planner-default (investigation + planning)
│   └── file-editor-default (parallel, per-file)
│
├── /bug-scout
│   ├── bug-scout-default (investigation + fix plan)
│   └── file-editor-default (parallel, per-file)
│
├── /code-quality
│   ├── code-quality-default (standard analysis + plan)
│   └── file-editor-default (parallel, per-file)
│
├── /code-quality-serena ⭐ NEW
│   ├── code-quality-serena (LSP semantic analysis + plan)
│   └── file-editor-default (parallel, per-file)
│
├── /editor
│   └── file-editor-default (parallel, per-file)
│
└── /prompt-builder
    └── prompt-builder-default (iterative refinement)
```

### Code Quality Analysis Workflow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                     CODE QUALITY ANALYSIS WORKFLOW                           │
└──────────────────────────────────────────────────────────────────────────────┘

USER: /code-quality-serena file1.ts file2.ts file3.ts
  │
  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: PARALLEL ANALYSIS (Background)                                │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │ code-quality-    │  │ code-quality-    │  │ code-quality-    │      │
│  │ serena           │  │ serena           │  │ serena           │      │
│  │ Agent 1          │  │ Agent 2          │  │ Agent 3          │      │
│  │                  │  │                  │  │                  │      │
│  │ Analyzes:        │  │ Analyzes:        │  │ Analyzes:        │      │
│  │ file1.ts         │  │ file2.ts         │  │ file3.ts         │      │
│  │                  │  │                  │  │                  │      │
│  │ Using LSP:       │  │ Using LSP:       │  │ Using LSP:       │      │
│  │ • get_symbols_   │  │ • get_symbols_   │  │ • get_symbols_   │      │
│  │   overview       │  │   overview       │  │   overview       │      │
│  │ • find_symbol    │  │ • find_symbol    │  │ • find_symbol    │      │
│  │ • find_          │  │ • find_          │  │ • find_          │      │
│  │   referencing_   │  │   referencing_   │  │   referencing_   │      │
│  │   symbols        │  │   symbols        │  │   symbols        │      │
│  │ • search_for_    │  │ • search_for_    │  │ • search_for_    │      │
│  │   pattern        │  │   pattern        │  │   pattern        │      │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘      │
│           │                     │                     │                │
│           │ Writes Plan         │ Writes Plan         │ Writes Plan    │
│           ▼                     ▼                     ▼                │
│  .claude/plans/        .claude/plans/        .claude/plans/           │
│  code-quality-         code-quality-         code-quality-            │
│  file1-plan.md         file2-plan.md         file3-plan.md            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
  │
  │ All analyses complete
  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: PARSE RESULTS                                                 │
│                                                                         │
│  Orchestrator reads each plan file:                                    │
│  • Extract: File path, quality score, TOTAL CHANGES                    │
│  • Group: Needs Changes (score < 9.1) vs Clean (score ≥ 9.1)          │
│  • LSP Stats: Symbols analyzed, references checked, unused found       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
  │
  │ Files needing changes identified
  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: PARALLEL IMPLEMENTATION (Background)                          │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │ file-editor-     │  │ file-editor-     │  │ file-editor-     │      │
│  │ default          │  │ default          │  │ default          │      │
│  │                  │  │                  │  │                  │      │
│  │ Reads Plan:      │  │ Reads Plan:      │  │ Reads Plan:      │      │
│  │ code-quality-    │  │ code-quality-    │  │ code-quality-    │      │
│  │ file1-plan.md    │  │ file2-plan.md    │  │ file3-plan.md    │      │
│  │                  │  │                  │  │                  │      │
│  │ Implements:      │  │ Implements:      │  │ Implements:      │      │
│  │ All 6 fixes      │  │ All 4 fixes      │  │ All 8 fixes      │      │
│  │ from plan        │  │ from plan        │  │ from plan        │      │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘      │
│           │                     │                     │                │
│           └─────────────────────┴─────────────────────┘                │
│                                 │                                      │
└─────────────────────────────────┼──────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: VERIFICATION                                                  │
│                                                                         │
│  For each file, compare:                                               │
│  • TOTAL CHANGES (from analysis plan)                                  │
│  • CHANGES COMPLETED (from editor report)                              │
│                                                                         │
│  If mismatch:                                                          │
│  • Re-dispatch file-editor with missed fixes only                      │
│  • Repeat until CHANGES COMPLETED == TOTAL CHANGES                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: COMPREHENSIVE SUMMARY                                         │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Code Quality Analysis & Implementation Summary (LSP-Powered)    │  │
│  │                                                                  │  │
│  │ Files Analyzed: 3                                                │  │
│  │ LSP Symbols Analyzed: 47 (classes, methods, functions)          │  │
│  │ References Checked: 183                                          │  │
│  │ Unused Elements Found: 8                                         │  │
│  │                                                                  │  │
│  │ Files Modified: 3                                                │  │
│  │ Total Fixes Applied: 18 (verified complete)                     │  │
│  │                                                                  │  │
│  │ Quality Scores:                                                  │  │
│  │ • file1.ts: 6.8 → 9.2 ✓                                         │  │
│  │ • file2.ts: 7.5 → 9.3 ✓                                         │  │
│  │ • file3.ts: 8.1 → 9.4 ✓                                         │  │
│  │                                                                  │  │
│  │ All files meet 9.1/10 threshold                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Plan Storage

All plans are stored in **your project's** `.claude/plans/` directory (not the plugin):
- `{task-slug}-plan.md` - Implementation plans
- `bug-scout-{identifier}-plan.md` - Bug fix plans
- `code-quality-{filename}-plan.md` - Quality improvement plans (both standard and LSP)
- `prompt-builder-{slug}-draft.md` - Prompt drafts

## Directory Structure

```
essentials/
├── agents/
│   ├── bug-scout-default.md        # Bug investigation agent
│   ├── code-quality-default.md     # Code analysis agent (standard)
│   ├── code-quality-serena.md      # Code analysis agent (LSP-powered) ⭐
│   ├── file-editor-default.md      # File modification agent
│   ├── planner-default.md          # Planning agent
│   └── prompt-builder-default.md   # Prompt engineering agent
└── commands/
    ├── bug-scout.md                # /bug-scout command
    ├── code-quality.md             # /code-quality command
    ├── code-quality-serena.md      # /code-quality-serena command ⭐
    ├── editor.md                   # /editor command
    ├── planner.md                  # /planner command
    └── prompt-builder.md           # /prompt-builder command
```

## Key Design Principles

1. **Parallel Execution**: File-editor agents run in parallel for multi-file changes
2. **Plan-Driven**: All complex work flows through plan files in `.claude/plans/`
3. **Minimal Context Pollution**: Agents return minimal output; details stay in plan files
4. **Verification Loops**: All implementations are verified against plan counts
5. **No Git Modifications**: Agents never commit; user reviews and commits manually
6. **Security-First**: All file edits include security checklist verification
7. **Semantic Accuracy** (LSP): Use language servers for accurate code understanding

## LSP vs Standard Analysis Comparison

| Feature | Standard (`/code-quality`) | LSP Serena (`/code-quality-serena`) |
|---------|----------------------------|-------------------------------------|
| **Symbol Discovery** | Text search (Grep) | LSP semantic understanding |
| **Reference Finding** | Pattern matching | Precise cross-file references |
| **Dead Code Detection** | Heuristic-based | LSP-verified zero references |
| **Type Awareness** | Text-based inference | Language server type info |
| **Speed** | Fast (simple text ops) | Fast (LSP indexed) |
| **Setup Required** | None | Serena MCP + LSP config |
| **Accuracy** | Good for most cases | Excellent for refactoring |
| **Best For** | Quick checks, simple projects | Large codebases, complex refactors |

## Requirements

- **Claude Code** - The CLI for orchestration and execution
- **Node.js 18+** - For running Claude Code
- **Serena MCP** (optional) - For `/code-quality-serena` LSP analysis

## License

MIT
