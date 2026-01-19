#!/bin/bash

# Beads Loop Setup Script
# Validates beads setup and outputs info for the loop

set -euo pipefail

LABEL_FILTER=""
MAX_ITERATIONS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Beads Loop - Iterative beads execution

USAGE:
  /beads-loop [OPTIONS]

OPTIONS:
  --label <label>        Filter beads by label (e.g., plan:my-feature)
  --max-iterations <n>   Maximum iterations before stopping (default: unlimited)
  -h, --help             Show this help message

DESCRIPTION:
  Executes beads iteratively:
  1. Runs `bd ready` to find tasks with no blockers
  2. Picks the highest priority ready task
  3. Implements the task using its self-contained description
  4. Runs `bd close` when complete
  5. Repeats until no ready tasks remain

EXAMPLES:
  /beads-loop
  /beads-loop --label plan:add-auth
  /beads-loop --max-iterations 5

STOPPING:
  - No ready tasks remaining (`bd ready` returns empty)
  - Max iterations reached (if set)
  - User runs /cancel-beads
HELP_EOF
      exit 0
      ;;
    --label|-l)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --label requires a label argument" >&2
        exit 1
      fi
      LABEL_FILTER="$2"
      shift 2
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
      echo "Error: Unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

# Check if bd is installed
if ! command -v bd &> /dev/null; then
  echo "Error: bd CLI not found" >&2
  echo "" >&2
  echo "Install beads:" >&2
  echo "  brew tap steveyegge/beads && brew install bd" >&2
  exit 1
fi

# Check if beads is initialized
if ! bd ready &> /dev/null; then
  echo "Error: Beads not initialized in this project" >&2
  echo "Run: bd init" >&2
  exit 1
fi

# Check if there are ready tasks
if [[ -n "$LABEL_FILTER" ]]; then
  READY_COUNT=$(bd ready -l "$LABEL_FILTER" --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
else
  READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
fi

if [[ "$READY_COUNT" == "0" ]]; then
  echo "No ready tasks found."
  if [[ -n "$LABEL_FILTER" ]]; then
    echo "Checked: bd ready -l $LABEL_FILTER"
    echo "Try without label filter or check: bd list -l $LABEL_FILTER"
  else
    echo "Create tasks with: /beads-creator <plan>"
  fi
  exit 1
fi

# Create marker file for stop hook (stores label:max_iterations:current_iteration)
mkdir -p .claude
echo "$LABEL_FILTER:$MAX_ITERATIONS:1" > .claude/beads-loop-active

# Output setup info
cat <<EOF
BEADS_LOOP_ACTIVE=true
LABEL_FILTER=$LABEL_FILTER
READY_TASKS=$READY_COUNT
MAX_ITERATIONS=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

Beads loop activated.

Ready Tasks: $READY_COUNT
Label Filter: ${LABEL_FILTER:-"(all)"}
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

To cancel: /cancel-beads
EOF
