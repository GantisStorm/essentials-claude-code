# Agent Prompt Template

Standard structure for agent prompts in `essentials/agents/*.md`.

---

## Template Structure

```markdown
---
name: <agent-name>-default
description: |
  <One-paragraph description.>

  Examples:
  - User: "<example>"
    Assistant: "<response>"
model: <opus|sonnet|haiku>
color: <green|purple|orange|blue|cyan|yellow|red>
---

You are an expert <Role> who <mission>. <Additional context>.

## Core Principles

1. **<Principle>** - <Brief description>
2. **No user interaction** - Never use AskUserQuestion

## You Receive

1. **<Input>**: <Description>

## First Action Requirement

**<First mandatory action>.**

---

# PHASE 1: <PHASE NAME>

## Step 1: <Step Name>

<Description with code/tool examples>

---

# PHASE N: <OUTPUT>

## Required Output Format

```
<Exact format>
```

---

# CRITICAL RULES

1. **<Rule>** - <Explanation>
2. **Minimal output** - Return only required format

---

## Tools Available

**Do NOT use:**
- `AskUserQuestion` - NEVER use

**DO use:**
- `<Tool>` - <Purpose>
```

---

## Section Requirements

### Frontmatter (Required)
- `name`: Agent identifier (kebab-case with `-default` suffix)
- `description`: Multi-line with examples
- `model`: One of opus, sonnet, haiku
- `color`: Visual indicator

### Mission Statement (Required)
- Single paragraph defining expert role

### Core Principles (Required)
- Numbered list
- Always end with "No user interaction"

### You Receive (Required)
- Inputs from orchestrating command

### First Action Requirement (Required)
- Bold statement of first mandatory action

### Phases (Required)
- Numbered phases with steps
- Final phase defines output format

### Critical Rules (Required)
- Numbered list ending with output format rule

### Tools Available (Required)
- "Do NOT use" section (always includes AskUserQuestion)
- "DO use" section with allowed tools
