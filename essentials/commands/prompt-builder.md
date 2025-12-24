---
allowed-tools: Task, TaskOutput, Read, Write
argument-hint: <vibe-prompt>
description: Iteratively build high-quality prompts from vibe descriptions (project)
---

Build a high-quality Claude Code prompt from a vibe description through iterative refinement.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the draft FILE directly, not in chat.

## Arguments

1. **Vibe prompt**: Rough description of what the prompt should do

## Instructions

### Step 1: Generate Draft File Path

Create a unique draft file path:
- Pattern: `.claude/plans/prompt-builder-{slug}-draft.md`
- Derive slug from the vibe (e.g., "security-review", "test-generator")

### Step 2: Launch Prompt Builder

Launch `prompt-builder-default` agent **in background**:

```
Build a prompt from this vibe.

Vibe: <user's vibe prompt>

Draft file: <generated file path>

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
   Refine the prompt based on user feedback.

   Draft file: <same file path>

   User feedback: <their feedback>

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
┌─────────────────────────────────────┐
│ Launch prompt-builder-default       │◄── background
└─────────────────────────────────────┘
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
    ├──[feedback]──► Launch agent to refine ──► "Draft updated" ──► loop
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
