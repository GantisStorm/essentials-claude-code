#!/bin/bash

# Implement Loop Setup Script
# Creates state file for plan implementation loop

set -euo pipefail

PLAN_PATH=""
MAX_ITERATIONS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Implement Loop - Iterative plan implementation

USAGE:
  /implement-loop <plan_path> [--max-iterations N]

ARGUMENTS:
  plan_path              Path to the plan file

OPTIONS:
  --max-iterations <n>   Maximum iterations before stopping (default: unlimited)
  -h, --help             Show this help message

DESCRIPTION:
  Implements a plan iteratively:
  1. Reads the plan file and extracts implementation tasks
  2. Creates todos from the plan
  3. Implements each todo until all complete
  4. Runs exit criteria verification
  5. Loops until exit criteria pass

EXAMPLES:
  /implement-loop .claude/plans/oauth2-auth-3k7f2-plan.md
  /implement-loop .claude/plans/fix-login-bug-9f2a1-plan.md --max-iterations 20

STOPPING:
  - Exit criteria pass
  - Max iterations reached (if set)
  - User runs /cancel-implement
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
      if [[ -z "$PLAN_PATH" ]]; then
        PLAN_PATH="$1"
      else
        echo "Error: Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Validate plan path
if [[ -z "$PLAN_PATH" ]]; then
  echo "Error: No plan path provided" >&2
  echo "Usage: /implement-loop <plan_path> [--max-iterations N]" >&2
  exit 1
fi

# Check if plan file exists
if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found: $PLAN_PATH" >&2
  if [[ -d ".claude/plans" ]]; then
    echo "Available plans:" >&2
    ls -1 .claude/plans/*.md 2>/dev/null || echo "  (none)" >&2
  fi
  exit 1
fi

# Create state file
mkdir -p .claude

cat > .claude/implement-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
plan_path: "$PLAN_PATH"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

## Implementation Loop State

Plan: $PLAN_PATH
Started: $(date)
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

### Instructions

1. Read plan, create tasks with TaskCreate
2. Set dependencies with TaskUpdate
3. Implement each task following the plan
4. Run exit criteria verification
5. Loop until exit criteria pass
EOF

# Output setup info
cat <<EOF
IMPLEMENT_LOOP_ACTIVE=true
PLAN_PATH=$PLAN_PATH
MAX_ITERATIONS=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

Implement loop activated.

Plan: $PLAN_PATH
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

To cancel: /cancel-implement

PLAN_TO_IMPLEMENT=$PLAN_PATH
EOF
