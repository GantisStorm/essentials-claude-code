---
allowed-tools: Task, TaskOutput, Bash, Read
argument-hint: <plan-file-path> "<user instructions>"
description: Apply user-requested refinements to implementation plans with git-style revision tracking (project)
---

Apply user-requested refinements to existing implementation plans created by planner. The slash command orchestrates the process while the plan-builder-default agent applies changes precisely using multi-pass revision and maintains a comprehensive git-style revision history.

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY applies changes to the plan.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the updated plan FILE directly.

## Arguments

- **plan-file-path**: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
- **user instructions**: Quoted string describing what to change/optimize (e.g., "Add error handling details to auth handler")

## Instructions

### Step 1: Parse and Validate Arguments

Parse `$ARGUMENTS` to extract:
1. Plan file path (first argument)
2. User instructions (all remaining arguments, may be quoted or unquoted)

**Validation:**
```bash
# Verify plan file exists
ls <plan-file-path>
```

- If plan file missing: Report error and stop
- If user instructions empty: Report error with usage example
- If arguments malformed: Report error and stop

### Step 2: Launch Plan Builder Agent

**CRITICAL**: The SLASH COMMAND orchestrates, the agent ONLY applies changes.

Launch the `plan-builder-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Apply user-requested changes to the implementation plan.

Plan file: <plan-file-path>

User instructions:
<user instructions exactly as provided>

## Your Task

You are ONLY responsible for applying changes to the plan. You do NOT orchestrate or interact with the user.

1. PLAN ANALYSIS:
   - Read the plan file completely
   - Parse plan structure and metadata
   - Understand user's requested changes

2. IMPACT ANALYSIS:
   - Identify affected sections
   - Validate change feasibility
   - Determine cascading updates needed

3. REFLECTION CHECKPOINT:
   - Verify impact completeness
   - Confirm no dependency breakages
   - Validate alignment with user intent

4. APPLY CHANGES:
   - Make requested changes precisely
   - Apply cascading updates for consistency
   - Update metadata (increment revision)

5. META BUILDER VALIDATION:
   - Pass 1: Structural integrity
   - Pass 2: Consistency check
   - Pass 3: Quality re-assessment (if needed)
   - Pass 4: Anti-pattern scan

6. REVISION HISTORY:
   - Create git-style diffs showing all changes
   - Document impact summary
   - Add validation checkmarks

7. WRITE & REPORT:
   - Write updated plan to file
   - Report structured summary back to command

Follow user instructions precisely. If instructions are ambiguous, make best judgment and document assumptions in revision notes.

DO NOT use AskUserQuestion. DO NOT orchestrate. The slash command handles all user interaction.
```

Use `subagent_type: "plan-builder-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the plan-builder agent to complete.

Collect agent output:
- Plan file path
- Revision number (before/after)
- Sections modified
- Lines added/removed
- Quality score change
- Validation results
- Any warnings or issues

### Step 4: Report Summary

After the agent completes, provide a minimal summary:

```
═══════════════════════════════════════════════════════════════
PLAN BUILDER: CHANGES APPLIED
═══════════════════════════════════════════════════════════════

Plan: .claude/plans/{task-slug}-{hash5}-plan.md
Revision: [N] (was [N-1])

USER REQUEST:
[user instructions]

MODIFICATIONS:
- Sections updated: [count]
- Lines added: [count]
- Lines removed: [count]
- Requirements affected: [count]
- Dependencies affected: [count]

QUALITY SCORE: [XX]/50 (was [YY]/50, [+/-N])

AFFECTED SECTIONS:
- [Section 1]: [brief change description]
- [Section 2]: [brief change description]
...

VALIDATION:
- [✓] Plan structure intact
- [✓] Dependencies consistent
- [✓] Requirements traceable
- [✓] Quality maintained

REVISION HISTORY:
Git-style diffs showing all changes have been added to the plan file.

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Review updated plan: .claude/plans/{plan-file}
2. Check revision history at end of file for detailed change tracking
3. Make additional refinements: /plan-builder <plan-file> "<instructions>"
4. Proceed with implementation: /editor or /task-builder
═══════════════════════════════════════════════════════════════
```

## Workflow Diagram

```
/plan-builder <plan-file> "<instructions>"
    │
    ▼
┌─────────────────────┐
│ Parse arguments     │
│ Validate plan file  │
└─────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch plan-builder-default                      │◄── run_in_background: true
│ (apply changes ONLY)                             │
│                                                  │
│  PHASE 1: Plan Analysis                          │
│  PHASE 2: Impact Analysis                        │
│  PHASE 2.5: Reflection Checkpoint (ReAct)        │
│  PHASE 3: Apply Changes                          │
│  PHASE 4: Meta Builder Validation (4 passes)     │
│  PHASE 5: Revision History (git-style diffs)     │
│  PHASE 6-7: Write & Output                       │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for completion
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report summary      │◄── Minimal output
└─────────────────────┘
```

## Key Architecture Points

1. **Slash Command Orchestrates**: The command file (plan-builder.md) handles minimal orchestration
2. **Agent Only Applies Changes**: The agent (plan-builder-default.md) ONLY applies changes to plan
3. **No User Interaction in Agent**: Agent never uses AskUserQuestion
4. **Single-Pass Execution**: No loops, just launch agent and report
5. **Git-Style Revision Tracking**: All changes documented with diffs
6. **Multi-Pass Validation**: 4 validation passes ensure plan integrity

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file missing | Report error with correct path format, stop |
| User instructions empty | Report error, show usage example, stop |
| Plan malformed | Report structural issues found by agent |
| Changes conflict with plan | Agent documents conflict in revision notes |
| Quality degradation | Agent warns in output, suggests improvements |
| Agent fails | Report error, suggest checking plan file |

## Example Usage

```bash
# Add error handling details
/plan-builder .claude/plans/oauth2-authentication-a3f9e-plan.md "Add error handling details to the auth handler section"

# Update implementation order
/plan-builder .claude/plans/oauth2-authentication-a3f9e-plan.md "Change implementation order to do database migrations first"

# Add security considerations
/plan-builder .claude/plans/payment-refactor-7k2m1-plan.md "Add security considerations for PCI compliance to payment processing section"

# Reorganize sections
/plan-builder .claude/plans/api-redesign-3x9f2-plan.md "Move testing strategy before implementation plan section"

# Update requirements
/plan-builder .claude/plans/user-auth-5m3k1-plan.md "Add requirement for password strength validation with specific rules"

# Enhance specificity
/plan-builder .claude/plans/cache-layer-2h8j4-plan.md "Add exact Redis configuration parameters to the cache setup section"
```

## When to Use Plan Builder

**Use `/plan-builder` when:**
- Plan needs additional details or clarifications
- Requirements changed after initial planning
- Implementation approach needs adjustment
- Want to add/remove constraints
- Need to reorganize sections for clarity
- Quality could be improved in specific areas
- Dependencies need adjustment
- Want to track iterative plan refinements

**Don't use `/plan-builder` when:**
- Plan is fundamentally wrong (create new plan with `/planner`)
- Major architectural change needed (create new plan)
- Just want to review the plan (open file directly)

## Revision History Tracking

The plan-builder maintains a complete audit trail:

- **Git-style diffs**: Shows exactly what was added (+) and removed (-)
- **Context lines**: Includes surrounding unchanged lines for clarity
- **Impact summary**: Counts lines changed, sections affected, quality score changes
- **Validation status**: Confirms plan integrity maintained
- **User attribution**: Records what user requested for each revision

This makes plan evolution transparent and reviewable.

## Integration with Other Commands

Plan Builder works with plans created by:
- `/planner` - Implementation plans
- `/bug-scout` - Bug fix plans
- `/code-quality` - Quality improvement plans
- `/code-quality-serena` - LSP-based quality improvement plans

After building on a plan, proceed with:
- `/plan-builder` - Additional refinements (can be used multiple times)
- `/editor` - Batch implementation
- `/task-builder` - Iterative implementation
