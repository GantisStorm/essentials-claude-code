---
allowed-tools: Task, TaskOutput, Bash, Read, Write, AskUserQuestion
argument-hint: <vibe-description>
description: Build high-quality documentation from vibe descriptions through iterative refinement (project)
---

Build high-quality documentation (READMEs, technical specs, architecture docs, guides) from vibe descriptions using iterative multi-pass revision. The slash command orchestrates the refinement loop while the document-builder-default agent creates/updates document drafts with reflection checkpoints and quality validation.

**IMPORTANT**: The SLASH COMMAND handles ALL orchestration. The agent ONLY creates/updates document drafts.

**IMPORTANT**: Keep orchestrator output minimal. User reviews the draft FILE directly, not in chat.

**Quality Process**: The agent applies 6 validation passes (structural validation, anti-pattern scan, consumer simulation, quality scoring, final review) to ensure documents score ≥40/50 across 5 dimensions.

## Arguments

1. **Vibe description**: Rough description of what the document should cover

## Instructions

### Step 1: Validate Vibe Input

Check if the vibe description is sufficient:

**If vibe is too short (< 5 words):**

Use AskUserQuestion to get more detail:

```
questions:
  - question: "The vibe description is very short. Can you provide more details about what you want the document to cover?"
    header: "More detail"
    multiSelect: false
    options:
      - label: "Provide more detail now"
        description: "I'll describe what I want in more detail"
      - label: "Proceed anyway"
        description: "Continue with the short vibe and let the agent infer"
```

If user chooses "Provide more detail now", use their additional input as the vibe.

If user chooses "Proceed anyway", continue with the original vibe.

### Step 2: Generate Draft File Path

Create a unique draft file path:
- Pattern: `.claude/plans/document-builder-{slug}-{hash5}-draft.md`
- Derive slug from the vibe (e.g., "readme-api", "architecture-guide", "technical-spec")
- Generate a 5-character random hash to prevent conflicts (lowercase alphanumeric)
- Example: `.claude/plans/document-builder-readme-api-7k3m2-draft.md`

Use Bash to generate random hash if needed:
```bash
# Generate 5-char random hash
echo $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

### Step 3: Launch Document Builder Agent

**CRITICAL**: The SLASH COMMAND orchestrates the refinement loop. The agent ONLY creates/updates document drafts.

Launch `document-builder-default` agent **in background** using Task tool with `run_in_background: true`:

```
Build a high-quality document from this vibe using multi-pass revision with quality validation.

Vibe: <user's vibe description>

Draft file: <generated file path>

## Your Task

You are ONLY responsible for creating the document draft. You do NOT orchestrate or interact with the user.

1. CONTEXT GATHERING:
   - Read project files (CLAUDE.md, README, CONTRIBUTING, existing docs)
   - Understand project patterns and conventions
   - Gather existing documentation style

2. VIBE ANALYSIS:
   - Parse user's vibe description
   - Identify document type and requirements
   - Determine audience and purpose

3. RESEARCH (if needed):
   - Use available MCP tools for context
   - Gather best practices and examples
   - Research domain-specific patterns

4. DRAFT CREATION:
   - Determine document type (README, spec, guide, etc.)
   - Build initial draft following best practices
   - Structure for target audience

5. REFLECTION CHECKPOINT:
   - Verify clarity, completeness, usefulness
   - Ensure best practices alignment
   - Validate audience appropriateness

6. ITERATIVE REVISION (6 passes):
   - Pass 1: Initial draft
   - Pass 2: Structural validation
   - Pass 3: Anti-pattern scan (eliminate vague language)
   - Pass 4: Consumer simulation
   - Pass 5: Quality scoring (≥40/50, all dimensions ≥8)
   - Pass 6: Final review

7. WRITE DRAFT FILE:
   - Write to specified path with quality scores and revision log
   - Include validation status

Return only:
DRAFT_FILE: <path>
ITERATION: 1
STATUS: CREATED

DO NOT orchestrate refinement. The slash command handles all user interaction.
```

Use `subagent_type: "document-builder-default"` when invoking the Task tool.

### Step 4: Wait for Completion

Use `TaskOutput` with `block: true` to wait for the document-builder agent to complete.

Collect agent output:
- Draft file path
- Iteration number
- Status (CREATED)

### Step 5: Report Initial Draft

After agent completes initial draft, output ONLY:

```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: DRAFT CREATED
═══════════════════════════════════════════════════════════════

Draft ready: <file path>

Review the draft file and provide feedback, or say "done" when satisfied.
═══════════════════════════════════════════════════════════════
```

**DO NOT** read or display the draft content. User opens the file directly.

### Step 6: Refinement Loop (Command Orchestrates)

**CRITICAL**: The SLASH COMMAND runs the refinement loop, NOT the agent.

After initial draft, wait for user response:

#### Option A: User Provides Feedback

If user provides refinement request (e.g., "add more examples", "focus on X", "restructure Y"):

1. Launch `document-builder-default` agent again in background:

```
Refine the document based on user feedback using the same multi-pass revision process.

Draft file: <same file path>

User feedback: <their feedback>

## Your Task

You are ONLY responsible for applying changes to the document. You do NOT orchestrate or interact with the user.

REFINEMENT PROCESS:
1. Read existing draft file
2. Parse user's requested changes
3. Apply changes surgically (only what user requested)
4. Re-run all 6 validation passes:
   - Pass 1: Apply user's requested changes
   - Pass 2: Structural validation
   - Pass 3: Anti-pattern scan
   - Pass 4: Consumer simulation
   - Pass 5: Quality re-scoring (maintain ≥40/50)
   - Pass 6: Final review
5. Increment iteration number
6. Update revision history with changes and quality re-assessment
7. Write back to same file

Return only:
DRAFT_FILE: <path>
ITERATION: <n+1>
STATUS: UPDATED

DO NOT orchestrate further refinement. The slash command handles all user interaction.
```

Use `subagent_type: "document-builder-default"` with `run_in_background: true`.

2. Wait for completion using `TaskOutput` with `block: true`

3. Output:
```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: DRAFT UPDATED
═══════════════════════════════════════════════════════════════

Draft updated: <file path> (iteration <N>)

Review and provide more feedback, or say "done".
═══════════════════════════════════════════════════════════════
```

4. Return to Step 6 (loop until user says "done")

#### Option B: User Says "Done"

If user indicates completion (e.g., "done", "looks good", "that's it"):

Output:
```
═══════════════════════════════════════════════════════════════
DOCUMENT BUILDER: COMPLETE
═══════════════════════════════════════════════════════════════

Final draft: <file path>

The document is ready for use. You can:
- Move it to your project root (for READMEs)
- Add it to your docs/ folder
- Use it as-is or continue editing manually

═══════════════════════════════════════════════════════════════
```

Exit refinement loop.

## Workflow Diagram

```
/document-builder <vibe>
    │
    ▼
┌─────────────────────┐
│ Validate vibe input │
│ Generate draft path │
└─────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│ Launch document-builder-default                  │◄── run_in_background: true
│ (create draft ONLY)                              │
│                                                  │
│  PHASE 0-4: Context, Analysis, Research, Draft   │
│  PHASE 4.5: Reflection Checkpoint (ReAct)        │
│  PHASE 5: Iterative Revision (6 passes)          │
│    - Pass 1: Initial draft                       │
│    - Pass 2: Structural validation               │
│    - Pass 3: Anti-pattern scan                   │
│    - Pass 4: Consumer simulation                 │
│    - Pass 5: Quality scoring (≥40/50)            │
│    - Pass 6: Final review                        │
│  PHASE 6: Write draft with scores & revision log │
└──────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────┐
│ TaskOutput (block)  │◄── Wait for completion
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Report: "Draft      │
│ ready"              │◄── minimal output
└─────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────┐
│ REFINEMENT LOOP (in command)                      │
│                                                   │
│  User reviews file → Provides feedback OR "done"  │
│                                                   │
│  If feedback:                                     │
│  ├─► Launch agent (Phase 7: refine)              │◄── run_in_background: true
│  ├─► Wait for completion                         │
│  ├─► Report "Draft updated"                      │
│  └─► Loop back                                   │
│                                                   │
│  If "done":                                       │
│  └─► Report "Complete" and exit                  │
└───────────────────────────────────────────────────┘
```

## Key Architecture Points

1. **Slash Command Orchestrates**: The command file (document-builder.md) handles refinement loop
2. **Agent Only Creates Documents**: The agent (document-builder-default.md) ONLY creates/updates drafts
3. **No User Interaction in Agent**: Agent never asks questions, just creates/updates
4. **Iterative Refinement**: Command runs loop, user provides feedback, agent applies changes
5. **Multi-Pass Quality**: Agent ensures all documents pass 6 validation passes
6. **Minimal Output**: Agent returns DRAFT_FILE, ITERATION, STATUS only

## Error Handling

| Scenario | Action |
|----------|--------|
| Vibe too short (<5 words) | Ask user for more detail via AskUserQuestion |
| Agent fails | Report error, offer retry |
| File write fails | Report error, suggest checking permissions |
| Draft file missing during refinement | Report error, suggest starting fresh |
| Invalid document type | Agent makes best judgment based on vibe |

## Example Usage

```bash
# Create initial draft
/document-builder "a README for our new GraphQL API with authentication, rate limiting, and webhook examples"

# Command creates draft, user reviews file

# User provides feedback
User: "add more authentication examples with JWT tokens"

# Command launches agent to refine, reports update

# User continues refining
User: "add troubleshooting section for common errors"

# Command launches agent again, reports update

# User finishes
User: "done"

# Command reports completion
```

## Common Document Types

The document-builder can create:

**Project Documentation:**
- README.md - Project overview, setup, usage
- CONTRIBUTING.md - Contribution guidelines
- ARCHITECTURE.md - System architecture documentation
- API.md - API reference documentation
- CHANGELOG.md - Version history and release notes

**Technical Specifications:**
- Requirements specs - Detailed requirements documents
- Design specs - Technical design documentation
- Integration specs - Integration guidelines
- Security specs - Security requirements and policies

**Guides:**
- User guides - End-user documentation
- Developer guides - Development workflow documentation
- Deployment guides - Deployment procedures
- Migration guides - Version migration instructions

**Reference Materials:**
- Best practices - Project coding standards
- Style guides - Code style and conventions
- Troubleshooting guides - Common issues and solutions

## Integration

Document Builder creates documentation for:
- Project repositories (README, CONTRIBUTING)
- Technical specifications (design docs, API specs)
- User documentation (guides, tutorials)
- Internal documentation (architecture, runbooks)

After building a document:
- Move to appropriate location (root, docs/, etc.)
- Commit to version control
- Update as project evolves
- Refine with `/document-builder <draft-file> "feedback"`

## When to Use Document Builder

**Use `/document-builder` when:**
- Creating new documentation from scratch
- Need structured, professional documentation
- Want consistent documentation style
- Building comprehensive guides or specs
- Documenting complex systems or APIs

**Don't use when:**
- Simple one-paragraph documentation (write directly)
- Updating existing docs (use editor or Edit tool)
- Documentation is code-generated (use code tools)
