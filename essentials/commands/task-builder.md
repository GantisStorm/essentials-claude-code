---
allowed-tools: Task, TaskOutput, Bash, Read, Write, AskUserQuestion
argument-hint: <plan-file-path OR tasks-file-path>
description: Break down a plan into granular tasks and orchestrate iterative implementation (project)
---

Break down implementation plans into trackable tasks and orchestrate user-driven iterative implementation. Creates a comprehensive tasks.json file, then manages implementation one task at a time with full user control and verification.

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY creates/updates tasks.json.

## Arguments

**Two modes based on file type:**

1. **DECOMPOSE MODE** - Pass a plan file:
   - `<plan-file-path>`: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
   - Agent creates tasks.json, then command orchestrates

2. **RESUME MODE** - Pass a tasks file:
   - `<tasks-file-path>`: Path to existing tasks file (e.g., `.claude/plans/tasks-a3f9e.json`)
   - Command loads tasks.json and orchestrates directly (NO agent)

## Instructions

### Step 1: Parse Arguments and Determine Mode

Parse `$ARGUMENTS` to extract the input file path.

**Mode Detection (based on file extension):**
- If file ends with `.md`: **DECOMPOSE mode** - Create tasks.json via agent, then orchestrate
- If file ends with `.json` or contains `tasks-`: **RESUME mode** - Load tasks.json and orchestrate directly

**Validation:**
- Verify input file exists (use Bash: `ls <file-path>`)
- For DECOMPOSE mode: Verify plan status is "READY FOR IMPLEMENTATION"
- For RESUME mode: Verify JSON structure is valid tasks file

### Step 2A: DECOMPOSE MODE - Create Tasks.json via Agent

**ONLY if mode is DECOMPOSE**, launch `task-builder-default` agent to create tasks.json:

```
Create a comprehensive tasks.json file from the implementation plan.

Plan file: <plan-file-path>

## Instructions

You are ONLY responsible for creating tasks.json. You do NOT orchestrate implementation.

1. PLAN ANALYSIS:
   - Read the plan file completely
   - Extract ALL plan metadata, requirements, constraints
   - Extract ALL implementation details, code snippets, architectural context
   - Build dependency graph of all file changes

2. TASK DECOMPOSITION:
   - Break plan into logical, atomic tasks
   - Strategy: layer-based OR file-based OR feature-based
   - For EACH task, embed COMPLETE details:
     * Full description with architectural context
     * Complete implementation details for each file
     * ALL code snippets from plan (can be hundreds of lines)
     * All requirements (R-IDs) and constraints (C-IDs)
     * Testing strategy and risk mitigations
     * External documentation context

3. CREATE TASKS FILE:
   - Write to: .claude/plans/tasks-{plan-hash5}.json
   - Use same 5-char hash from plan filename
   - Structure: version, plan_reference, tasks array, completion_summary
   - Tasks must be SELF-CONTAINED (file-editors never need to read plan)

4. MULTI-PASS REVISION:
   - Pass 1: Initial draft
   - Pass 2: Structural validation
   - Pass 3: Anti-pattern elimination
   - Pass 4: Self-containment check
   - Pass 5: Consumer simulation
   - Pass 6: Quality scoring (min 40/50)

5. REPORT BACK:
   Report minimal output:
   - Tasks file path
   - Total tasks created
   - Decomposition strategy used
   - Quality score

DO NOT orchestrate implementation. DO NOT spawn file-editors.
The slash command will handle orchestration after you create tasks.json.
```

Use `subagent_type: "task-builder-default"` and `run_in_background: true`.

Wait for agent to complete using TaskOutput with `block: true`.

Parse agent output to get tasks file path (should be `.claude/plans/tasks-{hash5}.json`).

### Step 2B: RESUME MODE - Skip Agent Launch

**If mode is RESUME**, skip the agent entirely. The tasks file already exists.

Set `tasks_file_path` to the provided `<tasks-file-path>` argument.

---

### Step 3: Load Tasks File

**BOTH MODES arrive here** with `tasks_file_path` set.

Read the tasks.json file:

```bash
# Read tasks file
Read <tasks_file_path>
```

Parse the JSON to extract:
- `plan_reference`: Path to the original plan file
- `total_issues`: Total number of tasks
- `issues`: Array of task objects
- `completion_summary`: Current status

Analyze current state:
- Count completed, pending, failed, deferred tasks
- Identify next task to implement (first pending task with all dependencies met)

### Step 4: Report Current Status to User

```
═══════════════════════════════════════════════════════════════
TASK-BASED IMPLEMENTATION: [STARTING | RESUMING]
═══════════════════════════════════════════════════════════════

Tasks File: [tasks_file_path]
Plan Reference: [plan_reference from tasks.json]

Status Summary:
✓ Completed: [X] tasks ([list TSK-IDs])
✗ Failed: [Y] tasks ([list TSK-IDs if any])
⚠ Deferred: [Z] tasks ([list TSK-IDs if any])
○ Pending: [W] tasks

Next Task: TSK-XXX - [title]
Dependencies: [All met / Waiting on TSK-YYY]

Ready to begin iterative implementation.
═══════════════════════════════════════════════════════════════
```

### Step 5: Orchestrator Loop (Command Handles This)

**CRITICAL**: The SLASH COMMAND runs the orchestrator loop, NOT the agent.

For each task (in dependency order):

#### 5.1: Present Task to User

Use AskUserQuestion tool to present the task:

**Question**: What would you like to do with this task?

**Header**: Task TSK-XXX

**Options** (with multiSelect: false):
1. **Implement this task** - Spawn file-editors and implement all changes
2. **Skip this task** - Mark as deferred and move to next
3. **View complete details** - Show full task JSON from tasks file
4. **Pause/Compact** - Save state and exit for context compaction
5. **Abort orchestration** - Exit loop and save current state

**Option Descriptions**:
- Option 1: "Spawns parallel file-editor agents to implement all files in this task. Verifies completion and updates tasks.json."
- Option 2: "Marks this task as deferred and moves to the next available task."
- Option 3: "Displays the complete task specification from tasks.json including all implementation details."
- Option 4: "Saves current progress to tasks.json and exits cleanly. You can resume later with /task-builder <tasks-file>."
- Option 5: "Stops orchestration and saves state. Use this to exit the implementation workflow."

Present task summary before question:
```
═══════════════════════════════════════════════════════════════
TASK: TSK-XXX - [Title]
═══════════════════════════════════════════════════════════════

Priority: [P1|P2|P3|P4]
Layer: [N]
Complexity: [low|medium|high]

Description:
[task.description]

Files to Modify:
- [file1] ([action]): [X] changes planned
- [file2] ([action]): [Y] changes planned

Dependencies: [List or "None - ready to implement"]
Requirements: [R-IDs]
Constraints: [C-IDs]

Progress: [X] / [N] tasks completed ([%]%)
═══════════════════════════════════════════════════════════════
```

#### 5.2: Process User Selection

**If user selects [1] Implement:**

1. Update tasks.json (in memory):
   - Set task status: "in_progress"
   - Set started_at: current timestamp

2. Extract plan file path from task.plan_reference

3. Launch file-editor-default agents IN PARALLEL:

   **CRITICAL**: Launch ALL file-editors in a SINGLE message with multiple Task tool calls.

   For each file in task.files:
   ```
   Execute the implementation plan on your assigned file.

   Plan file: [plan_reference from tasks.json]
   Your assigned file: [file.path]

   **Process**:
   1. Read plan file and validate pre-conditions
   2. Parse your file's section (`[edit]` or `[create]`)
   3. **Reflection Checkpoint** - Verify understanding
   4. Analyze change impact
   5. Apply security checklist
   6. Implement changes (Edit for [edit], Write for [create])
   7. Run regression loop
   8. Self-verify all changes completed

   Report back with:
   1. File path and action type
   2. **CHANGES COMPLETED**: [X] / [Y] (must match TOTAL CHANGES)
   3. Summary of changes
   4. Regression check results
   5. Any issues/warnings
   ```

   Use `subagent_type: "file-editor-default"` and `run_in_background: true`.

   **Send ALL file-editor Task calls in ONE message for parallel execution.**

4. Wait for all file-editors to complete:
   - Use TaskOutput with `block: true` for each spawned agent
   - Collect results:
     * File path
     * CHANGES COMPLETED count
     * Change summary
     * Regression check status
     * Issues encountered

5. Verify ALL changes completed:
   ```
   For each file in task:
   - File: [path]
   - Planned: [N] changes
   - Completed: [M] changes
   - Status: [✓ Complete | ⚠ Incomplete | ✗ Failed]

   Overall: [All complete | Some incomplete | Failed]
   ```

   If ANY file has fewer changes completed than planned:
   - Re-dispatch file-editor for that file with ONLY missed changes
   - Wait for completion
   - Verify again
   - Loop until all files complete

6. Update tasks.json:
   - Write updated tasks.json to disk using Write tool
   - Set task status: "completed"
   - Set completed_at: timestamp
   - Update completion_summary counters

7. Move to next task (return to Step 5.1)

**If user selects [2] Skip:**

1. Update tasks.json:
   - Set task status: "deferred"
   - Add note: "Deferred by user"

2. Write tasks.json to disk

3. Move to next task (return to Step 5.1)

**If user selects [3] View details:**

1. Display relevant section from tasks.json for this task

2. Return to Step 5.1 (re-present the same task)

**If user selects [4] Pause/Compact:**

1. Save current state:
   - Write tasks.json to disk with current progress
   - Ensure current task remains "pending" (not started)

2. Report pause summary:
   ```
   ═══════════════════════════════════════════════════════════════
   WORKFLOW PAUSED FOR CONTEXT COMPACTION
   ═══════════════════════════════════════════════════════════════

   Progress:
   - Tasks Completed: [X] / [N]
   - Changes Completed: [Y] / [Z]
   - Next Task: TSK-XXX (not started)

   State Saved To: [tasks_file_path]

   Next Steps:
   1. Run /compact to compact context
   2. Resume with: /task-builder [tasks_file_path]

   When you resume, the workflow will continue from TSK-XXX.
   ═══════════════════════════════════════════════════════════════
   ```

3. Exit orchestrator loop (go to Step 6)

**If user selects [5] Abort:**

1. Save current state:
   - Write tasks.json to disk

2. Report abort summary:
   ```
   ═══════════════════════════════════════════════════════════════
   ORCHESTRATION ABORTED BY USER
   ═══════════════════════════════════════════════════════════════

   Progress:
   - Tasks Completed: [X] / [N]
   - Changes Completed: [Y] / [Z]

   State Saved To: [tasks_file_path]

   You can resume later with: /task-builder [tasks_file_path]
   ═══════════════════════════════════════════════════════════════
   ```

3. Exit orchestrator loop (go to Step 6)

#### 5.3: Next Task Selection

After completing, skipping, or failing a task:

1. Find next task where:
   - status = "pending"
   - All depends_on_tasks are "completed"
   - Layer ≤ current_layer + 1

2. If next task found:
   - Return to Step 5.1 (present task)

3. If no tasks available but some pending:
   - Report: "Blocked - remaining tasks have unmet dependencies"
   - Go to Step 6 (final report)

4. If all tasks completed or deferred:
   - Go to Step 6 (final report)

### Step 6: Final Report

After orchestrator loop exits (completed, paused, or aborted):

```
═══════════════════════════════════════════════════════════════
TASK-BASED IMPLEMENTATION: [COMPLETE | PAUSED | ABORTED]
═══════════════════════════════════════════════════════════════

Tasks File: [tasks_file_path]
Plan: [plan_reference]

COMPLETION METRICS:
- Total Tasks: [N]
- Completed: [X] ([%]%)
- Failed: [Y]
- Deferred: [Z]
- Pending (blocked): [W]

CHANGE METRICS:
- Total Changes Planned: [N]
- Total Changes Completed: [X] ([%]%)
- Files Modified: [count]
- Files Created: [count]

═══════════════════════════════════════════════════════════════
TASK BREAKDOWN
═══════════════════════════════════════════════════════════════

Completed Tasks:
✓ TSK-001: [title] - [X] changes
✓ TSK-002: [title] - [Y] changes
...

Failed Tasks:
✗ TSK-XXX: [title] - [reason]

Deferred Tasks:
⚠ TSK-YYY: [title]

Blocked Tasks:
○ TSK-ZZZ: [title] - [blocked by TSK-XXX]

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Review changes: git diff
2. Run quality checks (see CLAUDE.md)
3. Address failed/deferred tasks
4. Resume if needed: /task-builder [tasks_file_path]
5. Commit when satisfied

Tasks file saved: [tasks_file_path]
═══════════════════════════════════════════════════════════════
```

## Workflow Diagram

```
/task-builder <file>
    │
    ▼
┌─────────────────────┐
│ Parse arguments     │
│ Determine mode      │
└─────────────────────┘
    │
    ├──[DECOMPOSE]─────────────────┐
    │                              │
    │   ┌──────────────────────────────┐
    │   │ Launch task-builder-default │
    │   │ (create tasks.json ONLY)    │
    │   └──────────────────────────────┘
    │                │
    │                ▼
    │   ┌──────────────────────────────┐
    │   │ Wait for agent completion   │
    │   │ Get tasks file path         │
    │   └──────────────────────────────┘
    │                │
    │                ▼
    ├──[RESUME]────────────────────┐
    │                              │
    ▼                              ▼
┌─────────────────────────────────────┐
│ Load tasks.json                     │
│ Parse current state                 │
│ Identify next task                  │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ORCHESTRATOR LOOP (in command)      │
│                                     │
│  For each task:                     │
│  ├─► Present to user (AskQuestion) │
│  ├─► User chooses action           │
│  ├─► If [1]: Spawn file-editors    │◄── PARALLEL
│  ├─► Wait for editors              │
│  ├─► Verify completion             │
│  ├─► Update tasks.json             │
│  └─► Next task                     │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Final Report        │
└─────────────────────┘
```

## Key Architecture Points

1. **Slash Command Orchestrates**: The command file (task-builder.md) handles ALL orchestration
2. **Agent Only Creates Tasks**: The agent (task-builder-default.md) ONLY creates/updates tasks.json
3. **No Double Orchestration**: Agent does NOT spawn file-editors or run loops
4. **RESUME Mode Skips Agent**: When resuming, command loads tasks.json directly
5. **Parallel File-Editors**: Command spawns all file-editors for a task in ONE message
6. **User Control**: AskUserQuestion after every task presentation
7. **Resumable**: Can pause/compact at any task boundary

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file missing | Report error, stop |
| Plan not READY FOR IMPLEMENTATION | Report error, stop |
| Tasks file missing (RESUME mode) | Report error, suggest running with plan file instead |
| Tasks file corrupted | Report error, suggest regenerating |
| All tasks blocked | Report blockers, ask user to resolve failed tasks |
| User pauses workflow | Save state to tasks.json, provide resume instructions |
| File-editor fails | Mark task as failed, ask user how to proceed |

## Example Usage

```bash
# DECOMPOSE MODE: Create tasks from plan and start implementation
/task-builder .claude/plans/oauth2-authentication-a3f9e-plan.md

# RESUME MODE: Resume from existing tasks file
/task-builder .claude/plans/tasks-a3f9e.json

# After /compact, resume where you left off
/task-builder .claude/plans/tasks-7k2m1.json
```

## When to Use Task Builder vs Direct Editor

**Use Task Builder (`/task-builder`) when:**
- Complex plans with >5 files
- Unclear dependencies between files
- You want incremental, reviewable progress
- You might need to pause and resume
- You want granular control over what gets implemented

**Use Direct Editor (`/editor`) when:**
- Simple plans with <5 files
- All files independent or dependencies clear
- You want batch implementation
- Single execution session expected
