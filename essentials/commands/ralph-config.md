---
allowed-tools: Bash(cat:*), Bash(mkdir:*), Bash(test:*)
argument-hint: "<json|beads>"
description: Write recommended RalphTUI config for json or beads tracker
model: opus
context: fork
---

# Ralph Config

Write the full recommended RalphTUI configuration for Tasks (json) or Beads workflow.

## Arguments

- `json` — Write config for prd.json workflow
- `beads` — Write config for Beads workflow

## Instructions

### Step 1: Validate Argument

If argument is not `json` or `beads`:
```
Usage: /ralph-config <json|beads>

  json   - Config for prd.json tasks workflow
  beads  - Config for Beads workflow
```

### Step 2: Ensure Directory Exists

```bash
mkdir -p .ralph-tui
```

### Step 3: Write Config

**If argument is `json`:**

```bash
cat > .ralph-tui/config.toml << 'EOF'
# RalphTUI config for Tasks (prd.json) workflow
# See: WORKFLOW-TASKS.md#recommended-configurations

configVersion = "2.1"
maxIterations = 0
agent = "claude"
tracker = "json"
autoCommit = false
subagentTracingDetail = "full"

[agentOptions]
model = "claude-opus-4-5-20251101"

[trackerOptions]

[notifications]
sound = "system"
EOF
```

**If argument is `beads`:**

```bash
cat > .ralph-tui/config.toml << 'EOF'
# RalphTUI config for Beads workflow
# See: WORKFLOW-BEADS.md#setup-for-beads

configVersion = "2.1"
maxIterations = 0
agent = "claude"
tracker = "beads-bv"
autoCommit = false
subagentTracingDetail = "full"

[agentOptions]
model = "claude-opus-4-5-20251101"

[trackerOptions]

[notifications]
sound = "system"
EOF
```

### Step 4: Report Result

```bash
cat .ralph-tui/config.toml
```

```
Config written: .ralph-tui/config.toml
Tracker: <json or beads-bv>

Run with:
  ralph-tui run --prd <path>      # json tracker
  ralph-tui run --epic <epic-id>  # beads-bv tracker
```
