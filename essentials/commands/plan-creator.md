---
allowed-tools: Task, TaskOutput
argument-hint: <task-description>
description: Create a comprehensive architectural plan for any task - detailed enough to feed directly into /implement-loop or OpenSpec
model: opus
context: fork
---

# Architectural Plan Creator

Create a comprehensive **architectural plan** for any task. For large changes that require design decisions, architectural planning with full context produces dramatically better results.

**IMPORTANT**: Keep orchestrator output minimal - summarize the plan location and next steps. The detailed content is in the plan FILE, which the user should review directly.

## Why Architectural Planning?

Architectural planning with full context produces dramatically better results:
- **Bird's eye view** - Understand the full codebase before planning
- **Complete information** - Read all relevant files, not just a few lines
- **Separated phases** - Discovery first, then planning with full context
- **Mapped relationships** - Detect all dependencies between classes

When you understand the entire codebase structure before planning, you can specify exactly HOW to implement, not just WHAT to implement.

## What Good Architectural Plans Include

1. **Clear Outcome Specification**
   - What the final product should do after changes
   - Success criteria and expected behavior
   - Edge cases to handle

2. **Architectural Specification**
   - How new code should be structured
   - Which parts of the codebase are affected
   - What each component should do exactly
   - Dependencies and relationships

3. **Implementation Steps**
   - Ordered list of changes to make
   - Clear, verifiable sub-tasks
   - Dependencies between steps

## Arguments

Takes **any input** describing the task:
- Feature requests: `"Add OAuth2 authentication"`
- Bug descriptions: `"Fix login timeout issue"`
- Refactoring: `"Refactor auth module to use dependency injection"`
- Anything else that needs architectural planning

## Instructions

### Step 1: Process Input

Parse `$ARGUMENTS` as the task description.

Grammar and spell check the description before passing to agent.

### Step 2: Launch Architectural Planner Agent

Launch `plan-creator-default` in background:

```
Create a comprehensive architectural plan with maximum depth and verbosity.

Task: <corrected task description>

Requirements:
- Produce a VERBOSE architectural plan suitable for /implement-loop or OpenSpec
- Include complete implementation specifications (not just requirements)
- Specify exact code structures, file organizations, and component relationships
- Provide ordered implementation steps with clear dependencies
- Include exit criteria with verification commands

Write the plan to `.claude/plans/` following standard format.
```

Use `subagent_type: "plan-creator-default"` and `run_in_background: true`.

Wait with TaskOutput (block: true).

### Step 3: Report Result

```
## Architectural Planning Complete

**Plan File**: .claude/plans/{task-slug}-{hash5}-plan.md
**Files to Modify**: [count]

### Plan Contains
- Outcome Specification with success criteria
- Architectural Specification with code structure
- Implementation Steps with dependencies
- Exit Criteria with verification script

### Next Steps

1. Review the architectural plan file
2. Implement using one of:
   - `/implement-loop <plan-path>` - Iterative implementation with exit criteria verification
   - [OpenSpec](https://github.com/Fission-AI/OpenSpec) - `/proposal-creator <plan-path>` → `/spec-loop <change-id>`
3. For large plans exceeding context limits: `/beads-creator` → `/beads-loop` for atomic task tracking that survives session boundaries
```

## Workflow Diagram

> **Note**: This diagram shows a simplified view. The agent internally executes 7 phases with multiple revision passes. See agent documentation for full details.

```
/plan-creator <task>
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: PARSE & VALIDATE                                      │
│                                                               │
│  • Grammar/spell check task description                       │
│  • Prepare context for agent                                  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: LAUNCH AGENT                                          │
│                                                               │
│  Agent: plan-creator-default                                  │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES (simplified view - 7 phases internally):   │  │
│  │                                                         │  │
│  │  Phase 1: CODE INVESTIGATION                            │  │
│  │     • Read CLAUDE.md, README.md, DEVGUIDE.md            │  │
│  │     • Glob/Grep for relevant files                      │  │
│  │     • Identify stakeholders, map architecture           │  │
│  │                                                         │  │
│  │  Phase 2: EXTERNAL DOCUMENTATION RESEARCH               │  │
│  │     • Context7/SearxNG for API docs                     │  │
│  │     • Best practices, code examples                     │  │
│  │                                                         │  │
│  │  Phase 2.5: RISK ANALYSIS                               │  │
│  │     • Technical/integration/process risks               │  │
│  │     • Rollback strategy                                 │  │
│  │                                                         │  │
│  │  Phase 3: SYNTHESIS INTO ARCHITECTURAL PLAN             │  │
│  │     • Task, Architecture, Requirements                  │  │
│  │     • Testing Strategy, Success Metrics                 │  │
│  │                                                         │  │
│  │  Phase 4: PER-FILE IMPLEMENTATION INSTRUCTIONS          │  │
│  │     • Full reference implementations                    │  │
│  │     • Migration patterns, dependencies                  │  │
│  │                                                         │  │
│  │  Phase 4.5: PRE-IMPLEMENTATION CHECKLIST                │  │
│  │     • Completeness, consistency, feasibility            │  │
│  │                                                         │  │
│  │  Phase 5: ITERATIVE REVISION (7 passes)                 │  │
│  │     • Structural validation, anti-pattern scan          │  │
│  │     • Dependency chain, consumer simulation             │  │
│  │     • Requirements traceability, quality scoring        │  │
│  │                                                         │  │
│  │  OUTPUT: .claude/plans/{task-slug}-{hash5}-plan.md      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: REPORT RESULT                                         │
│                                                               │
│  Output:                                                      │
│  • Plan file path                                             │
│  • Files to modify count                                      │
│  • Next steps: /implement-loop or OpenSpec                    │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Architectural planner fails | Report error, stop |
| Plan not ready | Report issues, suggest fixes |

## Example Usage

```bash
# Architectural plan for a new feature
/plan-creator Add OAuth2 authentication with Google login

# Architectural plan for a bug fix
/plan-creator Fix the login timeout issue when session expires

# Architectural plan for refactoring
/plan-creator Refactor the auth module to use dependency injection
```
