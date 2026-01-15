---
allowed-tools: Task, TaskOutput, Bash, Read, AskUserQuestion
argument-hint: <description>
description: Create high-quality prompts from any description (project)
model: opus
---

# Prompt Creator

Transform descriptions into precise, effective prompts through multi-pass quality validation.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the output FILE directly.

## Arguments

Takes **any input** describing what the prompt should do:
- `"review PRs for security issues"`
- `"generate API tests"`
- `"write documentation from code"`

## Instructions

### Step 1: Validate Input

If input is too short (< 3 words), use AskUserQuestion:
```
questions:
  - question: "Can you provide more details about what the prompt should do?"
    header: "More detail"
    multiSelect: false
    options:
      - label: "Add more detail"
        description: "I'll describe what I want"
      - label: "Proceed anyway"
        description: "Continue with what was given"
```

### Step 2: Generate Output Path

```bash
HASH=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

Path: `.claude/prompts/prompt-creator-{slug}-{hash5}.md`

### Step 3: Launch Agent

Launch `prompt-creator-default` in background:

```
Create a high-quality prompt from this description.

Description: <user input>
Output file: <generated path>

## Process

1. CONTEXT GATHERING - Read reference files
2. ANALYSIS - Parse requirements
3. BUILD PROMPT - Create prompt structure
4. QUALITY VALIDATION (6 passes)
5. WRITE OUTPUT FILE

Return:
OUTPUT_FILE: <path>
STATUS: CREATED
```

Use `subagent_type: "prompt-creator-default"` and `run_in_background: true`.

### Step 4: Report Result

```
Prompt ready: <file path>

Review the output. When satisfied, copy "The Prompt" section.
For edits, prompt the main agent to make changes.
```

## Workflow Diagram

```
/prompt-creator <description>
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: VALIDATE INPUT                                        │
│                                                               │
│  • Check if description is sufficient (≥3 words)              │
│  • AskUserQuestion if too short                               │
│  • Generate output path with 5-char hash                      │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: LAUNCH AGENT                                          │
│                                                               │
│  Agent: prompt-creator-default                                │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  1. CONTEXT GATHERING                                   │  │
│  │     • Read reference files if relevant                  │  │
│  │     • Analyze codebase patterns                         │  │
│  │                                                         │  │
│  │  2. ANALYSIS                                            │  │
│  │     • Parse requirements from description               │  │
│  │     • Identify prompt type and structure                │  │
│  │                                                         │  │
│  │  3. BUILD PROMPT                                        │  │
│  │     • Create prompt structure                           │  │
│  │     • Add sections: Role, Context, Instructions         │  │
│  │                                                         │  │
│  │  4. QUALITY VALIDATION (6 PASSES)                       │  │
│  │     • Pass 1: Clarity check                             │  │
│  │     • Pass 2: Completeness check                        │  │
│  │     • Pass 3: Consistency check                         │  │
│  │     • Pass 4: Edge case coverage                        │  │
│  │     • Pass 5: Output format validation                  │  │
│  │     • Pass 6: Final review                              │  │
│  │                                                         │  │
│  │  5. WRITE OUTPUT FILE                                   │  │
│  │     → .claude/prompts/prompt-creator-{slug}-{hash5}.md  │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Prompt file path                                           │
│  • Status: CREATED                                            │
│  • Next steps: Review, copy to commands/ or agents/           │
└───────────────────────────────────────────────────────────────┘
```

## Example Usage

```bash
# Create security review prompt
/prompt-creator "review PRs for security issues"

# Create test generation prompt
/prompt-creator "generate unit tests for React components"

# Create documentation prompt
/prompt-creator "write API documentation from code"
```

## Integration

After creating:
- Copy to `commands/` for slash commands
- Copy to `agents/` for subagents
