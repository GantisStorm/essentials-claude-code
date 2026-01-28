# Slash Command Template

Standard structure for slash commands in `essentials/commands/*.md`.

---

## Template Structure

````markdown
---
allowed-tools: <Tool1, Tool2, ...>
argument-hint: "<argument pattern>"
description: <One-line description>
context: fork  # Optional: runs in isolated context
model: opus    # Optional: opus (default), sonnet, or haiku
---

# <Command Title>

<One sentence overview.>

## Arguments

<Description of arguments with examples>

## Instructions

### Step 1: <Step Name>

<Step description with code blocks if needed>

### Step 2: Launch Agent

Launch `<agent-name>`:

```
<Agent prompt with requirements and phases>

Return:
<expected return format>
```

Use `subagent_type: "<agent-type>"` and `run_in_background: true`.

### Step 3: Report Result

```
## <Result Title>

**<Key field>**: <value>

Next Steps:
1. <step>
2. <step>
```

## Error Handling

| Scenario | Action |
|----------|--------|
| <error> | <action> |

## Example Usage

```bash
/<command> <example>
```
````

---

## Section Requirements

### Frontmatter (Required)
- `allowed-tools`: Comma-separated list of tools
- `argument-hint`: Pattern showing expected arguments
- `description`: Single-line description
- Optional: `context: fork` for heavy background agents
- Optional: `model: opus|sonnet|haiku` - Model selection for cost optimization (default: opus)
  - `opus`: Complex reasoning tasks (creators, planners)
  - `haiku`: Fast/cheap iterative tasks (loops, cancels)

### Title & Overview (Required)
- H1 title matching command name
- One sentence description

### Arguments (Required)
- What arguments are accepted
- Examples of usage

### Instructions (Required)
- Numbered steps
- Agent launch format with `subagent_type` and `run_in_background`
- Result reporting format

### Error Handling (Required)
- Table with Scenario and Action columns
- Common failure cases

### Example Usage (Required)
- Bash code block with examples

---

## Special Command Types

### Cancel Commands

For commands that cancel loops:

```markdown
---
allowed-tools: Bash
description: Cancel active <loop-name> loop
model: opus
---

# Cancel <Loop Name>

Cancel the active <loop-name> loop.

## Instructions

1. Check if state file exists
2. If exists: Remove file, report cancellation
3. If not: Report "No active loop found"

## After Cancellation

Progress is preserved. Resume with: `/<loop-command>`
```
