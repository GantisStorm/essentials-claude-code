#!/bin/bash

# Beads Loop Setup Script
# Creates state file for iterative beads execution

set -euo pipefail

# Parse arguments
LABEL_FILTER=""
MAX_ITERATIONS=0
STEP_MODE=true  # Default to step mode for human control

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Beads Loop - Iterative beads execution until all tasks complete

USAGE:
  /beads-loop [OPTIONS]

OPTIONS:
  --step                Step mode (DEFAULT) - pause after each bead for human control
  --auto                Auto mode - continue without pausing
  --label <label>       Filter beads by label (e.g., openspec:my-feature)
  --max-iterations <n>  Maximum iterations before auto-stop (default: unlimited)
  -h, --help            Show this help message

DESCRIPTION:
  Starts an execution loop that:
  1. Runs `bd ready` to find tasks with no blockers
  2. Picks the highest priority ready task
  3. Implements the task using its self-contained description
  4. Runs `bd close` when complete
  5. Pauses for human decision (step mode) or auto-continues (auto mode)
  6. Repeats until no ready tasks remain

  Step mode (default) pauses after each bead, letting you:
  - Continue to the next bead
  - Stop and start a fresh session (beads persist)
  - Skip a bead if needed

  This prevents context compaction issues on large task sets.

  The loop uses the beads database as source of truth.
  On context compaction, `bd show <id>` provides full context recovery.

EXAMPLES:
  /beads-loop                                      # Step mode (pauses after each bead)
  /beads-loop --auto                               # Auto mode (continuous)
  /beads-loop --label openspec:refactor-bullmq    # With label filter
  /beads-loop --auto --max-iterations 20          # Auto with limit

STOPPING:
  - No ready tasks remaining (`bd ready` returns empty)
  - Max iterations reached (if set)
  - User says "stop" at pause prompt (step mode)
  - User runs /cancel-beads

STEP MODE CONTROLS:
  After each bead completes:
  - Say "continue" to proceed to next bead
  - Say "stop" to end the loop
  - Start a fresh session anytime - beads persist across sessions

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/beads-loop.local.md

  # View ready tasks:
  bd ready

  # View full state:
  cat .claude/beads-loop.local.md
HELP_EOF
      exit 0
      ;;
    --step)
      STEP_MODE=true
      shift
      ;;
    --auto)
      STEP_MODE=false
      shift
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
      echo "Error: Unexpected argument: $1" >&2
      echo "Usage: /beads-loop [--label <label>] [--max-iterations N]" >&2
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
  echo "" >&2
  echo "Or:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash" >&2
  exit 1
fi

# Check if beads is initialized
if ! bd ready &> /dev/null; then
  echo "Error: Beads not initialized in this project" >&2
  echo "" >&2
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
  echo ""
  if [[ -n "$LABEL_FILTER" ]]; then
    echo "Checked: bd ready -l $LABEL_FILTER"
    echo ""
    echo "Try without label filter or check if tasks exist:"
    echo "  bd list -l $LABEL_FILTER"
  else
    echo "Checked: bd ready"
    echo ""
    echo "Create some tasks first:"
    echo "  bd create \"Task title\" -t task -p 2 -d \"Description\""
    echo ""
    echo "Or import from a spec:"
    echo "  /beads-creator openspec/changes/<name>/"
  fi
  exit 1
fi

# Create state file
mkdir -p .claude

cat > .claude/beads-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
label_filter: "$LABEL_FILTER"
step_mode: $STEP_MODE
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
setup_timestamp: $(date +%s)
owner_transcript: ""
current_task: ""
---

## Beads Loop State

Label Filter: ${LABEL_FILTER:-"(all)"}
Mode: $(if [[ "$STEP_MODE" == "true" ]]; then echo "Step (pause after each bead)"; else echo "Auto (continuous)"; fi)
Started: $(date)

### Progress
- Iteration: 1
- Ready Tasks: $READY_COUNT
- Current Task: (picking first task)
- Status: Starting

### Instructions

On each iteration:
1. Run \`bd ready\` to find tasks with no blockers
2. Pick highest priority ready task
3. Run \`bd show <id>\` to get full task details
4. Mark as in_progress: \`bd update <id> --status in_progress\`
5. Implement following the task description
6. When done: \`bd close <id> --reason "Completed: <summary>"\`
$(if [[ "$STEP_MODE" == "true" ]]; then echo "7. Wait for human to say 'continue' or 'stop'"; else echo "7. Auto-continue to next task"; fi)
8. Repeat until no ready tasks remain

The loop will $(if [[ "$STEP_MODE" == "true" ]]; then echo "pause after each bead for your decision"; else echo "continue automatically"; fi).
EOF

# Output setup message
cat <<EOF
BEADS_LOOP_ACTIVE=true
LABEL_FILTER=$LABEL_FILTER
MAX_ITERATIONS=$MAX_ITERATIONS
STEP_MODE=$STEP_MODE
READY_TASKS=$READY_COUNT
ITERATION=1

Beads loop activated.

Ready Tasks: $READY_COUNT
Label Filter: ${LABEL_FILTER:-"(all)"}
Mode: $(if [[ "$STEP_MODE" == "true" ]]; then echo "STEP (pause after each bead)"; else echo "AUTO (continuous)"; fi)
Max Iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)

$(if [[ "$STEP_MODE" == "true" ]]; then
cat <<'STEP_MSG'
Step mode enabled - pauses after each bead for your decision.
After each bead completes:
  - Say "continue" to proceed to next bead
  - Say "stop" to end the loop
  - Start a fresh session anytime - beads persist
STEP_MSG
else
echo "The stop hook will keep you implementing until all beads are complete."
fi)
To cancel: /cancel-beads
EOF
