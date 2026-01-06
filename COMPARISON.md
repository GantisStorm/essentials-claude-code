# How Essentials Compares

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

If you need those things, other excellent tools exist. Essentials solves a different problem.

---

## The Problem Essentials Solves

Most AI coding tools share a common failure mode:

```
Human: "Build user authentication"
AI: [writes code]
AI: "Done! I've implemented authentication."
Human: [runs tests]
Tests: 3 failing, 2 errors
```

The AI said "done" when it wasn't done. This happens because:

1. **No verification requirement** — tools declare completion without checking
2. **Context loss** — long tasks exceed context windows, losing track of requirements
3. **No plan** — coding starts before understanding the full scope
4. **Session boundaries** — multi-day work loses state between sessions

Essentials solves all four.

---

## Feature Comparison

### Planning Phase

| Capability | Typical AI Tools | Essentials |
|------------|------------------|------------|
| Starts coding immediately | Yes | No |
| Creates implementation plan first | Rare | Always |
| Plans include exact verification commands | No | Yes |
| Plans include reference code (50-200+ lines) | No | Yes |
| Human reviews plan before coding | Optional | Required |

**Essentials approach:** You don't write code until you have a plan. The plan includes the exact commands that will verify success.

### Execution Phase

| Capability | Typical AI Tools | Essentials |
|------------|------------------|------------|
| Iterates until user says stop | Yes | No |
| Iterates until AI says "done" | Yes | No |
| Iterates until verification passes | No | **Yes** |
| Can skip verification | Usually | **Never** |
| Shows execution order before each step | Rare | Always |

**Essentials approach:** The loop continues until exit criteria pass. Not until the AI thinks it's done. Not until you're tired of waiting. Until verification actually passes.

### Verification

| Capability | Typical AI Tools | Essentials |
|------------|------------------|------------|
| Suggests running tests | Sometimes | N/A |
| Runs tests automatically | Sometimes | Always |
| Blocks completion if tests fail | **Never** | **Always** |
| Exit criteria defined upfront | Rare | Required |
| Verification script in plan | No | Yes |

**Essentials approach:** Exit criteria are defined in the plan. The loop runs the verification script. If it fails, the loop continues. You cannot skip this.

### Context & Memory

| Capability | Typical AI Tools | Essentials |
|------------|------------------|------------|
| Works within single session | Yes | Yes |
| Survives context compaction | Partially | Yes |
| Survives session boundaries | No | Yes (with Beads) |
| Self-contained task descriptions | No | Yes |
| Back-references for recovery | No | Yes |

**Essentials approach:** Each task contains everything needed to implement it—not references to other files, but actual code. When context compacts, the plan file is the source of truth.

### Task Management

| Capability | Typical AI Tools | Essentials |
|------------|------------------|------------|
| Auto-decomposes large tasks | Rare | Yes |
| Threshold-based decomposition | No | Yes |
| Shows priority/dependency order | Rare | Always |
| Tracks progress across todos | Basic | Detailed |

**Essentials approach:** When a plan exceeds thresholds (>5 files, >500 lines, >2 subsystems), it automatically decomposes. You don't need to ask.

---

## Scaling: When to Use What

Essentials provides three workflow tiers:

| Task Size | Workflow | When to Use |
|-----------|----------|-------------|
| **Small** | Plan → Implement | Single session, <5 files |
| **Medium** | Plan → Spec → Implement | Want human review of design |
| **Large** | Plan → Spec → Beads | Multi-session, AI losing track |

Most tools are single-mode. Essentials scales with your task.

---

## What Essentials Does NOT Do

### No Parallel Execution

Essentials runs one task at a time. If you need 5-8 agents working simultaneously on different parts of a codebase, use a parallel orchestration system.

**Why:** Parallel execution adds complexity. Essentials prioritizes correctness over speed. One verified task is worth more than five unverified ones.

### No Team Collaboration

Essentials is designed for individual developers or pair programming with AI. It doesn't integrate with issue trackers, doesn't sync with team dashboards, and doesn't support multiple human collaborators.

**Why:** Team features require infrastructure (databases, APIs, permissions). Essentials stays local and simple.

### No Cloud Infrastructure

Essentials runs entirely on your machine. No cloud accounts, no subscriptions, no data leaving your environment.

**Why:** Simplicity and privacy. Your code stays yours.

### No Multi-Model Orchestration

Essentials works with Claude Code. It doesn't route tasks to different AI models or coordinate between providers.

**Why:** Focus. Claude Code is the tool; Essentials extends it.

---

## The Core Innovation

Most AI coding tools optimize for:
- **Speed** — generate code quickly
- **Breadth** — handle many task types
- **Autonomy** — work without human intervention

Essentials optimizes for:
- **Completion** — actually finish what you started
- **Verification** — prove it works before declaring done
- **Recovery** — handle context limits and session boundaries

**The key insight:** An AI that writes code fast but declares "done" prematurely wastes more time than an AI that writes code methodically and verifies completion.

---

## Decision Guide

### Choose Essentials If:

- You want enforced verification (tests must pass)
- You prefer plan-first development
- You work on multi-session projects
- You've been burned by "done" that wasn't done
- You want simple, local tooling

### Choose Something Else If:

- You need parallel agent execution
- You need team collaboration features
- You need GitHub/GitLab integration
- You need cloud-hosted infrastructure
- You need multi-model orchestration

---

## Summary

| Aspect | Essentials | Typical AI Tools |
|--------|------------|------------------|
| **Philosophy** | Plan first, verify always | Code first, hope for best |
| **Completion** | Exit criteria must pass | AI declares "done" |
| **Execution** | Sequential, verified | Often parallel, unverified |
| **Persistence** | Multi-session (Beads) | Single session |
| **Complexity** | Simple, local | Often complex, cloud |
| **Team** | Solo/pair | Often team-oriented |

**Essentials is for developers who want to actually finish things.**

Not "probably done." Not "looks done." Actually done, with passing tests and verified exit criteria.

If that's what you need, essentials is the only tool that enforces it.
