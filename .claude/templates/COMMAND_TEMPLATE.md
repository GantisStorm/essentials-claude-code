# Slash Command Template

This template defines the standard structure for slash commands in `essentials/commands/*.md`.

---

## Template Structure

```markdown
---
allowed-tools: <Tool1, Tool2, ...>
argument-hint: "<argument pattern>"
description: <One-line description>
model: <haiku|opus>  # Optional: haiku for loops/cancels, opus for creators
context: fork  # Optional: runs command in isolated context (use for heavy exploration commands)
---

# <Command Title>

<One to two sentence overview of what this command does.>

**IMPORTANT**: <Key behavioral note, e.g., output handling>.

## Why <Feature Name>?

<Brief rationale explaining the benefits of this approach.>

<Bullet points highlighting key advantages>:
- **<Advantage 1>** - <Brief explanation>
- **<Advantage 2>** - <Brief explanation>
- **<Advantage 3>** - <Brief explanation>

## What Good <Output Type> Include

1. **<Section 1>**
   - <Detail 1>
   - <Detail 2>

2. **<Section 2>**
   - <Detail 1>
   - <Detail 2>

3. **<Section 3>**
   - <Detail 1>
   - <Detail 2>

## Arguments

<Description of argument handling>:
- <Argument type 1>: `<example>`
- <Argument type 2>: `<example>`
- <Argument type 3>: `<example>`

## Instructions

### Step 1: <Step Name>

<Description of what to do>

```bash
# Example commands
<command 1>
<command 2>
```

### Step 2: <Step Name>

Launch `<agent-name>` in background:

```
<Agent prompt template>

## Requirements

- <Requirement 1>
- <Requirement 2>

## Process

1. <Phase 1>
2. <Phase 2>
...

Return:
<Return format>
```

Use `subagent_type: "<agent-type>"` and `run_in_background: true`.

### Step 3: <Step Name>

```
## <Output Title>

**<Field 1>**: <value>
**<Field 2>**: <value>

### <Subsection>

<Content>

### Next Steps

1. <Step 1>
2. <Step 2>
3. <Step 3>
```

## Workflow Diagram

> **Note**: <Any notes about the diagram>

```
/<command-name> <arguments>
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 1: <STEP NAME>                                           │
│                                                               │
│  • <Action 1>                                                 │
│  • <Action 2>                                                 │
│  • <Action 3>                                                 │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 2: <STEP NAME>                                           │
│                                                               │
│  Agent: <agent-name>                                          │
│  Mode: run_in_background: true                                │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ AGENT PHASES:                                           │  │
│  │                                                         │  │
│  │  Phase 1: <PHASE NAME>                                  │  │
│  │     • <Action 1>                                        │  │
│  │     • <Action 2>                                        │  │
│  │                                                         │  │
│  │  Phase 2: <PHASE NAME>                                  │  │
│  │     • <Action 1>                                        │  │
│  │     • <Action 2>                                        │  │
│  │                                                         │  │
│  │  Phase N: <PHASE NAME>                                  │  │
│  │     → <Output location>                                 │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────┐
│ STEP 3: <STEP NAME>                                           │
│                                                               │
│  Output:                                                      │
│  • <Output item 1>                                            │
│  • <Output item 2>                                            │
│  • <Output item 3>                                            │
└───────────────────────────────────────────────────────────────┘
```

## Error Handling

| Scenario | Action |
|----------|--------|
| <Error 1> | <Action to take> |
| <Error 2> | <Action to take> |
| <Error 3> | <Action to take> |

## Example Usage

```bash
# <Description of example 1>
/<command-name> <example args 1>

# <Description of example 2>
/<command-name> <example args 2>

# <Description of example 3>
/<command-name> <example args 3>
```
```

---

## Section Requirements

### Frontmatter (Required)
- `allowed-tools`: Comma-separated list of tools the command can use
- `argument-hint`: Pattern showing expected arguments (e.g., `<file1> [file2]`)
- `description`: Single-line description for help text
- Optional: `model: <haiku|opus>` for explicit model selection (haiku for loops/cancels, opus for creators)
- Optional: `context: fork` for commands that spawn heavy background agents (isolates context from main session)
- Optional: `hide-from-slash-command-tool: "true"` for internal commands

### Title & Overview (Required)
- H1 title matching the command name
- One to two sentence description
- **IMPORTANT** note for key behavioral requirements

### Why Section (Recommended)
- Explains the rationale for the approach
- Bullet points with **bold** advantage names
- Helps users understand the value

### What Good Output Includes (Recommended)
- Numbered list of output sections
- Nested bullet points for details
- Helps set expectations

### Arguments (Required)
- Description of what arguments are accepted
- Bullet list with examples
- Handle edge cases (no args, multiple formats)

### Instructions (Required)
- Numbered steps (Step 1, Step 2, etc.)
- Each step has clear actions
- Include example commands/prompts
- Agent launch format with `subagent_type` and `run_in_background`
- Final step shows output format

### Workflow Diagram (Required)
- ASCII box diagram showing flow
- Shows orchestrator steps and agent phases
- Uses consistent box characters: `┌─┐│└─┘▼▶`
- Nested boxes for agent internals

### Error Handling (Required)
- Table format with Scenario and Action columns
- Cover common failure cases
- Clear remediation actions

### Example Usage (Required)
- Code block with bash highlighting
- Multiple examples covering different use cases
- Comments explaining each example

---

## Special Command Types

### Commands with Step Mode

For commands that pause for user confirmation:

```markdown
## Step Mode (Default)

Step mode pauses after <action> for human control.

**After <action>, you MUST use AskUserQuestion:**

```
Use AskUserQuestion with:
- question: "<Question text>"
- header: "<Short header>"
- options:
  - label: "Continue (Recommended)"
    description: "<What continue does>"
  - label: "Stop"
    description: "<What stop does>"
```

Use `--auto` flag to skip pauses.
```

### Cancel Commands

For commands that cancel loops:

```markdown
---
allowed-tools: Bash, Read, TodoWrite
argument-hint: ""
description: Cancel active <loop-name> loop
---

# Cancel <Loop Name>

Cancel the active <loop-name> loop.

## Instructions

1. Set a flag or state indicating the loop should stop
2. Report cancellation to the user

The <loop-command> checks for this flag and will gracefully exit.
```
