# How Essentials Compares

## The One Problem It Solves

```
Human: "Build user authentication"
AI: [writes code]
AI: "Done!"
Human: [runs tests] → 3 failing
Human: "Tests are failing"
AI: [fixes some] → "Fixed!"
Human: [runs tests] → 1 still failing
Human: [gives up, fixes manually]
```

The AI said "done" three times when it wasn't done. This wastes more time than writing code yourself.

**Essentials makes "done" mean actually done.** The loop cannot end until verification passes.

---

## Four Approaches to AI Coding

### Code-First
Generate immediately, hope it works.
```
Request → Generate → "Done"
```
Fast output. High rework when things break. No verification.

### Conversation-First
Interactive back-and-forth, human drives every step.
```
Request ↔ Discuss ↔ Generate ↔ Discuss ↔ Repeat
```
Maximum control. Slow. Human becomes the state machine.

### Spec-First
Create specifications, get approval, then generate.
```
Request → Spec → Approve → Generate → "Done"
```
Good for teams. Process overhead. May still lack verification.

### Plan-First + Verification-Enforced (Essentials)
Plan with exit criteria, loop until verification passes.
```
Request → Plan with Exit Criteria → Loop Until Tests Pass → Done
```
Medium speed. Guaranteed completion. Cannot skip verification.

---

## The Key Difference

Other tools let you declare "done" based on feelings. Essentials requires proof.

```
Other tools:
  AI finishes writing code → "Done"

Essentials:
  AI finishes writing code → Run verification → FAIL → Keep working
  AI fixes issues → Run verification → FAIL → Keep working
  AI fixes more → Run verification → PASS → Done
```

The loop blocks until exit criteria pass. There's no "looks good enough."

---

## What This Means in Practice

**Context Compaction:**
Other tools lose track when context fills up. Essentials re-reads the plan file (external source of truth) and continues.

**Multi-Session Work:**
Other tools start fresh each session. Essentials (with Beads) persists task state across sessions and restarts.

**Stuck Detection:**
Other tools loop forever or give up. Essentials detects when you're stuck (>3 iterations on same task) and offers to decompose into smaller pieces.

**Error Recovery:**
Other tools require you to explain the error. Essentials automatically retries with error context until verification passes.

---

## When Essentials Fits

**Use Essentials when:**
- Completion reliability matters more than speed
- You want verification, not hope
- Complex features that need planning
- Multi-session projects
- You've been burned by premature "done"

**Use something else when:**
- Trivial 2-line fixes (overkill)
- Learning/exploration (use conversation)
- Team collaboration needed (essentials is solo-focused)
- You need parallel execution (essentials is sequential)
- IDE integration required (essentials is terminal-based)

---

## What Essentials Doesn't Do

**No parallel agents** - One task at a time, verified before moving on.

**No team features** - No dashboards, permissions, or multi-user sync.

**No cloud infrastructure** - Runs locally, your code stays on your machine.

**No IDE integration** - Terminal-based, works with any editor.

**No auto-commit** - You decide when code is ready to commit.

If you need those things, excellent tools exist. Essentials solves a different problem.

---

## The Trade-Off

```
Speed vs Correctness:
  Code-first:   Fast first output, slow to actually finish
  Essentials:   Slower first output, fast to actually finish

Process vs Freedom:
  Code-first:   No structure, unpredictable results
  Essentials:   Structured workflow, predictable completion
```

Planning looks like overhead until you count the hours debugging premature "done."

---

## Scaling to Task Size

Don't use a sledgehammer for thumbtacks:

```
Trivial (1-2 files):     Just ask Claude directly
Simple (single session): /plan-creator → /implement-loop
Medium (want review):    Plan → /proposal-creator → /spec-loop
Large (multi-session):   Plan → Proposal → /beads-creator → /beads-loop
```

Match the workflow to the task. Essentials provides all three tiers.

---

## The Bottom Line

Essentials does one thing: **ensures "done" means done.**

Not "probably done." Not "looks done." Not "the AI said done."

Actually done, with passing tests and verified exit criteria.

If you've spent more time debugging AI code than it would have taken to write it yourself, Essentials fixes that. The loop won't end until verification passes.
