---
description: "Execute a plan file with Agent Teams (contract-first parallel coordination)"
argument-hint: "<plan_path> [--agents N]"
allowed-tools: ["Read", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Bash", "Glob", "Grep"]
model: opus
---

# Plan Team Command

Execute a plan file using Agent Teams — full Claude Code instances coordinated through contracts in tmux split panes. **Requires a plan file.** All agents complete → done.

**Note:** Team, swarm, and loop are all execution modes for plans. Use teams when components need to integrate and agents need to agree on interfaces (frontend + backend + database). Use swarms for independent parallel tasks. Use loops for sequential work.

Uses Claude Code's built-in Task Management System for dependency tracking and visual progress (`ctrl+t`).

## Supported Plan Types

This command works with plans from:
- `/plan-creator` - Implementation plans
- `/bug-plan-creator` - Bug fix plans
- `/code-quality-plan-creator` - LSP-powered quality plans

## Arguments

- `<plan_path>` (required): Path to the plan file
- `--agents N` (optional): Number of agents (if omitted, determined automatically from plan complexity)

## Instructions

### Step 1: Check Prerequisites

Verify before proceeding:

1. **tmux installed**: Run `which tmux` — if not found, tell the user to install it (`brew install tmux` on macOS, `sudo apt install tmux` on Linux) and exit
2. **Agent Teams enabled**: Run `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` — if not `1`, tell the user to enable it in `~/.claude/settings.json` under `"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}` or export it in their shell profile, and exit

### Step 2: Read the Plan

Read the plan document. Understand:
- What are we building?
- What are the major components/layers?
- What technologies are involved?
- What are the dependencies between components?
- What are the acceptance/exit criteria?

**DO NOT read other files, grep, or explore the codebase** — just parse the plan.

### Step 3: Determine Team Structure

If `--agents N` is specified, use that number. Otherwise, analyze the plan and determine optimal team size:

- **2 agents**: Simple projects with clear frontend/backend split
- **3 agents**: Full-stack apps (frontend, backend, database/infra)
- **4 agents**: Complex systems with additional concerns (testing, DevOps, docs)
- **5+ agents**: Large systems with many independent modules

For each agent, define:
1. **Name**: Short, descriptive (e.g., "frontend", "backend", "database")
2. **Ownership**: What files/directories they own exclusively
3. **Does NOT touch**: What's off-limits (prevents conflicts)
4. **Key responsibilities**: What they're building

### Step 4: Define Contracts

Before spawning agents, define the integration contracts between layers. This focused upfront work is what enables all agents to spawn in parallel without diverging on interfaces. Agents that build in parallel will diverge on endpoint URLs, response shapes, trailing slashes, and data storage semantics unless they start with agreed-upon contracts.

**Map the contract chain** — identify which layers need to agree on interfaces:

```
Database → function signatures, data shapes → Backend
Backend → API contract (URLs, response shapes, SSE format) → Frontend
```

**Author each contract** from the plan with enough specificity that agents can build to it independently:

- **Database → Backend**: Function signatures (CRUD), model definitions, data shapes and types
- **Backend → Frontend**: Exact endpoint URLs (including trailing slash conventions), request/response JSON shapes (exact structures, not prose), status codes for success and error cases, SSE event types with exact JSON format, response envelopes (flat vs nested)

**Identify cross-cutting concerns** — behaviors that span multiple agents and will fall through the cracks unless explicitly assigned. Identify these from the plan and assign ownership to one agent:
- **Streaming data storage**: Chunks stored individually or accumulated into one row?
- **URL conventions**: Trailing slashes, path parameters, query params — both sides must match exactly
- **Response envelopes**: Flat objects vs nested wrappers — both sides must agree
- **Error shapes**: Status codes and error body format
- **UI accessibility**: Interactive elements need aria-labels for automated testing

**Contract quality checklist** — before including a contract in agent prompts, verify:
- Are URLs exact, including trailing slashes? (`POST /api/sessions/` vs `POST /api/sessions`)
- Are response shapes explicit JSON, not prose? (`{"session": {...}}` not "returns session")
- Are all SSE event types documented with exact JSON?
- Are error responses specified? (404 body, 422 body, etc.)
- Are storage semantics clear? (accumulated vs per-chunk)

### Step 5: Create Task Graph

Create a shared task list. Since contracts are defined upfront, agents can start building immediately — no inter-agent blocking for initial implementation work. Only block tasks that genuinely require another agent's output (like integration testing).

```json
TaskCreate({
  "subject": "Agent 1: Build backend API",
  "description": "Full scope + contracts owned + contracts consumed",
  "activeForm": "Agent 1 building backend API"
})
```

```json
// Integration blocked by all agent tasks
TaskUpdate({ "taskId": "4", "addBlockedBy": ["1", "2", "3"] })
// Exit criteria blocked by integration
TaskUpdate({ "taskId": "5", "addBlockedBy": ["4"] })
```

**Task types:**
- Agent work scopes → one task per agent
- Contract validation + integration testing → blocked by all agent tasks
- Exit criteria → final task, blocked by validation

### Step 6: Spawn Agents

**You are the lead. You do NOT implement code — your role is coordination.** Enter **Delegate Mode** (Shift+Tab) before spawning. Enable tmux split panes (`teammateMode: "tmux"`). Mark each agent task `in_progress`, then spawn all agents simultaneously.

Each agent gets this prompt structure:

```
You are the [ROLE] agent for this build.

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Building
[Relevant section from plan]

## Contracts

### Contract You Produce
[Lead-authored contract this agent is responsible for]
- Build to match this exactly
- If you need to deviate, message the lead and wait for approval before changing

### Contract You Consume
[Lead-authored contract this agent depends on]
- Build against this interface exactly — do not guess or deviate

### Cross-Cutting Concerns You Own
[Integration behaviors this agent is responsible for]

## Coordination
- Message the lead if you discover something that affects a contract
- Ask before deviating from any agreed contract
- Flag cross-cutting concerns that weren't anticipated
- Share with [other agent] when: [trigger]
- Challenge [other agent]'s work on: [integration point]

## Before Reporting Done
Run these validations and fix any failures:
1. [specific validation command]
2. [specific validation command]
Do NOT report done until all validations pass.
```

Spawn all agents, then output "Team of N agents spawned. Coordinating via Delegate Mode." and stay in Delegate Mode.

**Avoid these anti-patterns:**
- Spawning agents without contracts → they diverge on interfaces
- Sequential spawning (database → wait → backend → wait → frontend) → defeats parallelism
- Telling agents to "share contracts with each other" → they won't reliably; lead authors contracts

### Step 7: Facilitate Collaboration

All agents are working in parallel. Keep them aligned and unblock them:

- **Relay messages** between agents when they flag contract issues
- **Mediate contract changes** — if an agent needs to deviate, evaluate the change, update the contract, and notify all affected agents
- **Unblock** agents waiting on decisions
- **Track progress** through the shared task list

**Pre-completion contract diff** — before any agent reports "done":
- "Backend: what exact curl commands test each endpoint?"
- "Frontend: what exact fetch URLs are you calling with what request bodies?"
- Compare and flag mismatches before integration testing

**Cross-review** — each agent reviews another's work:
- Frontend reviews Backend API usability
- Backend reviews Database query patterns
- Database reviews Frontend data access patterns

**Watch for these pitfalls:**
1. File conflicts → two agents editing the same file (assign clear ownership)
2. Lead over-implementing → you start coding (stay in Delegate Mode)
3. Isolated work → agents don't communicate (require explicit handoffs via lead relay)
4. Vague boundaries → "help with backend" (specify exact files/responsibilities)
5. Implicit contracts → "The API returns sessions" (require exact JSON shapes, URLs, status codes)
6. Orphaned cross-cutting concerns → streaming storage, URL conventions, error shapes (explicitly assign to one agent)

### Step 8: Validate and Complete

Validation happens at two levels:

**Agent validation** — before any agent reports "done", they must run their domain-specific validation (included in their spawn prompt). Do NOT accept "done" until validations pass.

**Lead validation (end-to-end)** — after ALL agents return control to you:

1. **Can the system start?** — Start all services, no startup errors
2. **Does the happy path work?** — Walk through the primary user flow
3. **Do integrations connect?** — Frontend calls backend, backend queries database, data flows through all layers
4. **Are edge cases handled?** — Empty states, error states, loading states

If the plan has a Validation section, use those exact commands. If absent, derive validation steps from the acceptance/exit criteria.

If validation fails → identify which agent's domain contains the bug → re-spawn that agent with the specific issue → re-run validation after fix.

The build is complete when: all agents validated their domain, integration points tested, cross-review addressed, plan's exit criteria met, and lead has run end-to-end validation.

When all validation passes → **"Exit criteria passed — team complete"**

## Visual Progress

Press `ctrl+t` to see task progress:
```
Tasks (1 done, 2 in progress, 2 open)
■ #1 Agent 1: Backend API (delegated)
■ #2 Agent 2: Database Layer (delegated)
✓ #3 Agent 3: Frontend Components
□ #4 Contract validation > blocked by #1, #2
□ #5 Exit criteria > blocked by #4
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Plan file not found | Report error and exit |
| tmux not installed | Tell user to install tmux and exit |
| Agent Teams not enabled | Tell user to set env var and exit |
| Agent fails mid-work | Other agents continue; assess contract impact |
| Contract mismatch found | Fix before running exit criteria |
| Context compacted | TaskList → re-read plan → resume coordination |

## Stopping

- Use `/cancel-team` to halt all agents
- Individual agents can be stopped from their tmux pane

## Example Usage

```bash
/plan-team .claude/plans/full-stack-auth.md              # Auto-determine team size
/plan-team .claude/plans/microservice-api.md --agents 5  # 5 agents for complex build
/plan-team .claude/plans/refactor.md --agents 2          # 2 agents for simple split
```
