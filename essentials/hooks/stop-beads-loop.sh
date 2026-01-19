#!/bin/bash

# Beads Loop Stop Hook
# Continues loop while ready tasks remain

MARKER_FILE=".claude/beads-loop-active"

# Exit early if no active loop
if [[ ! -f "$MARKER_FILE" ]]; then
  exit 0
fi

# Parse marker file (format: label:max_iterations:current_iteration)
IFS=':' read -r LABEL_FILTER MAX_ITERATIONS ITERATION < "$MARKER_FILE"

[[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && MAX_ITERATIONS=0
[[ ! "$ITERATION" =~ ^[0-9]+$ ]] && ITERATION=1

# Read hook input for completion signals
HOOK_INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

# Check for completion signals
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | jq -r '.message.content | if type == "array" then map(select(.type == "text")) | map(.text) | join("\n") else "" end' 2>/dev/null || echo "")
  if echo "$LAST_OUTPUT" | grep -qiE "all beads complete|beads loop complete"; then
    echo "Beads loop complete!"
    rm -f "$MARKER_FILE"
    exit 0
  fi
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Beads loop: Max iterations ($MAX_ITERATIONS) reached."
  rm -f "$MARKER_FILE"
  exit 0
fi

# Check for ready tasks
if [[ -n "$LABEL_FILTER" ]]; then
  READY_COUNT=$(bd ready -l "$LABEL_FILTER" --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
else
  READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
fi

# All done?
if [[ "$READY_COUNT" == "0" ]]; then
  echo "Beads loop: No ready tasks remaining. All beads complete!"
  rm -f "$MARKER_FILE"
  exit 0
fi

# Increment iteration and continue
NEXT_ITERATION=$((ITERATION + 1))
echo "$LABEL_FILTER:$MAX_ITERATIONS:$NEXT_ITERATION" > "$MARKER_FILE"

PROMPT="Continue executing beads.

Ready Tasks: $READY_COUNT
Label Filter: ${LABEL_FILTER:-"(all)"}
Iteration: $NEXT_ITERATION

Instructions:
1. Run \`bd ready\` to find next task
2. Pick highest priority task
3. Run \`bd show <id>\` for details
4. Run \`bd update <id> --status in_progress\`
5. Implement following the task description
6. Run \`bd close <id> --reason \"Done: <summary>\"\`

When no ready tasks remain, say: \"All beads complete\""

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "Beads loop iteration $NEXT_ITERATION | $READY_COUNT ready" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
