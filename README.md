# Essentials for Claude Code

A comprehensive multi-agent orchestration framework for Claude Code. Features deep planning, bug investigation, code quality analysis, and parallel file editing capabilities.

## Core Concept: Multi-Agent Workflows

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ESSENTIALS FRAMEWORK                                  │
│                                                                             │
│  COMMANDS (User-Invoked)           AGENTS (Background Workers)              │
│  ─────────────────────────         ────────────────────────────             │
│                                                                             │
│  ┌──────────────┐                  ┌─────────────────────────┐              │
│  │  /planner    │──────────────────│   planner-default       │              │
│  │              │                  │   (codebase → plan)     │              │
│  └──────────────┘                  └───────────┬─────────────┘              │
│                                                │                            │
│  ┌──────────────┐                              │ spawns                     │
│  │  /editor     │──────────────────────────────┼──────────────────┐         │
│  │              │                              ▼                  ▼         │
│  └──────────────┘                  ┌─────────────────┐ ┌─────────────────┐  │
│                                    │ file-editor     │ │ file-editor     │  │
│  ┌──────────────┐                  │ (file1)         │ │ (file2)         │  │
│  │  /bug-scout  │──────────┐       └─────────────────┘ └─────────────────┘  │
│  │              │          │                                                │
│  └──────────────┘          │       ┌─────────────────────────┐              │
│                            └──────►│   bug-scout-default     │              │
│  ┌──────────────┐                  │   (logs → fix plan)     │              │
│  │/code-quality │──────────┐       └─────────────────────────┘              │
│  │              │          │                                                │
│  └──────────────┘          │       ┌─────────────────────────┐              │
│                            └──────►│ code-quality-default    │              │
│  ┌──────────────┐                  │   (analyze → improve)   │              │
│  │/prompt-build │──────────┐       └─────────────────────────┘              │
│  │              │          │                                                │
│  └──────────────┘          │       ┌─────────────────────────┐              │
│                            └──────►│ prompt-builder-default  │              │
│                                    │   (vibe → prompt)       │              │
│                                    └─────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
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

### 3. **Code Quality** (`/code-quality`)
Comprehensive static analysis with automatic improvements:
- 11-dimension quality scoring (SOLID, DRY, KISS, YAGNI, OWASP)
- Cognitive and cyclomatic complexity metrics
- Technical debt estimation
- Project standards compliance checking
- Auto-spawns file-editor agents to implement fixes
- Targets 9.1/10 minimum quality score

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

### Step 3: Create Plans Directory (in your project)

The agents store implementation plans in your project's `.claude/plans/` directory:

```bash
mkdir -p .claude/plans
```

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
# Analyze and improve multiple files
/code-quality src/services/auth src/services/user src/models/user

# Single file analysis
/code-quality src/services/payment
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
│   ├── code-quality-default (analysis + plan)
│   └── file-editor-default (parallel, per-file)
│
├── /editor
│   └── file-editor-default (parallel, per-file)
│
└── /prompt-builder
    └── prompt-builder-default (iterative refinement)
```

### Plan Storage

All plans are stored in **your project's** `.claude/plans/` directory (not the plugin):
- `{task-slug}-plan.md` - Implementation plans
- `bug-scout-{identifier}-plan.md` - Bug fix plans
- `code-quality-{filename}-plan.md` - Quality improvement plans
- `prompt-builder-{slug}-draft.md` - Prompt drafts

## Directory Structure

```
essentials/
├── agents/
│   ├── bug-scout-default.md      # Bug investigation agent
│   ├── code-quality-default.md   # Code analysis agent
│   ├── file-editor-default.md    # File modification agent
│   ├── planner-default.md        # Planning agent
│   └── prompt-builder-default.md # Prompt engineering agent
├── commands/
│   ├── bug-scout.md              # /bug-scout command
│   ├── code-quality.md           # /code-quality command
│   ├── editor.md                 # /editor command
│   ├── planner.md                # /planner command
│   └── prompt-builder.md         # /prompt-builder command
└── skills/
    └── code-quality.md           # Code quality skill reference
```

## Key Design Principles

1. **Parallel Execution**: File-editor agents run in parallel for multi-file changes
2. **Plan-Driven**: All complex work flows through plan files in `.claude/plans/`
3. **Minimal Context Pollution**: Agents return minimal output; details stay in plan files
4. **Verification Loops**: All implementations are verified against plan counts
5. **No Git Modifications**: Agents never commit; user reviews and commits manually
6. **Security-First**: All file edits include security checklist verification

## Requirements

- **Claude Code** - The CLI for orchestration and execution
- **Node.js 18+** - For running Claude Code

## License

MIT
