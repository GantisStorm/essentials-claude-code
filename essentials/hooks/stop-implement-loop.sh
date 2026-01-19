#!/bin/bash

# Implement Loop Stop Hook
# Continues loop until exit criteria pass

IMPLEMENT_STATE=".claude/implement-loop.local.md"

# Exit early if no active loop
if [[ ! -f "$IMPLEMENT_STATE" ]]; then
  exit 0
fi

# Read hook input
HOOK_INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

# Check for completion signals in last output
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | jq -r '.message.content | if type == "array" then map(select(.type == "text")) | map(.text) | join("\n") else "" end' 2>/dev/null || echo "")
  if echo "$LAST_OUTPUT" | grep -qiE "exit criteria.*passed|implementation complete|all todos.*completed|verification.*passed"; then
    echo "Implement loop: Exit criteria passed!"
    rm -f "$IMPLEMENT_STATE"
    exit 0
  fi
fi

# Parse frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$IMPLEMENT_STATE" 2>/dev/null || echo "")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "0")
PLAN_PATH=$(echo "$FRONTMATTER" | grep '^plan_path:' | sed 's/plan_path: *//' | sed 's/^"\(.*\)"$/\1/' || echo "")

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

# Continue loop
NEXT_ITERATION=$((ITERATION + 1))

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
EOF

PROMPT="Continue implementing the plan.

Plan: $PLAN_PATH
Iteration: $NEXT_ITERATION

Instructions:
1. Check your todo list
2. Find next pending todo
3. Implement the change
4. Mark todo completed
5. Run exit criteria when all todos done

When exit criteria pass, say: \"Exit criteria passed\""

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "Implement loop iteration $NEXT_ITERATION | $PLAN_PATH" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
