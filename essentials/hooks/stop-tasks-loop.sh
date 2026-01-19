#!/bin/bash

# Tasks Loop Stop Hook
# Continues loop while pending tasks remain

MARKER_FILE=".claude/tasks-loop-active"

# Exit early if no active loop
if [[ ! -f "$MARKER_FILE" ]]; then
  exit 0
fi

# Parse marker file (format: prd_path:max_iterations:current_iteration)
IFS=':' read -r PRD_PATH MAX_ITERATIONS ITERATION < "$MARKER_FILE"

[[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && MAX_ITERATIONS=0
[[ ! "$ITERATION" =~ ^[0-9]+$ ]] && ITERATION=1

# Verify prd.json exists
if [[ ! -f "$PRD_PATH" ]]; then
  echo "Tasks loop: prd.json not found: $PRD_PATH"
  rm -f "$MARKER_FILE"
  exit 0
fi

# Read hook input for completion signals
HOOK_INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

# Check for completion signals
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | jq -r '.message.content | if type == "array" then map(select(.type == "text")) | map(.text) | join("\n") else "" end' 2>/dev/null || echo "")
  if echo "$LAST_OUTPUT" | grep -qiE "all tasks complete|tasks loop complete"; then
    echo "Tasks loop complete!"
    rm -f "$MARKER_FILE"
    exit 0
  fi
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Tasks loop: Max iterations ($MAX_ITERATIONS) reached."
  rm -f "$MARKER_FILE"
  exit 0
fi

# Count pending and ready tasks
TOTAL_TASKS=$(jq '.userStories | length' "$PRD_PATH" 2>/dev/null || echo "0")
COMPLETED_TASKS=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH" 2>/dev/null || echo "0")
PENDING_TASKS=$((TOTAL_TASKS - COMPLETED_TASKS))

# Count ready tasks (pending and no blocking dependencies)
READY_TASKS=$(jq '
  .userStories as $all |
  [.userStories[] |
    select(.passes == false) |
    select(
      (.dependsOn == null) or
      (.dependsOn | length == 0) or
      ((.dependsOn // []) | all(. as $dep | ($all | map(select(.id == $dep and .passes == true)) | length > 0)))
    )
  ] | length
' "$PRD_PATH" 2>/dev/null || echo "0")

# All done?
if [[ "$PENDING_TASKS" == "0" ]]; then
  echo "Tasks loop: All tasks complete!"
  rm -f "$MARKER_FILE"
  exit 0
fi

# No ready tasks (all blocked)?
if [[ "$READY_TASKS" == "0" ]]; then
  echo "Tasks loop: No ready tasks (all blocked by dependencies). Check dependencies."
  rm -f "$MARKER_FILE"
  exit 0
fi

# Increment iteration and continue
NEXT_ITERATION=$((ITERATION + 1))
echo "$PRD_PATH:$MAX_ITERATIONS:$NEXT_ITERATION" > "$MARKER_FILE"

PROMPT="Continue executing tasks from prd.json.

File: $PRD_PATH
Completed: $COMPLETED_TASKS/$TOTAL_TASKS
Ready (no blockers): $READY_TASKS
Iteration: $NEXT_ITERATION

Instructions:
1. Read prd.json to find next pending task (passes: false)
2. Pick highest priority task with resolved dependencies
3. Implement following the task description
4. Update the task in prd.json: set passes: true
5. Continue until all tasks complete

When all tasks are complete, say: \"All tasks complete\""

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "Tasks loop iteration $NEXT_ITERATION | $COMPLETED_TASKS/$TOTAL_TASKS complete, $READY_TASKS ready" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
