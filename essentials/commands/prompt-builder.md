---
allowed-tools: Task, TaskOutput, Read, Write
argument-hint: <vibe-prompt>
description: Build high-quality prompts from vibe descriptions using multi-pass revision (project)
---

Build high-quality Claude Code prompts from vibe descriptions using iterative multi-pass revision with reflection checkpoints and quality validation. The prompt-builder agent applies a meta builder pattern with anti-pattern scanning, consumer simulation, and quality scoring to ensure prompts are clear, specific, and actionable.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the draft FILE directly, not in chat.

**Quality Process**: The agent applies 6 validation passes (structural validation, anti-pattern scan, consumer simulation, quality scoring, final review) to ensure prompts score ≥40/50 across 5 dimensions.

## Arguments

1. **Vibe prompt**: Rough description of what the prompt should do

## Instructions

### Step 1: Generate Draft File Path

Create a unique draft file path:
- Pattern: `.claude/plans/prompt-builder-{slug}-{hash5}-draft.md`
- Derive slug from the vibe (e.g., "security-review", "test-generator")
- Generate a 5-character random hash to prevent conflicts (lowercase alphanumeric)
- Example: `.claude/plans/prompt-builder-security-review-7k3m2-draft.md`

### Step 2: Launch Prompt Builder

Launch `prompt-builder-default` agent **in background**:

```
Build a high-quality prompt from this vibe using multi-pass revision with quality validation.

Vibe: <user's vibe prompt>

Draft file: <generated file path>

Process:
- Phase 0-4: Context gathering, analysis, research, drafting
- Phase 4.5: Reflection checkpoint (ReAct loop)
- Phase 5: Iterative revision (6 validation passes with meta builder pattern)
- Phase 6: Write draft with quality scores and revision log

Write the draft to the specified file. Return only:
DRAFT_FILE: <path>
ITERATION: 1
STATUS: CREATED
```

Use `subagent_type: "prompt-builder-default"` with `run_in_background: true`.

### Step 3: Wait and Report

Use `TaskOutput` with `block: true`. Then output ONLY:

```
Draft ready: <file path>

Review and provide feedback, or say "done" when satisfied.
```

**DO NOT** read or display the draft content. User opens the file directly.

### Step 4: Refinement Loop

When user provides feedback:

1. **If refinement request** (e.g., "add more examples", "focus on X"):

   Launch `prompt-builder-default` again:

   ```
   Refine the prompt based on user feedback using the same multi-pass revision process.

   Draft file: <same file path>

   User feedback: <their feedback>

   Process (Phase 7):
   - Read existing draft
   - Apply user's requested changes
   - Re-run all 6 validation passes (structural, anti-pattern, consumer simulation, quality scoring, final review)
   - Increment iteration number
   - Update revision history with changes and quality re-assessment

   Update the file in place. Return only:
   DRAFT_FILE: <path>
   ITERATION: <n+1>
   STATUS: UPDATED
   ```

   Wait for completion, then output:
   ```
   Draft updated: <file path> (iteration N)

   Review and provide more feedback, or say "done".
   ```

2. **If user says "done"** (e.g., "done", "looks good", "that's it"):

   Output: `Done. Copy the prompt from: <file path>`

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
│ Launch prompt-builder-default (background)       │
│                                                  │
│  PHASE 0-4: Context, Analysis, Research, Draft   │
│  PHASE 4.5: Reflection Checkpoint (ReAct)        │◄── Meta builder pattern
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
│ Report: "Draft      │
│ ready at: <path>"   │◄── minimal output
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ User reviews FILE   │◄── user opens file directly
│ directly            │
└─────────────────────┘
    │
    ├──[feedback]──► Launch agent (Phase 7: re-run 6 passes) ──► "Draft updated" ──► loop
    │
    └──[done]──► User copies prompt from file
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Vibe too short (<3 words) | Ask for more detail |
| Agent fails | Report error, offer retry |
| File write fails | Report error |

## Example Usage

```bash
/prompt-builder "a prompt that reviews PRs for security issues"
/prompt-builder "subagent for analyzing test coverage with pytest"
```
