---
description: "Implement a plan with iterative loop until completion"
argument-hint: "<plan_path> [--step|--auto] [--max-iterations N]"
model: haiku
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh)", "Read", "TodoWrite", "Bash", "Edit", "AskUserQuestion"]
hide-from-slash-command-tool: "true"
---

# Implement Loop Command

Execute a plan file iteratively until all todos are complete AND exit criteria pass.

**IMPORTANT**: The plan file is your source of truth. Exit Criteria MUST pass before the loop will end.

## Why Implement Loop?

Iterative implementation with automatic verification ensures plans are fully executed with quality checks.

- **Complete execution** - Continues until all todos done AND exit criteria pass
- **Auto-decomposition** - Large plans automatically broken into manageable groups
- **Step mode control** - Pause after each todo to prevent context degradation
- **Context recovery** - Can resume from any point by re-reading plan state

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

The command accepts:
- `<plan_path>`: Path to the plan file (required)
- `--step`: Step mode (default) - pause after each todo for human control
- `--auto`: Auto mode - skip pauses but still follow todo order
- `--max-iterations N`: Maximum number of iterations before stopping

## Instructions

### Step 1: Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh" $ARGUMENTS
```

You are now in **implement loop mode**. Your task is to implement the plan completely.

### Step 2: Read the Plan

Read the plan file specified above. Extract:
1. **Files to Edit** - existing files that need modification
2. **Files to Create** - new files to create
3. **Implementation Plan** - per-file implementation instructions
4. **Requirements** - acceptance criteria that must be satisfied
5. **Exit Criteria** - verification script and success conditions
6. **Testing Strategy** (if present) - unit, integration, and manual test requirements
7. **Risk Analysis** (if present) - technical/integration risks and rollback strategy
8. **Success Metrics** (if present) - quantifiable success criteria
9. **Post-Implementation Verification** (if present) - verification steps beyond exit criteria

### Step 3: Auto-Assess & Decompose

After reading the plan, **automatically** assess and decompose if thresholds are exceeded:

| Signal | Threshold | Action |
|--------|-----------|--------|
| Files to modify | >5 files | AUTO decompose by file group |
| Total lines | >500 lines | AUTO decompose by feature |
| Subsystems | >2 unrelated areas | AUTO decompose by subsystem |
| Dependencies | Complex ordering | AUTO decompose with ordering |

**This is AUTOMATIC** - no user prompt needed. If triggers are met, decompose immediately.

**Auto-Decomposition Process:**
1. Break the plan into logical groups (by subsystem, by file, by feature)
2. Create grouped sub-todos using TodoWrite
3. Each group is independently completable
4. For very large plans (>1000 lines), suggest escalating to `/proposal-creator` → `/beads-loop`

**Report in output:**
```
COMPLEXITY ASSESSMENT:
- Files: N (threshold: 5)
- Lines: N (threshold: 500)
- Subsystems: N (threshold: 2)
- Decision: [DIRECT | AUTO_DECOMPOSED]
- Groups created: [list if decomposed]
```

### Step 4: Create Todos

Use **TodoWrite** to create a todo for each:
- File that needs to be edited or created
- Major requirement to satisfy
- Tests from Testing Strategy (unit tests, integration tests)
- Run exit criteria verification
- Post-implementation verification steps (if present)

Example todo structure:
```
1. [pending] Implement changes to src/auth/handler.py
2. [pending] Create new file src/auth/oauth_provider.py
3. [pending] Write unit tests per Testing Strategy
4. [pending] Run test suite and fix failures
5. [pending] Run exit criteria verification
6. [pending] Complete post-implementation verification
```

### Step 5: Implement Each Todo

For each todo:
1. Mark it as **in_progress** using TodoWrite
2. Read the relevant section from the plan
3. Implement the changes following the plan exactly
4. Verify the implementation (run tests, type checks)
5. Mark as **completed** ONLY when fully done

### Step 6: Run Exit Criteria

Before declaring completion:
1. Find the `## Exit Criteria` section in the plan
2. Run the `### Verification Script` command
3. If it passes (exit 0), say "Exit criteria passed - implementation complete"
4. If it fails, fix the issues and retry

### Step 7: Loop Continues Until Exit Criteria Pass

When you try to exit:
- The stop hook extracts the Verification Script from the plan
- It runs the verification command
- If verification PASSES → loop ends, implementation complete
- If verification FAILS → loop continues with error context
- If todos remain incomplete → loop continues

### Step 8: Context Recovery

If context is compacted and you lose track:
1. Read the plan file again
2. Check the current todo list status
3. Find the `## Exit Criteria` section
4. Continue with the next pending/in_progress todo

**Additional notes:**
- Consult Risk Analysis for rollback strategy if implementation issues arise
- Use Success Metrics to validate quality beyond pass/fail

## Step Mode (Default)

Step mode pauses after each todo for human control. This prevents context compaction and quality degradation on large plans.

**After completing each todo, you MUST:**

1. Check todo list status
2. Show execution order in the pause message
3. Use AskUserQuestion to let user confirm or continue

**Before pausing, output execution status:**
```
===============================================================
TODO COMPLETED: <todo-name>
===============================================================

Progress: N/M todos complete

EXECUTION ORDER (remaining):
  Next → Todo 3: Add validation logic
  Then → Todo 4: Write unit tests
  Then → Todo 5: Run exit criteria
===============================================================
```

**Then use AskUserQuestion:**

The options MUST include:
1. **Continue (Recommended)** - proceed to next pending todo
2. **Stop** - end the implement loop
3. *(Other is automatic for feedback)*

Example:
```
Use AskUserQuestion with:
- question: "Todo complete. Next: Add validation logic. Continue?"
- header: "Next step"
- options:
  - label: "Continue (Recommended)"
    description: "Proceed to: Add validation logic"
  - label: "Stop"
    description: "End the implement loop here"
```

Based on the response:
- **Continue**: Proceed to the next pending todo
- **Stop**: End the loop and report progress
- **Other/feedback**: Handle user's custom input

**Auto mode** (`--auto` flag): Skips pauses but still follows todo order.

## Workflow Diagram

```
/implement-loop <plan_path> [--step|--auto]
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: SETUP                                                 │
│                                                               │
│  • Run setup-implement-loop.sh with arguments                 │
│  • Enter implement loop mode                                  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: READ PLAN                                             │
│                                                               │
│  • Extract files to edit/create                               │
│  • Extract implementation instructions                        │
│  • Extract exit criteria and verification script              │
│  • Extract testing strategy, risk analysis, success metrics   │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: AUTO-ASSESS & DECOMPOSE                               │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ COMPLEXITY CHECK:                                       │  │
│  │                                                         │  │
│  │  Files >5?     → AUTO decompose by file group           │  │
│  │  Lines >500?   → AUTO decompose by feature              │  │
│  │  Subsystems >2? → AUTO decompose by subsystem           │  │
│  │                                                         │  │
│  │  Output: COMPLEXITY ASSESSMENT report                   │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 4-5: CREATE & IMPLEMENT TODOS                            │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ TODO LOOP:                                              │  │
│  │                                                         │  │
│  │  For each todo:                                         │  │
│  │    1. Mark in_progress                                  │  │
│  │    2. Read relevant plan section                        │  │
│  │    3. Implement changes                                 │  │
│  │    4. Verify implementation                             │  │
│  │    5. Mark completed                                    │  │
│  │                                                         │  │
│  │  Step mode: Pause after each todo (AskUserQuestion)     │  │
│  │  Auto mode: Continue without pauses                     │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 6-7: EXIT CRITERIA VERIFICATION                          │
│                                                               │
│  • Run verification script from plan                          │
│  • If PASS (exit 0) → Implementation complete                 │
│  • If FAIL → Fix issues, retry loop                           │
│  • If todos incomplete → Continue loop                        │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ OUTPUT: Implementation Complete                               │
│                                                               │
│  • All todos marked completed                                 │
│  • Exit criteria verification passed                          │
│  • Success metrics validated                                  │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| Exit criteria fail | Fix issues and retry verification |
| Context compacted | Re-read plan file, check todo status, continue |
| Implementation issues | Consult Risk Analysis for rollback strategy |
| Very large plan (>1000 lines) | Suggest escalating to `/proposal-creator` → `/beads-loop` |
| Todos remain incomplete | Loop continues until all complete |

## Example Usage

```bash
# Implement a feature plan with step mode (default)
/implement-loop .plans/add-user-auth.md

# Implement with auto mode (no pauses)
/implement-loop .plans/fix-memory-leak.md --auto

# Implement with maximum iterations limit
/implement-loop .plans/refactor-api.md --max-iterations 10

# Implement a bug fix plan
/implement-loop .plans/bug-null-pointer.md --step
```
