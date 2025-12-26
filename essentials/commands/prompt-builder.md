---
allowed-tools: Task, TaskOutput, Bash, Read, Write, AskUserQuestion
argument-hint: <vibe-prompt>
description: Build high-quality prompts from vibe descriptions through iterative refinement (project)
---

Build high-quality Claude Code prompts from vibe descriptions using iterative multi-pass revision. The slash command orchestrates the refinement loop while the prompt-builder-default agent creates/updates prompt drafts with reflection checkpoints and quality validation.

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY creates/updates prompt drafts.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the draft FILE directly, not in chat.

**Quality Process**: The agent applies 6 validation passes (structural validation, anti-pattern scan, consumer simulation, quality scoring, final review) to ensure prompts score ≥40/50 across 5 dimensions.

## Arguments

1. **Vibe prompt**: Rough description of what the prompt should do

## Instructions

### Step 1: Validate Vibe Input

Check if the vibe prompt is sufficient:

**If vibe is too short (< 3 words):**

Use AskUserQuestion to get more detail:

```
questions:
  - question: "The vibe prompt is very short. Can you provide more details about what you want the prompt to do?"
    header: "More detail"
    multiSelect: false
    options:
      - label: "Provide more detail now"
        description: "I'll describe what I want in more detail"
      - label: "Proceed anyway"
        description: "Continue with the short vibe and let the agent infer"
```

If user chooses "Provide more detail now", use their additional input as the vibe.

If user chooses "Proceed anyway", continue with the original vibe.

### Step 2: Generate Draft File Path

Create a unique draft file path:
- Pattern: `.claude/plans/prompt-builder-{slug}-{hash5}-draft.md`
- Derive slug from the vibe (e.g., "security-review", "test-generator")
- Generate a 5-character random hash to prevent conflicts (lowercase alphanumeric)
- Example: `.claude/plans/prompt-builder-security-review-7k3m2-draft.md`

Use Bash to generate random hash if needed:
```bash
# Generate 5-char random hash
echo $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

### Step 3: Launch Prompt Builder Agent

**CRITICAL**: The SLASH COMMAND orchestrates the refinement loop. The agent ONLY creates/updates prompt drafts.

Launch `prompt-builder-default` agent **in background** using Task tool with `run_in_background: true`:

```
Build a high-quality prompt from this vibe using multi-pass revision with quality validation.

Vibe: <user's vibe prompt>

Draft file: <generated file path>

## Your Task

You are ONLY responsible for creating the prompt draft. You do NOT orchestrate or interact with the user.

1. CONTEXT GATHERING:
   - Read reference files (planner.md, planner-default.md, etc.)
   - Understand project patterns and conventions

2. VIBE ANALYSIS:
   - Parse user's vibe prompt
   - Identify intent and requirements

3. RESEARCH (if needed):
   - Use available MCP tools for context
   - Gather best practices and examples

4. DRAFT CREATION:
   - Determine prompt type (slash command vs subagent)
   - Build initial draft following guidelines

5. REFLECTION CHECKPOINT:
   - Verify clarity, specificity, completeness
   - Ensure best practices alignment

6. ITERATIVE REVISION (6 passes):
   - Pass 1: Initial draft
   - Pass 2: Structural validation
   - Pass 3: Anti-pattern scan (eliminate vague language)
   - Pass 4: Consumer simulation
   - Pass 5: Quality scoring (≥40/50, all dimensions ≥8)
   - Pass 6: Final review

7. WRITE DRAFT FILE:
   - Write to specified path with quality scores and revision log
   - Include validation status

Return only:
DRAFT_FILE: <path>
ITERATION: 1
STATUS: CREATED

DO NOT orchestrate refinement. The slash command handles all user interaction.
```

Use `subagent_type: "prompt-builder-default"` when invoking the Task tool.

### Step 4: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the prompt-builder agent to complete.

Collect agent output:
- Draft file path
- Iteration number
- Status (CREATED)

### Step 5: Report Initial Draft

After agent completes initial draft, output ONLY:

```
═══════════════════════════════════════════════════════════════
PROMPT BUILDER: DRAFT CREATED
═══════════════════════════════════════════════════════════════

Draft ready: <file path>

Review the draft file and provide feedback, or say "done" when satisfied.
═══════════════════════════════════════════════════════════════
```

**DO NOT** read or display the draft content. User opens the file directly.

### Step 6: Refinement Loop (Command Orchestrates)

**CRITICAL**: The SLASH COMMAND runs the refinement loop, NOT the agent.

After initial draft, wait for user response:

#### Option A: User Provides Feedback

If user provides refinement request (e.g., "add more examples", "focus on X"):

1. Launch `prompt-builder-default` agent again in background:

```
Refine the prompt based on user feedback using the same multi-pass revision process.

Draft file: <same file path>

User feedback: <their feedback>

## Your Task

You are ONLY responsible for applying changes to the prompt. You do NOT orchestrate or interact with the user.

REFINEMENT PROCESS:
1. Read existing draft file
2. Parse user's requested changes
3. Apply changes surgically (only what user requested)
4. Re-run all 6 validation passes:
   - Pass 1: Apply user's requested changes
   - Pass 2: Structural validation
   - Pass 3: Anti-pattern scan
   - Pass 4: Consumer simulation
   - Pass 5: Quality re-scoring (maintain ≥40/50)
   - Pass 6: Final review
5. Increment iteration number
6. Update revision history with changes and quality re-assessment
7. Write back to same file

Return only:
DRAFT_FILE: <path>
ITERATION: <n+1>
STATUS: UPDATED

DO NOT orchestrate further refinement. The slash command handles all user interaction.
```

Use `subagent_type: "prompt-builder-default"` with `run_in_background: true`.

2. Wait for completion using `TaskOutput` with `block: true`

3. Output:
```
═══════════════════════════════════════════════════════════════
PROMPT BUILDER: DRAFT UPDATED
═══════════════════════════════════════════════════════════════

Draft updated: <file path> (iteration <N>)

Review and provide more feedback, or say "done".
═══════════════════════════════════════════════════════════════
```

4. Return to Step 6 (loop until user says "done")

#### Option B: User Says "Done"

If user indicates completion (e.g., "done", "looks good", "that's it"):

Output:
```
═══════════════════════════════════════════════════════════════
PROMPT BUILDER: COMPLETE
═══════════════════════════════════════════════════════════════

Final draft: <file path>

Copy the prompt from the "The Prompt" section in the draft file.
═══════════════════════════════════════════════════════════════
```

Exit refinement loop.

## Workflow Diagram

```
/prompt-builder <vibe>
    │
    ▼
┌─────────────────────┐
│ Generate draft path │
└─────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch prompt-builder-default                    │◄── run_in_background: true
│ (create draft ONLY)                              │
│                                                  │
│  PHASE 0-4: Context, Analysis, Research, Draft   │
│  PHASE 4.5: Reflection Checkpoint (ReAct)        │
│  PHASE 5: Iterative Revision (6 passes)          │
│    - Pass 1: Initial draft                       │
│    - Pass 2: Structural validation               │
│    - Pass 3: Anti-pattern scan                   │
│    - Pass 4: Consumer simulation                 │
│    - Pass 5: Quality scoring (≥40/50)            │
│    - Pass 6: Final review                        │
│  PHASE 6: Write draft with scores & revision log │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for completion
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report: "Draft      │
│ ready"              │◄── minimal output
└─────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────┐
│ REFINEMENT LOOP (in command)                      │
│                                                   │
│  User reviews file → Provides feedback OR "done"  │
│                                                   │
│  If feedback:                                     │
│  ├─► Launch agent (Phase 7: refine)              │◄── run_in_background: true
│  ├─► Wait for completion                         │
│  ├─► Report "Draft updated"                      │
│  └─► Loop back                                   │
│                                                   │
│  If "done":                                       │
│  └─► Report "Complete" and exit                  │
└───────────────────────────────────────────────────┘
```

## Key Architecture Points

1. **Slash Command Orchestrates**: The command file (prompt-builder.md) handles refinement loop
2. **Agent Only Creates Prompts**: The agent (prompt-builder-default.md) ONLY creates/updates drafts
3. **No User Interaction in Agent**: Agent never asks questions, just creates/updates
4. **Iterative Refinement**: Command runs loop, user provides feedback, agent applies changes
5. **Multi-Pass Quality**: Agent ensures all prompts pass 6 validation passes
6. **Minimal Output**: Agent returns DRAFT_FILE, ITERATION, STATUS only

## Error Handling

| Scenario | Action |
|----------|--------|
| Vibe too short (<3 words) | Ask user for more detail via AskUserQuestion |
| Agent fails | Report error, offer retry |
| File write fails | Report error, suggest checking permissions |
| Draft file missing during refinement | Report error, suggest starting fresh |

## Example Usage

```bash
# Create initial draft
/prompt-builder "a prompt that reviews PRs for security issues"

# Command creates draft, user reviews file

# User provides feedback
User: "add more focus on OWASP top 10"

# Command launches agent to refine, reports update

# User continues refining
User: "add specific examples for SQL injection"

# Command launches agent again, reports update

# User finishes
User: "done"

# Command reports completion
```

## Integration

Prompt Builder creates prompts for:
- Custom slash commands
- Custom subagents
- One-off automation tasks
- Project-specific workflows

After building a prompt:
- Copy to `.claude/commands/` for slash commands
- Copy to `.claude/agents/` for subagents
- Use directly in conversation for one-off tasks
