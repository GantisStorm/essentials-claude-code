#!/bin/bash

# Essentials Stop Hook
# Handles implement-loop, spec-loop, and beads-loop continuation
# Prevents session exit when a loop is active

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

# Function to check for completion signals in transcript
check_completion_signals() {
  local signals="$1"

  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 || echo "")

    if [[ -n "$LAST_LINE" ]]; then
      LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
        .message.content |
        if type == "array" then
          map(select(.type == "text")) |
          map(.text) |
          join("\n")
        else
          ""
        end
      ' 2>/dev/null || echo "")

      if echo "$LAST_OUTPUT" | grep -qiE "$signals"; then
        return 0  # Completion detected
      fi
    fi
  fi
  return 1  # No completion
}

# ============================================================
# CHECK FOR IMPLEMENT-LOOP
# ============================================================

IMPLEMENT_STATE=".claude/implement-loop.local.md"

if [[ -f "$IMPLEMENT_STATE" ]]; then
  # Parse markdown frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$IMPLEMENT_STATE" 2>/dev/null || echo "")
  ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")
  MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "0")
  PLAN_PATH=$(echo "$FRONTMATTER" | grep '^plan_path:' | sed 's/plan_path: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")

  # Validate numeric fields
  [[ ! "$ITERATION" =~ ^[0-9]+$ ]] && ITERATION=1
  [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && MAX_ITERATIONS=0

  # Check max iterations
  if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo "Implement loop: Max iterations ($MAX_ITERATIONS) reached."
    rm -f "$IMPLEMENT_STATE"
    exit 0
  fi

  # Check plan exists
  if [[ -z "$PLAN_PATH" ]] || [[ ! -f "$PLAN_PATH" ]]; then
    echo "Implement loop: Plan file not found, ending loop" >&2
    rm -f "$IMPLEMENT_STATE"
    exit 0
  fi

  # Check for completion signals
  if check_completion_signals "exit criteria.*passed|implementation complete|all todos.*completed|all tasks.*completed|verification.*passed"; then
    echo "Implement loop: Completion signal detected!"
    rm -f "$IMPLEMENT_STATE"
    exit 0
  fi

  # Continue implement loop
  NEXT_ITERATION=$((ITERATION + 1))

  # Update state file
  cat > "$IMPLEMENT_STATE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
plan_path: "$PLAN_PATH"
started_at: "$(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date -u +%Y-%m-%dT%H:%M:%SZ)"
---

## Implementation Loop State

Plan: $PLAN_PATH
Iteration: $NEXT_ITERATION

### Instructions

1. Check todo status
2. Find next pending todo, mark as in_progress
3. Implement following the plan
4. Mark todo as completed
5. Repeat until all todos completed

Say "Exit criteria passed" when done.
EOF

  PROMPT="Continue implementing the plan.

Plan file: $PLAN_PATH
Iteration: $NEXT_ITERATION

Instructions:
1. Check your todo list
2. Find next pending/in_progress todo
3. Implement the change
4. Mark todo completed
5. Repeat until done

When complete, say: \"Exit criteria passed - implementation complete\""

  jq -n \
    --arg prompt "$PROMPT" \
    --arg msg "Implement loop iteration $NEXT_ITERATION | Plan: $PLAN_PATH" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }' 2>/dev/null || echo '{"decision":"block","reason":"Continue implementation"}'

  exit 0
fi

# ============================================================
# CHECK FOR SPEC-LOOP
# ============================================================

SPEC_STATE=".claude/spec-loop.local.md"

if [[ -f "$SPEC_STATE" ]]; then
  # Parse markdown frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SPEC_STATE" 2>/dev/null || echo "")
  ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")
  MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "0")
  CHANGE_ID=$(echo "$FRONTMATTER" | grep '^change_id:' | sed 's/change_id: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")
  CHANGE_PATH=$(echo "$FRONTMATTER" | grep '^change_path:' | sed 's/change_path: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")

  # Validate numeric fields
  [[ ! "$ITERATION" =~ ^[0-9]+$ ]] && ITERATION=1
  [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && MAX_ITERATIONS=0

  # Check max iterations
  if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo "Spec loop: Max iterations ($MAX_ITERATIONS) reached."
    rm -f "$SPEC_STATE"
    exit 0
  fi

  # Check change path exists
  if [[ -z "$CHANGE_PATH" ]] || [[ ! -d "$CHANGE_PATH" ]]; then
    echo "Spec loop: Change directory not found, ending loop" >&2
    rm -f "$SPEC_STATE"
    exit 0
  fi

  TASKS_FILE="$CHANGE_PATH/tasks.md"
  if [[ ! -f "$TASKS_FILE" ]]; then
    echo "Spec loop: tasks.md not found, ending loop" >&2
    rm -f "$SPEC_STATE"
    exit 0
  fi

  # Check for completion signals
  if check_completion_signals "all spec tasks complete|all tasks complete|spec loop complete|implementation complete"; then
    echo "Spec loop: Completion signal detected!"
    rm -f "$SPEC_STATE"
    exit 0
  fi

  # Count remaining tasks
  TOTAL_TASKS=$(grep -cE '^\s*- \[[ x]\]' "$TASKS_FILE" 2>/dev/null || echo "0")
  COMPLETED_TASKS=$(grep -cE '^\s*- \[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")
  REMAINING_TASKS=$((TOTAL_TASKS - COMPLETED_TASKS))

  if [[ "$REMAINING_TASKS" -eq 0 ]] && [[ "$TOTAL_TASKS" -gt 0 ]]; then
    echo "Spec loop: All tasks complete! ($COMPLETED_TASKS/$TOTAL_TASKS)"
    echo "To archive: openspec archive $CHANGE_ID"
    rm -f "$SPEC_STATE"
    exit 0
  fi

  # Continue spec loop
  NEXT_ITERATION=$((ITERATION + 1))

  # Update state file
  cat > "$SPEC_STATE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
change_id: "$CHANGE_ID"
change_path: "$CHANGE_PATH"
started_at: "$(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date -u +%Y-%m-%dT%H:%M:%SZ)"
---

## Spec Loop State

Change: $CHANGE_ID
Path: $CHANGE_PATH
Tasks: $COMPLETED_TASKS/$TOTAL_TASKS complete
Iteration: $NEXT_ITERATION

### Instructions

1. Check todo status
2. Find next uncompleted task
3. Implement following proposal/design
4. Mark todo completed
5. Update tasks.md: change \`- [ ]\` to \`- [x]\`
6. Repeat until all tasks marked [x]

Say "All spec tasks complete" when done.
EOF

  PROMPT="Continue implementing the OpenSpec change.

Change: $CHANGE_ID
Path: $CHANGE_PATH
Tasks: $COMPLETED_TASKS/$TOTAL_TASKS complete ($REMAINING_TASKS remaining)
Iteration: $NEXT_ITERATION

Key files:
- $CHANGE_PATH/proposal.md
- $CHANGE_PATH/design.md
- $CHANGE_PATH/tasks.md

Instructions:
1. Check your todo list
2. Find next pending/in_progress todo
3. Implement the change
4. Mark todo completed
5. Edit tasks.md: change \`- [ ]\` to \`- [x]\`
6. Repeat until done

When all tasks marked [x], say: \"All spec tasks complete\""

  jq -n \
    --arg prompt "$PROMPT" \
    --arg msg "Spec loop iteration $NEXT_ITERATION | $CHANGE_ID: $COMPLETED_TASKS/$TOTAL_TASKS tasks" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }' 2>/dev/null || echo '{"decision":"block","reason":"Continue spec implementation"}'

  exit 0
fi

# ============================================================
# CHECK FOR BEADS-LOOP
# ============================================================

BEADS_STATE=".claude/beads-loop.local.md"

if [[ -f "$BEADS_STATE" ]]; then
  # Parse markdown frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$BEADS_STATE" 2>/dev/null || echo "")
  ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")
  MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "0")
  LABEL_FILTER=$(echo "$FRONTMATTER" | grep '^label_filter:' | sed 's/label_filter: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")

  # Validate numeric fields
  [[ ! "$ITERATION" =~ ^[0-9]+$ ]] && ITERATION=1
  [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && MAX_ITERATIONS=0

  # Check max iterations
  if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo "Beads loop: Max iterations ($MAX_ITERATIONS) reached."
    rm -f "$BEADS_STATE"
    exit 0
  fi

  # Check for completion signals
  if check_completion_signals "all beads complete|no ready tasks|beads loop complete|all tasks complete"; then
    echo "Beads loop: Completion signal detected!"
    rm -f "$BEADS_STATE"
    exit 0
  fi

  # Check if there are ready tasks
  if [[ -n "$LABEL_FILTER" ]]; then
    READY_COUNT=$(bd ready -l "$LABEL_FILTER" --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
  else
    READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
  fi

  if [[ "$READY_COUNT" == "0" ]]; then
    echo "Beads loop: No ready tasks remaining. All beads complete!"

    # Remind about OpenSpec archive if applicable
    if [[ "$LABEL_FILTER" == openspec:* ]]; then
      CHANGE_NAME="${LABEL_FILTER#openspec:}"
      echo "To archive: openspec archive $CHANGE_NAME"
    fi

    rm -f "$BEADS_STATE"
    exit 0
  fi

  # Continue beads loop
  NEXT_ITERATION=$((ITERATION + 1))

  # Get in-progress task if any
  if [[ -n "$LABEL_FILTER" ]]; then
    CURRENT_TASK=$(bd list -l "$LABEL_FILTER" --status in_progress --json 2>/dev/null | jq -r '.[0].id // ""' 2>/dev/null || echo "")
  else
    CURRENT_TASK=$(bd list --status in_progress --json 2>/dev/null | jq -r '.[0].id // ""' 2>/dev/null || echo "")
  fi

  # Update state file
  cat > "$BEADS_STATE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
label_filter: "$LABEL_FILTER"
started_at: "$(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date -u +%Y-%m-%dT%H:%M:%SZ)"
current_task: "$CURRENT_TASK"
---

## Beads Loop State

Label: ${LABEL_FILTER:-"(all)"}
Ready: $READY_COUNT
Current: ${CURRENT_TASK:-"(none)"}
Iteration: $NEXT_ITERATION

### Instructions

1. Run \`bd ready\` to find tasks
2. Pick highest priority task
3. Run \`bd show <id>\` for details
4. Run \`bd update <id> --status in_progress\`
5. Implement the task
6. Run \`bd close <id> --reason "Done: <summary>"\`
7. If OpenSpec: edit tasks.md to mark [x]
8. Repeat until no ready tasks

Say "All beads complete" when done.
EOF

  LABEL_MSG=""
  if [[ -n "$LABEL_FILTER" ]]; then
    LABEL_MSG=" (label: $LABEL_FILTER)"
  fi

  PROMPT="Continue executing beads.

Ready tasks: $READY_COUNT$LABEL_MSG
Current task: ${CURRENT_TASK:-"(none)"}
Iteration: $NEXT_ITERATION

Instructions:
1. Run \`bd ready\` to see available tasks
2. Pick highest priority task
3. Run \`bd show <id>\` for full context
4. Run \`bd update <id> --status in_progress\`
5. Implement the task
6. Run \`bd close <id> --reason \"Done: <summary>\"\`
7. **If OpenSpec**: Edit tasks.md to mark that task \`[x]\`
8. Repeat until no ready tasks

When no ready tasks remain, say: \"All beads complete\""

  jq -n \
    --arg prompt "$PROMPT" \
    --arg msg "Beads loop iteration $NEXT_ITERATION | Ready: $READY_COUNT$LABEL_MSG" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }' 2>/dev/null || echo '{"decision":"block","reason":"Continue beads execution"}'

  exit 0
fi

# ============================================================
# NO ACTIVE LOOP - ALLOW EXIT
# ============================================================

exit 0
