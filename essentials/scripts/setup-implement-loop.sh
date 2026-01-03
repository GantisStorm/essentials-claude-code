#!/bin/bash

# Implement Loop Setup Script
# Creates state file for plan implementation loop

set -euo pipefail

# Parse arguments
PLAN_PATH=""
MAX_ITERATIONS=0

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Implement Loop - Iterative plan implementation with todo tracking

USAGE:
  /implement-loop <plan_path> [OPTIONS]

ARGUMENTS:
  plan_path    Path to the plan file (e.g., .claude/plans/feature-abc123-plan.md)

OPTIONS:
  --max-iterations <n>    Maximum iterations before auto-stop (default: unlimited)
  -h, --help              Show this help message

DESCRIPTION:
  Starts an implementation loop that:
  1. Reads the plan file and extracts implementation tasks
  2. Creates a todo list from the plan's file sections
  3. Iteratively implements each todo until all are complete
  4. Uses the plan as reference on each iteration

  The loop uses Claude's built-in TodoWrite tool for progress tracking.
  On context compaction, the plan file provides full context recovery.

EXAMPLES:
  /implement-loop .claude/plans/oauth2-auth-3k7f2-plan.md
  /implement-loop .claude/plans/fix-login-bug-9f2a1-plan.md --max-iterations 20

STOPPING:
  - All todos marked as 'completed'
  - Max iterations reached (if set)
  - User runs /cancel-implement

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/implement-loop.local.md

  # View full state:
  cat .claude/implement-loop.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer, got: $2" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      # First positional argument is plan path
      if [[ -z "$PLAN_PATH" ]]; then
        PLAN_PATH="$1"
      else
        echo "Error: Unexpected argument: $1" >&2
        echo "Usage: /implement-loop <plan_path> [--max-iterations N]" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Validate plan path
if [[ -z "$PLAN_PATH" ]]; then
  echo "Error: No plan path provided" >&2
  echo "" >&2
  echo "Usage: /implement-loop <plan_path> [--max-iterations N]" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  /implement-loop .claude/plans/oauth2-auth-3k7f2-plan.md" >&2
  echo "  /implement-loop .claude/plans/fix-bug-a1b2c-plan.md --max-iterations 30" >&2
  exit 1
fi

# Check if plan file exists
if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found: $PLAN_PATH" >&2
  echo "" >&2
  echo "Available plans in .claude/plans/:" >&2
  if [[ -d ".claude/plans" ]]; then
    ls -1 .claude/plans/*.md 2>/dev/null || echo "  (no plan files found)"
  else
    echo "  (plans directory does not exist)"
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
todos_created: false
---

## Implementation Loop State

Plan: $PLAN_PATH
Started: $(date)

### Progress
- Iteration: 1
- Todos Created: No (pending first iteration)
- Status: Starting

### Instructions

On each iteration:
1. If todos not created: Read plan, create todos with TodoWrite
2. Find next pending todo, mark as in_progress
3. Implement the change following the plan
4. Mark todo as completed when done
5. Repeat until all todos are completed

The loop will continue until ALL todos are marked 'completed'.
EOF

# Output setup message
cat <<EOF
IMPLEMENT_LOOP_ACTIVE=true
PLAN_PATH=$PLAN_PATH
MAX_ITERATIONS=$MAX_ITERATIONS
ITERATION=1

Implement loop activated.

Plan File: $PLAN_PATH
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

The stop hook will keep you implementing until all todos are complete.
To cancel: /cancel-implement
EOF

# Output the plan path for the command to read
echo ""
echo "PLAN_TO_IMPLEMENT=$PLAN_PATH"
