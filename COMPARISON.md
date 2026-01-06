# How Essentials Compares to Other AI Coding Tools

## What Essentials Is

**Essentials is a plan-first, verification-enforced workflow system for Claude Code.**

It ensures that when you say "done," you're actually done—tests pass, exit criteria are met, and the work is verified.

## What Essentials Is NOT

Essentials is **not**:

- A parallel agent swarm system
- A team collaboration platform
- A GitHub/GitLab project management integration
- A cloud-hosted AI coding service
- A multi-model orchestration framework
- An IDE extension or editor plugin
- A code review automation system
- A continuous integration tool

If you need those things, other excellent tools exist. Essentials solves a different problem.

---

## The Problem Space

### The Premature Completion Problem

Most AI coding tools share a common failure mode:

```
Human: "Build user authentication"
AI: [writes code]
AI: "Done! I've implemented authentication."
Human: [runs tests]
Tests: 3 failing, 2 errors
Human: "The tests are failing"
AI: [fixes some things]
AI: "Fixed! Should work now."
Human: [runs tests again]
Tests: 1 failing
Human: [gives up, fixes manually]
```

The AI declared "done" multiple times when it wasn't done. This wastes more time than writing the code yourself.

### Why This Happens

| Root Cause | What Goes Wrong |
|------------|-----------------|
| **No verification requirement** | Tools declare completion based on "I wrote code" not "code works" |
| **Optimistic completion** | AI assumes success rather than proving it |
| **Context loss** | Long tasks exceed context windows, losing track of requirements |
| **No plan** | Coding starts before understanding the full scope |
| **Session boundaries** | Multi-day work loses state between sessions |
| **No defined "done"** | Success criteria are vague or undefined |

### The Cost of Premature Completion

```
Time spent with premature "done":
  Initial implementation:     30 minutes
  First "it's broken" cycle:  15 minutes
  Second "still broken" cycle: 20 minutes
  Manual debugging:           45 minutes
  Total:                      110 minutes

Time spent with verified completion:
  Planning:                   10 minutes
  Implementation with loops:  50 minutes
  (Exit criteria pass)
  Total:                      60 minutes
```

**Essentials eliminates premature completion entirely.** The loop cannot end until verification passes.

---

## Philosophy Comparison

### Code-First Tools

**How they work:**
```
User request → Generate code → Declare done
```

**Characteristics:**
- Start coding immediately upon request
- Minimal or no planning phase
- Completion based on "I generated code"
- Fast initial output
- High iteration count when things break

**Best for:** Quick prototypes, simple changes, exploration

**Weakness:** Complex features often require multiple "fix it" cycles

### Conversation-First Tools

**How they work:**
```
User request → Chat about code → Make changes → Chat more → Repeat
```

**Characteristics:**
- Interactive back-and-forth
- Human guides each step
- Git integration for tracking changes
- No autonomous loops
- Session-based memory

**Best for:** Pair programming, learning, small changes

**Weakness:** Human must drive every step; no autonomous completion

### Spec-Driven Tools

**How they work:**
```
User request → Generate specification → Human approves → Generate code
```

**Characteristics:**
- Create specs/PRDs before coding
- Human review of design
- Structured documentation
- Often team-oriented
- May integrate with issue trackers

**Best for:** Teams, enterprise, auditable workflows

**Weakness:** Overhead for small tasks; may still lack verification

### Plan-First + Verification-Enforced (Essentials)

**How it works:**
```
User request → Create plan with exit criteria → Loop until exit criteria pass → Done
```

**Characteristics:**
- Planning is required, not optional
- Exit criteria defined upfront
- Loop blocks until verification passes
- Cannot skip verification
- Multi-session persistence available

**Best for:** Complex features, quality-critical code, multi-session work

**Weakness:** Overhead for trivial tasks; sequential execution

---

## Workflow Pattern Comparison

### Pattern A: Generate and Hope

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Request │────▶│ Generate │────▶│  "Done"  │
└──────────┘     └──────────┘     └──────────┘
                                       │
                                       ▼
                              (hope it works)
```

**Verification:** None or manual
**Iteration:** User-driven "fix this" requests
**Memory:** Session only

### Pattern B: Generate and Iterate

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Request │────▶│ Generate │────▶│  Review  │
└──────────┘     └──────────┘     └────┬─────┘
                      ▲                │
                      │    issues      │
                      └────────────────┘
                             │ looks good
                             ▼
                      ┌──────────┐
                      │  "Done"  │
                      └──────────┘
```

**Verification:** Human review (subjective)
**Iteration:** Based on human feedback
**Memory:** Session only

### Pattern C: Plan Then Execute

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Request │────▶│   Plan   │────▶│ Approve  │────▶│ Execute  │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
                                                        ▼
                                                 ┌──────────┐
                                                 │  "Done"  │
                                                 └──────────┘
```

**Verification:** Plan approval (design only, not execution)
**Iteration:** May require manual intervention
**Memory:** Varies

### Pattern D: Plan, Execute, Verify (Essentials)

```
┌──────────┐     ┌──────────────────┐     ┌──────────┐
│  Request │────▶│ Plan + Exit      │────▶│ Execute  │
└──────────┘     │ Criteria         │     └────┬─────┘
                 └──────────────────┘          │
                                               ▼
                                        ┌─────────────┐
                                        │   Verify    │
                                        │ (run tests) │
                                        └──────┬──────┘
                                               │
                                    ┌──────────┴──────────┐
                                    │                     │
                                  FAIL                  PASS
                                    │                     │
                                    ▼                     ▼
                             ┌──────────┐          ┌──────────┐
                             │ Continue │          │   Done   │
                             │   Loop   │          │ (actual) │
                             └────┬─────┘          └──────────┘
                                  │
                                  └──────▶ (back to Execute)
```

**Verification:** Automated, required, cannot skip
**Iteration:** Automatic until verification passes
**Memory:** Plan file + optional persistent storage (Beads)

---

## Detailed Feature Comparison

### Planning Capabilities

| Capability | Code-First | Conversation | Spec-Driven | Essentials |
|------------|------------|--------------|-------------|------------|
| Creates plan before coding | No | No | Yes | **Required** |
| Plan includes implementation details | N/A | N/A | Varies | Yes (50-200+ lines) |
| Plan includes exact test commands | No | No | Rare | **Yes** |
| Plan includes file paths | No | No | Sometimes | Yes |
| Plan reviewed before execution | No | No | Yes | Yes |
| Plan is source of truth | No | No | Sometimes | **Always** |

### Execution Models

| Capability | Code-First | Conversation | Spec-Driven | Essentials |
|------------|------------|--------------|-------------|------------|
| Autonomous execution | Limited | No | Varies | Yes |
| Iterates until done | No | Manual | Varies | **Yes (enforced)** |
| Shows progress | Basic | Chat | Varies | Detailed status |
| Step-by-step mode | No | Always | Varies | Yes (default) |
| Auto mode | N/A | N/A | Varies | Yes (optional) |
| Cancel gracefully | Varies | N/A | Varies | Yes |

### Verification Models

| Capability | Code-First | Conversation | Spec-Driven | Essentials |
|------------|------------|--------------|-------------|------------|
| Defines success criteria | No | No | Sometimes | **Required** |
| Runs verification automatically | No | No | Rare | **Always** |
| Blocks on verification failure | **No** | **No** | **No** | **Yes** |
| Verification is skippable | Yes | Yes | Yes | **No** |
| Re-runs until pass | No | Manual | No | **Automatic** |

### Memory & Persistence

| Capability | Code-First | Conversation | Spec-Driven | Essentials |
|------------|------------|--------------|-------------|------------|
| Single-session memory | Yes | Yes | Yes | Yes |
| Survives context compaction | Partial | No | Varies | Yes |
| Survives session restart | No | No | Partial | Yes (Beads) |
| Self-contained task info | No | No | Varies | Yes |
| Recovery from interruption | No | No | Varies | Yes |

### Task Decomposition

| Capability | Code-First | Conversation | Spec-Driven | Essentials |
|------------|------------|--------------|-------------|------------|
| Breaks down large tasks | Manual | Manual | Sometimes | **Automatic** |
| Threshold-based splitting | No | No | No | Yes |
| Tracks subtask dependencies | No | No | Varies | Yes |
| Shows execution order | No | No | Varies | Always |
| Priority levels | No | No | Varies | Yes (P0/P1/P2) |

---

## Architecture Approach Comparison

### Centralized vs Distributed

**Centralized (Single Agent):**
- One AI handles everything
- Simple mental model
- Limited parallelism
- **Essentials uses this model**

**Distributed (Multi-Agent Swarm):**
- Multiple specialized agents
- Complex coordination
- Parallel execution possible
- Higher throughput, higher complexity

### Local vs Cloud

**Local Execution:**
- Runs on your machine
- No data leaves your environment
- No subscription fees
- Limited by local resources
- **Essentials uses this model**

**Cloud Execution:**
- Runs on remote servers
- May require subscriptions ($200-500/month typical)
- Can scale resources
- Data leaves your environment
- Often includes team features

### Stateless vs Stateful

**Stateless (Session-Only):**
- Memory cleared between sessions
- Must re-establish context each time
- Simple but limited for long projects

**Stateful (Persistent):**
- Remembers across sessions
- Can resume interrupted work
- More complex but powerful
- **Essentials supports both modes**

---

## Human-in-the-Loop Patterns

### No Loop (Fully Autonomous)

```
Request → AI works → Done (no human input)
```

- Fast execution
- No oversight
- High risk of wrong direction
- Good for well-defined tasks

### Approval Gates

```
Request → AI plans → Human approves → AI executes → Human approves → Done
```

- Human validates key decisions
- Slower but safer
- Common in enterprise tools
- **Essentials step mode approximates this**

### Continuous Collaboration

```
Request ↔ AI suggests ↔ Human guides ↔ AI adjusts ↔ Repeat
```

- Tight human-AI partnership
- Maximum control
- Slowest execution
- Best for learning/exploration

### Verification-Enforced (Essentials)

```
Request → AI plans → Human reviews plan → AI loops → Tests pass → Done
```

- Human reviews plan (not every step)
- AI executes autonomously within plan
- Verification is automated and required
- Balances speed with safety

---

## Scaling Patterns

### Single-Mode Tools

Most tools offer one workflow regardless of task size:

```
Small task:  [Full workflow] → Overhead
Medium task: [Full workflow] → Appropriate
Large task:  [Full workflow] → Insufficient
```

### Multi-Tier Scaling (Essentials)

Essentials scales the workflow to match the task:

```
Small task:  Plan → Implement-Loop        (minimal overhead)
Medium task: Plan → Spec → Spec-Loop      (add human review)
Large task:  Plan → Spec → Beads → Loop   (add persistence)
```

| Task Characteristics | Recommended Tier |
|---------------------|------------------|
| Single session, <5 files | Simple (Plan → Implement) |
| Want design review, <10 files | Medium (Plan → Spec → Implement) |
| Multi-session, >10 files | Large (Plan → Spec → Beads) |
| AI losing track, hallucinating | Large (Plan → Spec → Beads) |

---

## Trade-off Analysis

### Speed vs Correctness

| Approach | Speed | Correctness | Best For |
|----------|-------|-------------|----------|
| Code-first | Fast | Low-Medium | Prototypes |
| Conversation | Slow | Medium | Learning |
| Spec-driven | Medium | Medium-High | Teams |
| **Essentials** | Medium | **High** | Production code |

**Essentials trade-off:** Slightly slower initial output, but total time (including fixes) is lower because verification catches issues immediately.

### Simplicity vs Power

| Approach | Simplicity | Power | Setup Required |
|----------|------------|-------|----------------|
| Code-first | High | Low | Minimal |
| Conversation | High | Medium | Minimal |
| Spec-driven | Low | High | Significant |
| **Essentials** | **Medium** | **High** | Minimal |

**Essentials trade-off:** More structure than code-first, but much simpler than enterprise spec-driven tools.

### Autonomy vs Control

| Approach | Autonomy | Human Control | Risk |
|----------|----------|---------------|------|
| Code-first | High | Low | High |
| Conversation | Low | High | Low |
| Spec-driven | Medium | Medium | Medium |
| **Essentials** | **High** | **Medium** | **Low** |

**Essentials trade-off:** High autonomy (loops automatically) with low risk (verification required).

### Flexibility vs Consistency

| Approach | Flexibility | Consistency | Predictability |
|----------|-------------|-------------|----------------|
| Code-first | High | Low | Low |
| Conversation | High | Low | Low |
| Spec-driven | Low | High | High |
| **Essentials** | **Medium** | **High** | **High** |

**Essentials trade-off:** Less flexible than free-form tools, but highly predictable outcomes.

---

## Use Case Scenarios

### Scenario: Quick Bug Fix (2-line change)

| Approach | Fit | Why |
|----------|-----|-----|
| Code-first | Good | Low overhead, fast |
| Conversation | Good | Simple discussion |
| Spec-driven | Overkill | Too much process |
| **Essentials** | Acceptable | Works but has overhead |

**Recommendation:** Use simpler tools for trivial fixes.

### Scenario: New Feature (Authentication System)

| Approach | Fit | Why |
|----------|-----|-----|
| Code-first | Poor | Will miss edge cases |
| Conversation | Poor | Too complex for chat |
| Spec-driven | Good | Structured approach |
| **Essentials** | **Excellent** | Plan + verification catches issues |

**Recommendation:** Essentials shines here—plan covers scope, verification ensures completion.

### Scenario: Multi-Day Refactoring

| Approach | Fit | Why |
|----------|-----|-----|
| Code-first | Poor | Will lose context |
| Conversation | Poor | No session persistence |
| Spec-driven | Good | Structured documentation |
| **Essentials** | **Excellent** | Beads persist across sessions |

**Recommendation:** Essentials with Beads workflow handles multi-session work.

### Scenario: Team Feature Development

| Approach | Fit | Why |
|----------|-----|-----|
| Code-first | Poor | No collaboration features |
| Conversation | Poor | Single-user |
| Spec-driven | Excellent | Built for teams |
| **Essentials** | Poor | Solo-focused |

**Recommendation:** Use team-oriented tools; Essentials is for individual developers.

### Scenario: Learning/Exploration

| Approach | Fit | Why |
|----------|-----|-----|
| Code-first | Good | Quick experiments |
| Conversation | Excellent | Interactive learning |
| Spec-driven | Poor | Too structured |
| **Essentials** | Poor | Overhead not justified |

**Recommendation:** Use conversational tools for exploration.

---

## What Essentials Does NOT Do

### No Parallel Execution

**What parallel tools offer:**
- 5-8 agents working simultaneously
- Different agents on different files
- Higher throughput for large codebases
- Complex coordination logic

**Why Essentials doesn't:**
- Parallel execution adds significant complexity
- Coordination bugs can cause subtle issues
- One verified task > five unverified tasks
- Sequential is predictable and debuggable

**Choose parallel tools if:** You need maximum throughput and can handle coordination complexity.

### No Team Collaboration

**What team tools offer:**
- Multiple human collaborators
- Issue tracker integration
- Progress dashboards
- Permission systems
- Audit trails for compliance

**Why Essentials doesn't:**
- Team features require infrastructure
- Databases, APIs, authentication
- Essentials stays local and simple
- Solo developers don't need this overhead

**Choose team tools if:** Multiple humans need to collaborate on the same AI-assisted project.

### No Cloud Infrastructure

**What cloud tools offer:**
- Remote execution
- Persistent cloud state
- Team synchronization
- Higher compute resources
- Managed infrastructure

**Why Essentials doesn't:**
- Privacy: your code stays local
- Simplicity: no accounts or subscriptions
- Cost: no monthly fees
- Control: no dependency on external services

**Choose cloud tools if:** You need enterprise features, team sync, or managed infrastructure.

### No IDE Integration

**What IDE-integrated tools offer:**
- Native editor experience
- Inline suggestions
- Visual diff tools
- Integrated debugging
- Familiar interface

**Why Essentials doesn't:**
- Terminal-first design
- Works with any editor
- Simpler implementation
- Claude Code is already terminal-based

**Choose IDE tools if:** You want AI assistance embedded in your editor.

### No Multi-Model Orchestration

**What multi-model tools offer:**
- Route tasks to best model
- Use specialized models for specific tasks
- Balance cost vs capability
- Fallback on failures

**Why Essentials doesn't:**
- Claude Code is the foundation
- Focus over flexibility
- Simpler mental model
- Consistent behavior

**Choose multi-model tools if:** You need to leverage multiple AI providers.

---

## The Core Innovation

### What Most Tools Optimize For

| Priority | Typical Tools | Result |
|----------|---------------|--------|
| 1st | Speed | Fast but often wrong |
| 2nd | Breadth | Handle many cases poorly |
| 3rd | Autonomy | Work alone, declare done incorrectly |

### What Essentials Optimizes For

| Priority | Essentials | Result |
|----------|------------|--------|
| 1st | **Completion** | Actually finish |
| 2nd | **Verification** | Prove it works |
| 3rd | **Recovery** | Handle interruptions |

### The Key Insight

```
Traditional:
  Time to "done" = generation time
  Time to ACTUALLY done = generation + debugging + fixing + retesting

Essentials:
  Time to done = planning + verified implementation
  Time to ACTUALLY done = same (verification is built-in)
```

An AI that writes code fast but declares "done" prematurely wastes more time than an AI that writes code methodically and verifies completion.

---

## Decision Matrix

### Task Characteristics

| If Your Task Has... | Best Approach |
|---------------------|---------------|
| 1-2 files, simple change | Code-first |
| Learning/exploration goal | Conversation |
| Team collaboration need | Team/spec-driven |
| Complex feature, quality matters | **Essentials** |
| Multi-session duration | **Essentials** |
| Strict completion requirements | **Essentials** |

### Your Preferences

| If You Prefer... | Best Approach |
|------------------|---------------|
| Maximum speed | Code-first |
| Maximum control | Conversation |
| Maximum collaboration | Team tools |
| **Maximum completion reliability** | **Essentials** |
| **Verification guarantees** | **Essentials** |
| **Multi-session persistence** | **Essentials** |

### Your Environment

| If You Need... | Best Approach |
|----------------|---------------|
| Cloud infrastructure | Cloud tools |
| Team features | Team tools |
| IDE integration | IDE plugins |
| **Local, simple, private** | **Essentials** |
| **No subscriptions** | **Essentials** |

---

## Summary Comparison

| Aspect | Code-First | Conversation | Spec-Driven | Essentials |
|--------|------------|--------------|-------------|------------|
| **Planning** | None | None | Required | Required |
| **Verification** | None | Manual | Optional | **Enforced** |
| **Completion** | AI declares | Human decides | Varies | **Tests pass** |
| **Iteration** | Manual | Manual | Varies | **Automatic** |
| **Persistence** | Session | Session | Varies | **Multi-session** |
| **Parallelism** | No | No | Sometimes | No |
| **Team** | No | No | Yes | No |
| **Cloud** | Varies | Varies | Often | No |
| **Complexity** | Low | Low | High | Medium |
| **Best For** | Prototypes | Learning | Teams | **Production** |

---

## Context Window Management

### The Context Crisis

AI coding tools face a fundamental constraint: limited context windows. When context fills up:

```
Early session:
  AI: "I'll implement the UserAuth class with these 5 methods..."
  [Clear understanding, good code]

Late session (context full):
  AI: "I'll implement the UserAuth class..."
  [Forgets 2 methods, misses edge cases, contradicts earlier decisions]
```

### How Different Approaches Handle Context

**Code-First Tools:**
- Start fresh each request
- No memory of previous work
- Context fills → quality degrades
- User must re-explain requirements

**Conversation Tools:**
- Accumulate context during chat
- Eventually hit limits
- Summarization loses details
- Long sessions degrade quality

**Spec-Driven Tools:**
- External documents hold requirements
- Can re-read specs when needed
- Better than pure memory
- Still vulnerable to mid-task compaction

**Essentials:**
- Plan file is external source of truth
- Re-read on context compaction
- Beads are fully self-contained
- Each bead has complete requirements (no "see design.md")
- Recovery protocol: read plan → check todos → continue

### Self-Contained vs Reference-Based

| Style | Example | On Compaction |
|-------|---------|---------------|
| Reference | "See design.md for auth flow" | Must re-read, may lose context |
| **Self-contained** | "Full 50-line auth implementation here" | Everything needed is present |

**Essentials requirement:** Every bead must be implementable with ONLY its description. References are for disaster recovery, not primary content.

---

## Error Recovery Patterns

### When Things Go Wrong

Every AI coding tool encounters failures:
- Tests fail
- Types don't match
- Dependencies conflict
- Edge cases break

How tools respond defines their usefulness.

### Recovery Approaches

**No Recovery (Code-First):**
```
AI: "Here's the implementation"
User: "It doesn't work"
AI: "Let me try again" [starts from scratch]
```
- Each fix attempt is independent
- No learning from failures
- May repeat same mistakes

**Manual Recovery (Conversation):**
```
User: "Tests fail with error X"
AI: "Let me analyze that error"
User: "Now error Y"
AI: "That's related to..."
```
- Human guides recovery
- Thorough but slow
- Requires human expertise

**Automated Recovery (Essentials):**
```
Loop iteration 1: Implement
  [tests fail]
Loop iteration 2: Fix based on failure
  [still failing]
Loop iteration 3: Try different approach
  [tests pass]
Done.
```
- Automatic retry on failure
- Context of previous attempts
- Continues until success

### Failure Memory

| Approach | Remembers Failures | Adapts Strategy |
|----------|-------------------|-----------------|
| Code-first | No | No |
| Conversation | During session | With human help |
| Spec-driven | Varies | Varies |
| **Essentials** | Yes (in loop) | Yes (automatic) |

---

## Cost and Efficiency Analysis

### Token Economics

AI coding involves significant token usage:

| Activity | Tokens (typical) |
|----------|------------------|
| Read codebase | 10,000-50,000 |
| Generate code | 2,000-10,000 |
| Iterate on fix | 5,000-15,000 |
| Re-explain context | 5,000-20,000 |

### Cost Patterns by Approach

**Code-First:**
```
Initial: $0.10 (fast generation)
Fix #1:  $0.15 (re-explain + fix)
Fix #2:  $0.20 (more context needed)
Fix #3:  $0.25 (getting complicated)
Total:   $0.70 for one feature
```

**Conversation:**
```
Chat 1:  $0.05 (small exchange)
Chat 2:  $0.08 (more context)
Chat 3:  $0.12 (accumulated history)
...
Chat 20: $0.50 (long conversation)
Total:   Variable, grows over time
```

**Essentials:**
```
Planning: $0.15 (thorough analysis)
Loop 1:   $0.20 (implementation)
Loop 2:   $0.10 (fix, has context)
Loop 3:   $0.05 (final fixes)
Total:    $0.50 for verified feature
```

### Total Cost of Ownership

| Factor | Code-First | Conversation | Essentials |
|--------|------------|--------------|------------|
| AI tokens | Low-Medium | Medium-High | Medium |
| Human time debugging | High | Medium | Low |
| Re-work from failures | High | Medium | Low |
| **Total effective cost** | High | Medium | **Low** |

Planning looks expensive upfront but reduces total cost by avoiding re-work.

---

## Stuck Detection and Recovery

### The Infinite Loop Problem

AI tools can get stuck:
- Same error repeated
- Going in circles
- Making things worse
- Not recognizing failure

### Detection Methods

**No Detection (Code-First):**
- User notices something's wrong
- AI keeps generating confidently
- No automatic intervention

**Time-Based Detection:**
- "It's been 30 minutes on this task"
- Trigger: elapsed time
- Problem: some tasks legitimately take long

**Iteration-Based Detection:**
- "This is the 4th attempt at the same task"
- Trigger: iteration count
- More reliable for detecting actual loops

**Progress-Based Detection:**
- "Tests passing went from 5 → 4 → 3"
- Trigger: metrics going wrong direction
- Best signal but requires measurable progress

### Essentials' Approach

**Multi-signal detection:**
```
Stuck triggers:
  - Same task for >3 iterations
  - Same error repeated
  - Time threshold exceeded (configurable)

When triggered:
  - Show decomposition option
  - Break task into smaller pieces
  - Each piece has own exit criteria
```

**Decomposition as recovery:**
```
Before: "Implement authentication" (stuck)
After:
  - "Add User model" (specific)
  - "Add password hashing" (specific)
  - "Add login endpoint" (specific)
  - "Add tests" (specific)
```

Smaller tasks = clearer success criteria = fewer loops.

---

## State Management Deep Dive

### What State Needs Tracking

During complex tasks:
- What's done vs pending
- Current context and decisions
- Previous attempts and failures
- Dependencies between tasks
- Success criteria for each piece

### State Management Approaches

**In-Memory Only:**
```
State lives in: AI context window
Survives: Current request only
Recovery: Start over
```

**Conversation History:**
```
State lives in: Chat log
Survives: Current session
Recovery: Re-read conversation (token-expensive)
```

**External Documents:**
```
State lives in: Files (plans, specs)
Survives: Indefinitely
Recovery: Re-read files
```

**Structured Database:**
```
State lives in: Specialized storage
Survives: Indefinitely
Recovery: Query current state
```

### Essentials' State Model

**Three tiers of state:**

| Tier | Storage | Survives | Use Case |
|------|---------|----------|----------|
| Session | TodoWrite | Session | Simple tasks |
| Plan | `.claude/plans/` | Indefinitely | Medium tasks |
| Persistent | Beads database | Indefinitely | Large tasks |

**State recovery protocol:**
```
On context compaction:
1. Read plan file (source of truth)
2. Check todo list (current progress)
3. Continue next pending item

On session restart:
1. bd ready (what's available)
2. bd show <id> (full context)
3. Implement (all info in bead)
```

---

## Documentation and Artifacts

### What Tools Produce

| Approach | Artifacts Created |
|----------|-------------------|
| Code-first | Code only |
| Conversation | Chat log (unstructured) |
| Spec-driven | PRDs, specs, diagrams |
| **Essentials** | Plans, specs, code maps |

### Essentials' Artifact Chain

```
/plan-creator
  └── .claude/plans/feature-plan.md
        │
        ├── Reference Implementation (50-200+ lines)
        ├── Migration Patterns (before/after)
        ├── Exit Criteria (exact commands)
        └── Files to Modify (paths)

/proposal-creator
  └── openspec/changes/feature/
        ├── proposal.md (motivation)
        ├── design.md (implementation)
        ├── tasks.md (checklist)
        └── specs/ (requirements)

/codemap-creator
  └── .claude/maps/code-map.json
        ├── Symbol definitions
        ├── Cross-references
        └── Dependency graph
```

### Traceability

Can you trace back what happened and why?

| Approach | Traceability | Audit Trail |
|----------|--------------|-------------|
| Code-first | None | Git only |
| Conversation | Scroll chat | Unstructured |
| Spec-driven | Documents | Good |
| **Essentials** | Full chain | Plan → Spec → Bead → Code |

---

## Anti-Patterns by Approach

### Code-First Anti-Patterns

- "Just make it work" without understanding
- Generating code without reading existing code
- Ignoring test failures
- Over-relying on AI confidence

### Conversation Anti-Patterns

- Very long conversations (context overflow)
- Not summarizing decisions
- Repeating explanations
- Human becoming the state machine

### Spec-Driven Anti-Patterns

- Specs that no one reads
- Over-documentation for simple tasks
- Specs that drift from implementation
- Process for process's sake

### Essentials Anti-Patterns

- Using full workflow for trivial changes
- Vague exit criteria ("tests pass" vs exact command)
- Not reviewing plans before execution
- Forcing beads on single-session work

### How to Avoid Anti-Patterns

| Anti-Pattern | Solution |
|--------------|----------|
| Too much process | Match tier to task size |
| Vague criteria | Write exact verification commands |
| Skipping review | Review plans before `/implement-loop` |
| Wrong tool | Simple changes → simple tools |

---

## Integration with Development Workflows

### Git Integration

| Approach | Git Usage |
|----------|-----------|
| Code-first | Optional, manual |
| Conversation | Some tools integrate |
| Spec-driven | Usually integrated |
| **Essentials** | Manual (user controls commits) |

**Essentials philosophy:** Don't auto-commit. User decides when code is ready. Exit criteria pass ≠ ready to merge.

### CI/CD Integration

| Approach | CI/CD Integration |
|----------|-------------------|
| Code-first | None |
| Conversation | None |
| Spec-driven | Some tools trigger CI |
| **Essentials** | Uses existing CI as verification |

**Essentials approach:** Your test suite IS your exit criteria. If CI fails, the loop continues.

### Code Review Integration

| Approach | Review Integration |
|----------|-------------------|
| Code-first | None |
| Conversation | None |
| Spec-driven | Some tools create PRs |
| **Essentials** | `/mr-description-creator` |

---

## Failure Mode Comparison

### Common Failure Modes

**Code-First Failures:**
- Generates plausible but wrong code
- Misunderstands requirements
- Ignores edge cases
- Over-confident declarations

**Conversation Failures:**
- Context overflow loses early decisions
- Human fatigue leads to acceptance
- Long sessions lose focus
- No forcing function for completion

**Spec-Driven Failures:**
- Specs drift from reality
- Over-engineering for simple tasks
- Team coordination overhead
- Specs become outdated

**Essentials Failures:**
- Overhead not worth it for trivial tasks
- Exit criteria incorrectly specified
- Loop stuck without decomposition
- Sequential bottleneck on parallel-friendly work

### Failure Recovery

| Failure Type | Code-First | Conversation | Essentials |
|--------------|------------|--------------|------------|
| Wrong implementation | Start over | Discuss fix | Loop continues |
| Lost context | Re-explain | Re-read chat | Re-read plan |
| Stuck/looping | User notices | User redirects | Auto-detect |
| Incomplete | User discovers | User tracks | Verification catches |

---

## The Bottom Line

**Essentials is for developers who want to actually finish things.**

Not "probably done." Not "looks done." Not "the AI said done."

Actually done, with passing tests and verified exit criteria.

If you've been burned by premature completion—if you've spent more time debugging AI-generated code than it would have taken to write it yourself—Essentials solves that problem.

The loop won't end until verification passes. That's the guarantee no other approach provides.

### Choose Essentials When:

- Completion reliability matters more than speed
- You want verification, not hope
- You work on multi-session projects
- You prefer plans over improvisation
- You want simple, local tooling

### Choose Something Else When:

- You need parallel execution
- You need team collaboration
- You need cloud infrastructure
- You need IDE integration
- Trivial tasks don't justify the overhead

**Essentials does one thing exceptionally well: it ensures you're actually done when you say you're done.**
