---
allowed-tools: Task, TaskOutput, Read, AskUserQuestion
argument-hint: <plan-file-path> "<user instructions>"
description: Build on or refine existing implementation plans using multi-pass revision with git-style tracking (project)
---

Build on or refine existing implementation plans created by planner. The plan-builder follows user instructions precisely using iterative multi-pass revision, asks clarifying questions when needed, applies changes through structured validation passes (including reflection checkpoints), and maintains a comprehensive git-style revision history showing all changes.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the updated plan FILE directly.

**Note**: The plan-builder may ask clarification questions via AskUserQuestion if instructions are ambiguous or conflicts are detected. Changes are applied through a meta builder pattern with reflection checkpoints and quality validation.

## Arguments

- **plan-file-path**: Path to plan file in `.claude/plans/` (e.g., `.claude/plans/oauth2-authentication-a3f9e-plan.md`)
- **user instructions**: Quoted string describing what to change/optimize (e.g., "Add error handling details to auth handler")

## Instructions

### Step 1: Parse Arguments

Parse `$ARGUMENTS` to extract:
1. Plan file path (first argument)
2. User instructions (all remaining arguments, may be quoted or unquoted)

**Validation:**
- Verify plan file exists (use Read tool to check)
- Ensure user instructions are clear and not empty
- If arguments malformed, report error and usage example

### Step 2: Launch Plan Builder in Background

Launch the `plan-builder-default` agent **in the background** using the Task tool with `run_in_background: true`:

```
Apply the following user-requested changes to the implementation plan:

Plan file: <plan-file-path>

User instructions:
<user instructions exactly as provided>

## Your Task

1. Read the plan file completely
2. Understand the user's requested changes
3. Apply changes precisely as requested
4. Update all affected sections to maintain consistency
5. Validate plan integrity after changes
6. Append git-style revision entry to Revision History
7. Write updated plan back to file

Follow the user's instructions exactly. Make only the changes they requested, plus any cascading updates needed to maintain plan consistency.
```

Use `subagent_type: "plan-builder-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the plan-builder agent to complete. The plan-builder will:
1. Read and analyze the current plan
2. Apply user-requested changes precisely
3. Update all affected sections for consistency
4. Validate plan integrity
5. Add git-style revision entry showing changes
6. Write updated plan to file
7. Return summary of changes made

### Step 4: Report Summary

After the agent completes, provide a minimal summary:

```
## Plan Builder Summary

**Plan**: .claude/plans/{task-slug}-{hash5}-plan.md
**Revision**: [N] (was [N-1])

### Changes Applied

**Request**: [user instructions]

**Modifications**:
- Sections updated: [count]
- Lines added: [count]
- Lines removed: [count]
- Requirements affected: [count]
- Dependencies affected: [count]

**Quality Score**: [XX]/50 (was [YY]/50, [+/-N])

### Affected Sections

- [Section 1]: [brief change description]
- [Section 2]: [brief change description]

### Validation

- [✓] Plan structure intact
- [✓] Dependencies consistent
- [✓] Requirements traceable
- [✓] Quality maintained

### Next Steps

- Review updated plan and revision history in `.claude/plans/{plan-file}`
- Make additional refinements: `/plan-builder <plan-file> "<instructions>"`
- Proceed with implementation: `/editor` or `/issue-builder`
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
│                                                  │
│  PHASE 1: Plan Analysis                          │
│    - Read plan file                              │
│    - Understand user instructions                │
│    - Check for ambiguities                       │
│                                                  │
│  PHASE 2: Impact Analysis                        │
│    - Identify affected sections                  │
│    - Validate change feasibility                 │
│                                                  │
│  PHASE 2.5: Reflection Checkpoint (ReAct)        │◄── Meta builder pattern
│    - Verify impact completeness                  │
│    - Confirm no breakages                        │
│    - Validate user intent alignment              │
│                                                  │
│  PHASE 3: Apply Changes                          │
│    - Make requested changes                      │
│    - Apply cascading updates                     │
│                                                  │
│  PHASE 4: Meta Builder Validation                │
│    - Pass 1: Structural Integrity                │
│    - Pass 2: Consistency Check                   │
│    - Pass 3: Quality Re-assessment               │
│    - Pass 4: Anti-Pattern Scan                   │
│                                                  │
│  PHASE 5: Revision History                       │
│    - Create git-style diffs                      │
│    - Document impact summary                     │
│                                                  │
│  PHASE 6-7: Write & Output                       │
│    - Write updated plan                          │
│    - Provide structured summary                  │
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

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file missing | Report error with correct path format |
| User instructions empty | Report error, show usage example |
| Plan malformed | Report structural issues found |
| Changes conflict with plan | Report conflict, suggest resolution |
| Quality degradation | Warn user, suggest improvements |

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
- `/issue-builder` - Iterative implementation
