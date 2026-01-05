---
description: "Implement a plan with iterative loop until completion"
argument-hint: "<plan_path> [--step|--auto] [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh)", "Read", "TodoWrite", "Bash", "Edit", "AskUserQuestion"]
hide-from-slash-command-tool: "true"
---

# Implement Loop Command

Execute a plan file iteratively until all todos are complete AND exit criteria pass.

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Setup

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh" $ARGUMENTS
```

## Initial Instructions

You are now in **implement loop mode**. Your task is to implement the plan completely.

### Step 1: Read the Plan

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

### Step 2: Auto-Assess & Decompose

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

### Step 3: Create Todos

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

### Step 4: Implement Each Todo

For each todo:
1. Mark it as **in_progress** using TodoWrite
2. Read the relevant section from the plan
3. Implement the changes following the plan exactly
4. Verify the implementation (run tests, type checks)
5. Mark as **completed** ONLY when fully done

### Step 5: Run Exit Criteria

Before declaring completion:
1. Find the `## Exit Criteria` section in the plan
2. Run the `### Verification Script` command
3. If it passes (exit 0), say "Exit criteria passed - implementation complete"
4. If it fails, fix the issues and retry

### Step 6: Loop Continues Until Exit Criteria Pass

When you try to exit:
- The stop hook extracts the Verification Script from the plan
- It runs the verification command
- If verification PASSES → loop ends, implementation complete
- If verification FAILS → loop continues with error context
- If todos remain incomplete → loop continues

### Context Recovery

If context is compacted and you lose track:
1. Read the plan file again
2. Check the current todo list status
3. Find the `## Exit Criteria` section
4. Continue with the next pending/in_progress todo

**IMPORTANT**:
- The plan file is your source of truth
- Exit Criteria MUST pass before the loop will end
- Run the verification script to confirm completion
- Consult Risk Analysis for rollback strategy if implementation issues arise
- Use Success Metrics to validate quality beyond pass/fail

### Step Mode (Default)

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
