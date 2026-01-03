---
description: "Implement a plan with iterative loop until completion"
argument-hint: "<plan_path> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh)", "Read", "TodoWrite", "Bash"]
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

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-implement-loop.sh" $ARGUMENTS

# Extract and display loop info
if [ -f .claude/implement-loop.local.md ]; then
  PLAN_PATH=$(grep '^plan_path:' .claude/implement-loop.local.md | sed 's/plan_path: *//' | sed 's/^"\(.*\)"$/\1/')
  echo ""
  echo "==============================================================="
  echo "IMPLEMENT LOOP - Plan Implementation Mode"
  echo "==============================================================="
  echo ""
  echo "Plan: $PLAN_PATH"
  echo ""
  echo "WORKFLOW:"
  echo "  1. Read the plan and create todos from implementation sections"
  echo "  2. Work through each todo (mark in_progress -> completed)"
  echo "  3. Run tests and verify changes work"
  echo "  4. The loop continues until EXIT CRITERIA pass"
  echo ""
  echo "EXIT CRITERIA (from plan's ## Exit Criteria section):"
  echo "  - All todos marked as 'completed'"
  echo "  - Verification Script passes (exit code 0)"
  echo "  - Tests, linting, and type checks pass"
  echo ""
  echo "STOPPING CONDITIONS:"
  echo "  - Exit Criteria verification passes"
  echo "  - Max iterations reached (if set)"
  echo "  - User cancels with /cancel-implement"
  echo "==============================================================="
fi
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

### Step 2: Create Todos

Use **TodoWrite** to create a todo for each:
- File that needs to be edited or created
- Major requirement to satisfy
- Run exit criteria verification

Example todo structure:
```
1. [pending] Implement changes to src/auth/handler.py
2. [pending] Create new file src/auth/oauth_provider.py
3. [pending] Update tests in tests/test_auth.py
4. [pending] Run test suite and fix failures
5. [pending] Run exit criteria verification
```

### Step 3: Implement Each Todo

For each todo:
1. Mark it as **in_progress** using TodoWrite
2. Read the relevant section from the plan
3. Implement the changes following the plan exactly
4. Verify the implementation (run tests, type checks)
5. Mark as **completed** ONLY when fully done

### Step 4: Run Exit Criteria

Before declaring completion:
1. Find the `## Exit Criteria` section in the plan
2. Run the `### Verification Script` command
3. If it passes (exit 0), say "Exit criteria passed - implementation complete"
4. If it fails, fix the issues and retry

### Step 5: Loop Continues Until Exit Criteria Pass

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
