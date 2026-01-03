# Essentials for Claude Code — Complete Guide

Detailed documentation for all commands, workflows, and integration options.

---

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/plan-creator <task>` | **Agent:** `plan-creator-default`<br><br>Create comprehensive architectural implementation plans with full codebase context. Plans specify the **HOW**, not just the **WHAT**.<br><br>**Phases:** Context Gathering (read CLAUDE.md, README.md, DEVGUIDE.md) → Codebase Exploration (Glob/Grep relevant files) → Plan Generation (outcome spec, architectural spec, implementation steps) → Exit Criteria (verification commands)<br><br>**Output:** `.claude/plans/{task-slug}-{hash5}-plan.md` |
| `/bug-plan-creator <error>` | **Agent:** `bug-plan-creator-default`<br><br>Deep bug investigation with evidence-based root cause analysis. Accepts error messages, stack traces, log files, or diagnostic commands.<br><br>**Phases:** Evidence Collection → Project Context (CLAUDE.md, git log/blame) → Code Path Tracing → Line-by-Line Analysis → Regression Analysis → Architectural Fix Plan (exact file:line changes) → Exit Criteria (verification commands)<br><br>**Output:** `.claude/plans/bug-fix-{desc}-{hash5}-plan.md` |
| `/code-quality-plan-creator <files>` | **Agent:** `code-quality-plan-creator-serena` (one per file, parallel)<br><br>LSP-powered 11-dimension code quality analysis. Spawns one agent per file for parallel analysis.<br><br>**Phases:** Context Gathering → LSP Symbol Extraction (`get_symbols_overview`, `find_symbol`) → Reference Verification (`find_referencing_symbols`, detect unused code) → Call Hierarchy Mapping → Quality Analysis (SOLID, DRY, KISS, YAGNI, OWASP, complexity) → Exit Criteria (verification commands)<br><br>**Target:** ≥9.1/10 score<br>**Output:** `.claude/plans/code-quality-{filename}-{hash5}-plan.md` |
| `/proposal-creator [input]` | **Agent:** `proposal-creator-default`<br><br>Convert architectural plans, descriptions, or context into validated OpenSpec change proposals. Bridges planning phase with OpenSpec workflow.<br><br>**Input Types:** Plan file path (`.claude/plans/*.md`), task description, or current context<br><br>**CRITICAL - Plan Preservation:** When converting a plan, preserves ALL implementation details:<br>• Reference Implementation (FULL code) → design.md<br>• Exit Criteria (EXACT commands) → tasks.md<br>• Migration Patterns (before/after) → design.md<br>• TypeScript interfaces (unchanged) → design.md<br>• plan_reference → ALL files (for recovery)<br><br>**Phases:** Validate Environment → Extract ALL sections from plan → Create proposal.md (with plan_reference) → Create design.md (with Reference Implementation) → Create tasks.md (with Exit Criteria) → Create specs/*.md → Validate<br><br>**Output:** `openspec/changes/<change-id>/` with plan_reference in all files |
| `/implement-loop <plan>` | **Agent:** — (orchestrator only)<br><br>Execute plan iteratively until all todos complete AND exit criteria pass. Works with plans from `/plan-creator`, `/bug-plan-creator`, `/code-quality-plan-creator`.<br><br>**Loop:** Read Plan → Create Todos → Implement (in_progress → completed) → Run Exit Criteria → If fail, fix and retry → Loop ends when all criteria pass<br><br>**Stop:** Exit criteria pass, max iterations, or `/cancel-implement` |
| `/cancel-implement` | **Agent:** — (orchestrator only)<br><br>Gracefully stop active implement loop. Removes `.claude/implement-loop.local.md` state file while preserving todo progress for reference. |
| `/codemap-creator [dir]` | **Agent:** `codemap-creator-serena`<br><br>Generate comprehensive JSON code map with LSP symbol extraction and reference verification.<br><br>**Phases:** File Discovery (`list_dir` recursive) → Symbol Extraction (`get_symbols_overview`: imports, classes, functions) → Reference Verification (`find_referencing_symbols`, mark `verified_used` or `potentially_unused`) → Dependency Mapping → Summary Generation<br><br>**Args:** `[dir]` defaults to `.`, `--ignore "patterns"`<br>**Output:** `.claude/maps/code-map-{dir}-{hash5}.json` |
| `/prompt-creator <description>` | **Agent:** `prompt-creator-default`<br><br>Transform natural language descriptions into precise, effective prompts through multi-pass validation.<br><br>**Phases:** Context Gathering → Analysis → Build Prompt (Role, Context, Instructions) → Quality Validation (6 passes: clarity, completeness, consistency, edge cases, format, final review)<br><br>**Output:** `.claude/prompts/prompt-creator-{slug}-{hash5}.md` |
| `/document-creator <dir>` | **Agent:** `document-creator-serena`<br><br>Generate DEVGUIDE.md architectural documentation with LSP-verified patterns and code templates.<br><br>**Phases:** Directory Analysis (`list_dir`, detect language/framework) → LSP Symbol Extraction (`get_symbols_overview`, `find_symbol`) → Pattern Identification (design patterns) → Reference Mapping (`find_referencing_symbols`) → DEVGUIDE Generation (Overview, Templates, Patterns, Best Practices)<br><br>**Output:** `DEVGUIDE.md` (or `DEVGUIDE_N.md` if exists) |
| `/mr-description-creator` | **Agent:** `mr-description-creator-default`<br><br>Create MR/PR descriptions via `gh` (GitHub) or `glab` (GitLab) CLI with auto-platform detection.<br><br>**Orchestrator:** Detect Platform → Validate Prerequisites (CLI, auth, feature branch) → Auto-detect Action (create/update) → Gather Git Context<br><br>**Agent:** Analyze Changes (categorize commits) → Generate Description (title, summary, changes, testing) → Apply via CLI<br><br>**Args:** `--template "markdown"` for custom format |
| `/spec-loop <change-id>` | **Agent:** — (orchestrator only)<br><br>Implement an OpenSpec change iteratively, keeping tasks.md in sync until all tasks complete.<br><br>**Loop:** Read proposal.md/design.md/tasks.md → Create Todos → Implement each task → Mark `[x]` in tasks.md → Repeat until all tasks complete<br><br>**Args:** `--max-iterations N`<br>**Stop:** All tasks marked `[x]`, max iterations, or `/cancel-spec-loop` |
| `/cancel-spec-loop` | **Agent:** — (orchestrator only)<br><br>Gracefully stop active spec loop. Removes `.claude/spec-loop.local.md` state file while preserving task progress in tasks.md. |
| `/beads-creator <path>` | **Agent:** `beads-creator-default`<br><br>Convert OpenSpec or SpecKit specifications into self-contained Beads issues with dual back-references. Automates Stage 4 of the 5-stage workflow.<br><br>**CRITICAL - Context Chain:** Each bead includes BOTH:<br>• Spec Reference → specs/*.md (requirements, scenarios)<br>• Plan Reference → source plan (full implementation code)<br>• Reference Implementation → FULL code from design.md<br>• Exit Criteria → EXACT commands from tasks.md<br><br>**Phases:** Extract plan_reference from proposal.md → Create Epic (with context chain) → Create Child Beads (self-contained with dual refs) → Set Dependencies → Create .beads-mapping.json (with plan_reference) → Verify<br><br>**Input:** OpenSpec `openspec/changes/<name>/` or SpecKit `.specify/`<br>**Output:** Beads epic + tasks with context chain: Bead → Spec → Plan |
| `/beads-loop` | **Agent:** — (orchestrator only)<br><br>Execute beads iteratively until all ready tasks complete. Stage 5 of the 5-stage workflow.<br><br>**Loop:** `bd ready` → pick task → `bd show <id>` → `bd update --status in_progress` → implement → `bd close --reason "Done"` → repeat until no ready tasks<br><br>**Args:** `--label <label>` filter by label, `--max-iterations N`<br>**Stop:** No ready tasks, max iterations, or `/cancel-beads` |
| `/cancel-beads` | **Agent:** — (orchestrator only)<br><br>Gracefully stop active beads loop. Removes `.claude/beads-loop.local.md` state file while preserving task progress in beads database. |

---

## What Makes Good Architectural Plans

### Why Architectural Planning?

Many coding agents ship with "plan modes," but they have fundamental limitations:

- **No bird's eye view** - The model drafting the plan doesn't see the full codebase
- **Incomplete information** - Plans stem from reading only a few lines at a time
- **Blended phases** - Discovery and planning are mixed, wasting context on orientation
- **Missed relationships** - Important dependencies between classes may not be detected

Architectural planning with full context solves these problems. When you understand the entire codebase structure before planning, you can specify exactly **HOW** to implement, not just **WHAT** to implement.

### What Good Plans Include

#### 1. Outcome Specification
- What the final product should do after changes
- Success criteria and expected behavior
- Edge cases to handle

#### 2. Architectural Specification
- How new code should be structured
- Which parts of the codebase are affected
- What each component should do exactly
- Dependencies and relationships between modules

#### 3. Implementation Steps
- Ordered list of changes to make
- Clear, verifiable sub-tasks
- Dependencies between steps

#### 4. Exit Criteria
- Verification commands that must pass (tests, lint, typecheck)
- Concrete "done" definition

### Why PRDs Aren't Enough

Many plan modes focus on PRDs (Product Requirements Documents). The problem:

| PRD Approach | Architectural Plan Approach |
|--------------|----------------------------|
| Describes **what** | Specifies **how** |
| Implementation left to agent | Implementation details upfront |
| Agent must re-orient during coding | Minimal ambiguity during coding |
| No code structure guidance | Exact file organization specified |

**PRDs describe what but not how.** Implementation details are left to the implementing model, which means:
- Agent orientation problems return during implementation
- No guidance on code structure or file organization
- The agent may choose suboptimal approaches

**Architectural plans specify implementation details upfront**, so the implementing model encounters minimal ambiguity.

---

## Context Chain: Plan → Spec → Beads

When working through the multi-stage workflows, a chain of back-references ensures no context is lost:

```
Plan (SOURCE OF TRUTH)
 │
 │  Contains: Full implementation code, exit criteria, migration patterns
 │
 └──▶ OpenSpec (proposal.md has plan_reference)
       │
       │  Contains: Reference Implementation (FULL code from plan)
       │            Exit Criteria (EXACT commands from plan)
       │            Migration Patterns (before/after from plan)
       │
       └──▶ Beads (each has spec_ref + plan_ref)
             │
             │  Contains: Requirements, Reference Implementation,
             │            Exit Criteria, dual back-references
             │
             └──▶ Loops (recover from plan if context lost)
```

### Why This Matters

| Without Chain | With Chain |
|---------------|------------|
| Spec summarizes plan → detail lost | Spec has FULL code from plan |
| Bead says "see spec" → context lost | Bead has requirements copied verbatim |
| Loop loses context → implementation drifts | Loop can recover from plan |
| Exit criteria vague → "done" unclear | Exit criteria EXACT commands |

### Context Recovery

When context is compacted during `/spec-loop` or `/beads-loop`:

1. **Quick**: Read the bead/task - it's self-contained
2. **Deep**: Follow the back-references:
   - `bd show <id>` → find spec_reference + plan_reference
   - Read spec → requirements and scenarios
   - Read plan → full implementation code, exit criteria

---

## Implementation Workflows

Choose based on plan size and complexity:

| Plan Size | Workflow | When to Use | Guide |
|-----------|----------|-------------|-------|
| **Small** | `/plan-creator` → `/implement-loop` | Fits in single context, no hallucination risk | [WORKFLOW-SIMPLE.md](WORKFLOW-SIMPLE.md) |
| **Medium** | `/plan-creator` → OpenSpec → `/spec-loop` | Need spec validation, iterative implementation | [WORKFLOW-SPEC.md](WORKFLOW-SPEC.md) |
| **Large** | `/plan-creator` → OpenSpec → `/beads-creator` → `/beads-loop` | Too big for single context, multi-session | [WORKFLOW-BEADS.md](WORKFLOW-BEADS.md) |

### Quick Links

- **[3-Stage: Self-Contained](WORKFLOW-SIMPLE.md)** — `/plan-creator` → `/implement-loop`
- **[4-Stage: Spec-Driven](WORKFLOW-SPEC.md)** — OpenSpec → `/spec-loop`
- **[5-Stage: With Beads](WORKFLOW-BEADS.md)** — OpenSpec → `/beads-creator` → `/beads-loop`

---

## Reference

### Directory Structure

```
essentials/
├── agents/          # 10 specialized agents
├── commands/        # 15 slash commands
├── hooks/           # Stop hook for implement-loop, spec-loop, beads-loop
├── scripts/         # Setup scripts
└── skills/          # github-cli, gitlab-cli
```

**Project outputs:**
- `.claude/plans/` - Architectural plans
- `.claude/maps/` - Code maps
- `.claude/prompts/` - Generated prompts

### Requirements

- **Claude Code** CLI
- **Serena MCP** - Required for `/code-quality-plan-creator`, `/document-creator`, `/codemap-creator`

### License

MIT
