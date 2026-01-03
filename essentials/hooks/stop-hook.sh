#!/bin/bash

# Essentials Stop Hook
# Handles implement-loop, spec-loop, and beads-loop continuation
# Prevents session exit when a loop is active

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

# Function to sync closed beads back to OpenSpec tasks.md
# Returns: SYNCED_COUNT variable set with number of tasks synced
sync_beads_to_openspec() {
  local label="$1"
  SYNCED_COUNT=0

  # Only sync if label starts with openspec:
  if [[ "$label" != openspec:* ]]; then
    return 0
  fi

  local change_name="${label#openspec:}"
  local change_dir="openspec/changes/$change_name"
  local tasks_file="$change_dir/tasks.md"
  local mapping_file="$change_dir/.beads-mapping.json"

  if [[ ! -f "$tasks_file" ]]; then
    return 0
  fi

  # Get all closed beads with this label
  local closed_beads
  closed_beads=$(bd list -l "$label" --status closed --json 2>/dev/null || echo "[]")

  if [[ "$closed_beads" == "[]" ]] || [[ -z "$closed_beads" ]]; then
    return 0
  fi

  local temp_file="${tasks_file}.tmp.$$"
  cp "$tasks_file" "$temp_file"

  # Method 1: Use mapping file if available (more reliable)
  if [[ -f "$mapping_file" ]]; then
    local closed_ids
    closed_ids=$(echo "$closed_beads" | jq -r '.[].id' 2>/dev/null || echo "")

    while IFS= read -r bead_id; do
      [[ -z "$bead_id" ]] && continue

      # Get task line number from mapping
      local task_line
      task_line=$(jq -r ".tasks[] | select(.bead_id == \"$bead_id\") | .task_line" "$mapping_file" 2>/dev/null || echo "")

      if [[ -n "$task_line" ]] && [[ "$task_line" != "null" ]]; then
        # Mark specific line as complete using line number
        sed -i.bak "${task_line}s/- \[ \]/- [x]/" "$temp_file" 2>/dev/null
        rm -f "${temp_file}.bak"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
      fi
    done <<< "$closed_ids"
  else
    # Method 2: Fallback to title matching
    local titles
    titles=$(echo "$closed_beads" | jq -r '.[].title' 2>/dev/null || echo "")

    while IFS= read -r title; do
      [[ -z "$title" ]] && continue

      # Escape special regex characters in title
      local escaped_title
      escaped_title=$(printf '%s\n' "$title" | sed 's/[[\.*^$()+?{|]/\\&/g')

      # Check if task exists and is unchecked
      if grep -qE "^[[:space:]]*- \[ \].*${escaped_title}" "$temp_file" 2>/dev/null; then
        # Mark as complete
        sed -i.bak "s/^\([[:space:]]*- \)\[ \]\(.*${escaped_title}\)/\1[x]\2/" "$temp_file" 2>/dev/null
        rm -f "${temp_file}.bak"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
      fi
    done <<< "$titles"
  fi

  # Only update if changes were made
  if [[ $SYNCED_COUNT -gt 0 ]]; then
    mv "$temp_file" "$tasks_file"
  else
    rm -f "$temp_file"
  fi

  return 0
}

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

  # Update state file with new iteration and progress
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
Started: $(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date)

### Progress
- Iteration: $NEXT_ITERATION
- Status: In Progress

### Instructions

On each iteration:
1. If todos not created: Read plan, create todos with TodoWrite
2. Find next pending todo, mark as in_progress
3. Implement the change following the plan
4. Mark todo as completed when done
5. Repeat until all todos are completed

The loop will continue until ALL todos are marked 'completed'.
EOF

  PROMPT="Continue implementing the plan.

## Context Recovery

Plan file: $PLAN_PATH

## Instructions

1. **Check Todo Status**: Review your current todo list
2. **Find Next Task**: Look for pending or in_progress todos
3. **Read Plan Section**: Read the relevant section from the plan file
4. **Implement**: Make the required changes following the plan
5. **Run Tests**: Verify changes work
6. **Mark Complete**: Use TodoWrite to mark the todo as completed
7. **Repeat**: Continue until all todos are completed

## Completion

When done, say: \"Exit criteria passed - implementation complete\"

## Current State
- Iteration: $NEXT_ITERATION
- Plan: $PLAN_PATH"

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

  # Count remaining tasks (unchecked checkboxes)
  TOTAL_TASKS=$(grep -cE '^\s*- \[[ x]\]' "$TASKS_FILE" 2>/dev/null || echo "0")
  COMPLETED_TASKS=$(grep -cE '^\s*- \[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")
  REMAINING_TASKS=$((TOTAL_TASKS - COMPLETED_TASKS))

  if [[ "$REMAINING_TASKS" -eq 0 ]] && [[ "$TOTAL_TASKS" -gt 0 ]]; then
    echo "Spec loop: All tasks complete! ($COMPLETED_TASKS/$TOTAL_TASKS)"
    echo ""
    echo "To archive this change: openspec archive $CHANGE_ID"
    rm -f "$SPEC_STATE"
    exit 0
  fi

  # Continue spec loop
  NEXT_ITERATION=$((ITERATION + 1))

  # Update state file with new iteration and task progress
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
Started: $(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date)

### Progress
- Iteration: $NEXT_ITERATION
- Total Tasks: $TOTAL_TASKS
- Completed: $COMPLETED_TASKS
- Remaining: $REMAINING_TASKS
- Status: In Progress

### Instructions

On each iteration:
1. If todos not created: Read tasks.md, create todos with TodoWrite
2. Find next uncompleted task, mark as in_progress
3. Implement the change following the proposal/design
4. Mark todo as completed when done
5. Update tasks.md to mark the task [x]
6. Repeat until all tasks are marked [x]

The loop will continue until ALL tasks in tasks.md are marked [x].
EOF

  PROMPT="Continue implementing the OpenSpec change.

## Context Recovery

Change: $CHANGE_ID
Path: $CHANGE_PATH
Tasks: $COMPLETED_TASKS/$TOTAL_TASKS complete ($REMAINING_TASKS remaining)

## Key Files (with back-references)
- \`$CHANGE_PATH/proposal.md\` - Change proposal (has plan_reference)
- \`$CHANGE_PATH/design.md\` - Reference Implementation + Migration Patterns
- \`$CHANGE_PATH/tasks.md\` - Task checklist with Exit Criteria
- \`$CHANGE_PATH/specs/*.md\` - Requirements with scenarios

## Deep Recovery (if needed)

1. Find plan reference: \`grep \"Source Plan\" $CHANGE_PATH/proposal.md\`
2. Read plan for: full implementation code, architecture diagrams
3. Read design.md for: Reference Implementation (FULL code)
4. Read tasks.md for: Exit Criteria (EXACT commands)

## Instructions

1. **Check Todo Status**: Review your current todo list
2. **Find Next Task**: Look for pending or in_progress todos
3. **Read Context**: Read design.md Reference Implementation for full code
4. **Implement**: Follow the Reference Implementation from design.md
5. **Verify**: Run Exit Criteria commands from tasks.md
6. **Update tasks.md**: Mark the task \`[x]\` when complete
7. **Repeat**: Continue until all tasks are marked \`[x]\`

## Completion

When all tasks are marked \`[x]\`, say: \"All spec tasks complete\"

## Current State
- Iteration: $NEXT_ITERATION
- Change: $CHANGE_ID
- Tasks: $COMPLETED_TASKS/$TOTAL_TASKS complete"

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

  # Auto-sync closed beads back to OpenSpec tasks.md
  sync_beads_to_openspec "$LABEL_FILTER"
  if [[ $SYNCED_COUNT -gt 0 ]]; then
    echo "Beads loop: Synced $SYNCED_COUNT completed tasks to OpenSpec tasks.md"
  fi

  # Get sync stats for state file
  if [[ "$LABEL_FILTER" == openspec:* ]]; then
    CHANGE_NAME="${LABEL_FILTER#openspec:}"
    TASKS_FILE="openspec/changes/$CHANGE_NAME/tasks.md"
    if [[ -f "$TASKS_FILE" ]]; then
      TOTAL_SPEC_TASKS=$(grep -cE '^\s*- \[[ x]\]' "$TASKS_FILE" 2>/dev/null || echo "0")
      COMPLETED_SPEC_TASKS=$(grep -cE '^\s*- \[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")
    fi
  fi

  if [[ "$READY_COUNT" == "0" ]]; then
    echo "Beads loop: No ready tasks remaining. All beads complete!"

    # Final sync and auto-archive for OpenSpec
    if [[ "$LABEL_FILTER" == openspec:* ]]; then
      CHANGE_NAME="${LABEL_FILTER#openspec:}"
      TASKS_FILE="openspec/changes/$CHANGE_NAME/tasks.md"

      if [[ -f "$TASKS_FILE" ]]; then
        # One final sync to ensure all tasks marked
        sync_beads_to_openspec "$LABEL_FILTER"
        echo "Beads loop: OpenSpec tasks.md synced ($COMPLETED_SPEC_TASKS/$TOTAL_SPEC_TASKS complete)"

        # Auto-archive the OpenSpec change
        if command -v openspec &> /dev/null; then
          echo "Beads loop: Auto-archiving OpenSpec change: $CHANGE_NAME"
          if openspec archive "$CHANGE_NAME" 2>/dev/null; then
            echo "Beads loop: OpenSpec change archived successfully"
            echo "OPENSPEC_ARCHIVED=true"
          else
            echo "Beads loop: OpenSpec archive failed, run manually: openspec archive $CHANGE_NAME"
            echo "OPENSPEC_ARCHIVE_NEEDED=true"
          fi
        else
          echo "Beads loop: openspec CLI not found, archive manually: openspec archive $CHANGE_NAME"
          echo "OPENSPEC_ARCHIVE_NEEDED=true"
        fi
        echo "OPENSPEC_CHANGE=$CHANGE_NAME"
      fi
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

  # Build OpenSpec sync section if applicable
  OPENSPEC_SYNC_SECTION=""
  if [[ "$LABEL_FILTER" == openspec:* ]] && [[ -n "$TOTAL_SPEC_TASKS" ]]; then
    OPENSPEC_SYNC_SECTION="
### OpenSpec Sync
- Change: ${LABEL_FILTER#openspec:}
- Tasks Synced: $COMPLETED_SPEC_TASKS/$TOTAL_SPEC_TASKS
- Last Sync: $SYNCED_COUNT tasks this iteration
- Status: Auto-syncing ✓
"
  fi

  # Update state file with new iteration and task progress
  cat > "$BEADS_STATE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
label_filter: "$LABEL_FILTER"
started_at: "$(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date -u +%Y-%m-%dT%H:%M:%SZ)"
current_task: "$CURRENT_TASK"
openspec_synced: ${COMPLETED_SPEC_TASKS:-0}
openspec_total: ${TOTAL_SPEC_TASKS:-0}
---

## Beads Loop State

Label Filter: ${LABEL_FILTER:-"(all)"}
Started: $(echo "$FRONTMATTER" | grep '^started_at:' | sed 's/started_at: *//' | sed 's/^"\(.*\)"$/\1/' || date)

### Progress
- Iteration: $NEXT_ITERATION
- Ready Tasks: $READY_COUNT
- Current Task: ${CURRENT_TASK:-"(none)"}
- Status: In Progress
$OPENSPEC_SYNC_SECTION
### Instructions

On each iteration:
1. Run \`bd ready\` to find tasks with no blockers
2. Pick highest priority ready task
3. Run \`bd show <id>\` to get full task details
4. Mark as in_progress: \`bd update <id> --status in_progress\`
5. Implement following the task description
6. When done: \`bd close <id> --reason "Completed: <summary>"\`
7. Repeat until no ready tasks remain

The loop will continue until \`bd ready\` returns no tasks.
EOF

  LABEL_MSG=""
  if [[ -n "$LABEL_FILTER" ]]; then
    LABEL_MSG=" (label: $LABEL_FILTER)"
  fi

  PROMPT="Continue executing beads.

## Context Recovery

**Quick Recovery (bead is self-contained):**
- \`bd ready\` - See tasks with no blockers
- \`bd list --status in_progress\` - Find current work
- \`bd show <id>\` - Get full task details (has all context)

**Deep Recovery (using context chain):**

Each bead has dual back-references:
- Spec Reference → specs/*.md (requirements, scenarios)
- Plan Reference → .claude/plans/*-plan.md (source of truth)

1. \`bd show <id>\` - find spec_reference and plan_reference
2. Read spec for requirements and scenarios
3. Read plan for full implementation code, exit criteria

## Ready Tasks: $READY_COUNT$LABEL_MSG

## Instructions

1. **Find Ready Work**: Run \`bd ready\` to see available tasks
2. **Pick Task**: Select highest priority task
3. **Read Details**: Run \`bd show <id>\` for full context
4. **Start Work**: Run \`bd update <id> --status in_progress\`
5. **Implement**: Follow the Reference Implementation in the bead
6. **Verify**: Run Exit Criteria commands from the bead
7. **Complete**: Run \`bd close <id> --reason \"Completed: <summary>\"\`
8. **Repeat**: Continue until no ready tasks remain

## Completion

When no ready tasks remain, say: \"All beads complete\"

## Current State
- Iteration: $NEXT_ITERATION
- Ready Tasks: $READY_COUNT
- Label Filter: ${LABEL_FILTER:-"(all)"}"

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
