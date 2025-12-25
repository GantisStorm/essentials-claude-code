---
allowed-tools: Task, TaskOutput, Read, AskUserQuestion
argument-hint: <plan-file-path> "<user instructions>"
description: Apply user-requested optimizations to an implementation plan with git-style revision tracking (project)
---

Apply user-requested changes and optimizations to an existing implementation plan. The optimizer follows user instructions precisely, asks clarifying questions when needed, updates the plan file, and maintains a comprehensive git-style revision history showing all changes.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the updated plan FILE directly.

**Note**: The optimizer may ask clarification questions via AskUserQuestion if instructions are ambiguous or conflicts are detected.

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

### Step 2: Launch Plan Optimizer in Background

Launch the `plan-optimizer-default` agent **in the background** using the Task tool with `run_in_background: true`:

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

Use `subagent_type: "plan-optimizer-default"` when invoking the Task tool.

### Step 3: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the plan-optimizer agent to complete. The optimizer will:
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
## Plan Optimizer Summary

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
- Make additional optimizations: `/plan-optimizer <plan-file> "<instructions>"`
- Proceed with implementation: `/editor` or `/issue-builder`
```

## Workflow Diagram

```
/plan-optimizer <plan-file> "<instructions>"
    │
    ▼
┌─────────────────────┐
│ Parse arguments     │
│ Validate plan file  │
└─────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Launch plan-optimizer-default           │◄── run_in_background: true
│                                         │
│  1. Read plan file                      │
│  2. Analyze user instructions           │
│  3. Apply changes precisely             │
│  4. Update cascading sections           │
│  5. Validate integrity                  │
│  6. Add git-style revision entry        │
│  7. Write updated plan                  │
└─────────────────────────────────────────┘
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
/plan-optimizer .claude/plans/oauth2-authentication-a3f9e-plan.md "Add error handling details to the auth handler section"

# Update implementation order
/plan-optimizer .claude/plans/oauth2-authentication-a3f9e-plan.md "Change implementation order to do database migrations first"

# Add security considerations
/plan-optimizer .claude/plans/payment-refactor-7k2m1-plan.md "Add security considerations for PCI compliance to payment processing section"

# Reorganize sections
/plan-optimizer .claude/plans/api-redesign-3x9f2-plan.md "Move testing strategy before implementation plan section"

# Update requirements
/plan-optimizer .claude/plans/user-auth-5m3k1-plan.md "Add requirement for password strength validation with specific rules"

# Enhance specificity
/plan-optimizer .claude/plans/cache-layer-2h8j4-plan.md "Add exact Redis configuration parameters to the cache setup section"
```

## When to Use Plan Optimizer

**Use `/plan-optimizer` when:**
- Plan needs additional details or clarifications
- Requirements changed after initial planning
- Implementation approach needs adjustment
- Want to add/remove constraints
- Need to reorganize sections for clarity
- Quality could be improved in specific areas
- Dependencies need adjustment
- Want to track iterative plan refinements

**Don't use `/plan-optimizer` when:**
- Plan is fundamentally wrong (create new plan with `/planner`)
- Major architectural change needed (create new plan)
- Just want to review the plan (open file directly)

## Revision History Tracking

The plan-optimizer maintains a complete audit trail:

- **Git-style diffs**: Shows exactly what was added (+) and removed (-)
- **Context lines**: Includes surrounding unchanged lines for clarity
- **Impact summary**: Counts lines changed, sections affected, quality score changes
- **Validation status**: Confirms plan integrity maintained
- **User attribution**: Records what user requested for each revision

This makes plan evolution transparent and reviewable.

## Integration with Other Commands

Plan Optimizer works with plans created by:
- `/planner` - Implementation plans
- `/bug-scout` - Bug fix plans
- `/code-quality` - Quality improvement plans
- `/code-quality-serena` - LSP-based quality improvement plans

After optimization, proceed with:
- `/plan-optimizer` - Additional refinements (can be used multiple times)
- `/editor` - Batch implementation
- `/issue-builder` - Iterative implementation
