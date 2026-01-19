#!/bin/bash

# Tasks Loop Setup Script
# Validates prd.json and outputs info for the loop

set -euo pipefail

PRD_PATH=""
MAX_ITERATIONS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Tasks Loop - Iterative prd.json execution

USAGE:
  /tasks-loop <prd_path> [--max-iterations N]

ARGUMENTS:
  prd_path              Path to the prd.json file

OPTIONS:
  --max-iterations <n>   Maximum iterations before stopping (default: unlimited)
  -h, --help             Show this help message

DESCRIPTION:
  Executes prd.json tasks iteratively:
  1. Reads prd.json and finds pending tasks
  2. Picks the highest priority task with no blockers
  3. Implements the task using its self-contained description
  4. Updates passes: true when complete
  5. Repeats until no pending tasks remain

EXAMPLES:
  /tasks-loop ./prd.json
  /tasks-loop ./tasks/my-feature.json
  /tasks-loop ./prd.json --max-iterations 5

STOPPING:
  - No pending tasks remaining
  - Max iterations reached (if set)
  - User runs /cancel-tasks
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      if [[ -z "$PRD_PATH" ]]; then
        PRD_PATH="$1"
      else
        echo "Error: Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Default to ./prd.json if not specified
if [[ -z "$PRD_PATH" ]]; then
  PRD_PATH="./prd.json"
fi

# Check if file exists
if [[ ! -f "$PRD_PATH" ]]; then
  echo "Error: File not found: $PRD_PATH" >&2
  echo "" >&2
  echo "Create with: /tasks-creator <plan-path>" >&2
  if [[ -d "./tasks" ]]; then
    echo "" >&2
    echo "Available task files:" >&2
    ls -1 ./tasks/*.json 2>/dev/null || echo "  (none)" >&2
  fi
  exit 1
fi

# Validate JSON
if ! jq empty "$PRD_PATH" 2>/dev/null; then
  echo "Error: Invalid JSON: $PRD_PATH" >&2
  exit 1
fi

# Check for userStories field (RalphTUI schema)
if ! jq -e '.userStories' "$PRD_PATH" &>/dev/null; then
  echo "Error: Invalid prd.json schema - missing 'userStories' field" >&2
  echo "Expected RalphTUI format with 'userStories' array" >&2
  exit 1
fi

# Count pending tasks (passes: false, no unresolved dependencies)
TOTAL_TASKS=$(jq '.userStories | length' "$PRD_PATH")
COMPLETED_TASKS=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH")
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
' "$PRD_PATH")

if [[ "$READY_TASKS" == "0" ]]; then
  if [[ "$PENDING_TASKS" == "0" ]]; then
    echo "All tasks already complete in: $PRD_PATH"
  else
    echo "No ready tasks found (all blocked by dependencies)"
    echo "Pending: $PENDING_TASKS, but all have unresolved dependencies"
  fi
  exit 1
fi

# Create marker file for stop hook (stores path:max_iterations:current_iteration)
mkdir -p .claude
echo "$PRD_PATH:$MAX_ITERATIONS:1" > .claude/tasks-loop-active

# Output setup info
cat <<EOF
TASKS_LOOP_ACTIVE=true
PRD_PATH=$PRD_PATH
TOTAL_TASKS=$TOTAL_TASKS
PENDING_TASKS=$PENDING_TASKS
READY_TASKS=$READY_TASKS
MAX_ITERATIONS=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

Tasks loop activated.

File: $PRD_PATH
Total Tasks: $TOTAL_TASKS
Pending: $PENDING_TASKS
Ready (no blockers): $READY_TASKS
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

To cancel: /cancel-tasks

PRD_TO_IMPLEMENT=$PRD_PATH
EOF
