---
allowed-tools: Task, TaskOutput, Bash, Read, AskUserQuestion
argument-hint: <description>
description: Enhance rough prompt ideas into detailed, effective prompts (project)
model: opus
---

# Prompt Creator

Transform rough, vibe-y prompt ideas into detailed, effective prompts tuned to your codebase.

## Arguments

Takes any rough prompt description:
- `"a prompt that reviews code for security"`
- `"help me debug stuff"`
- `"analyze my recon data and suggest next steps"`

## Instructions

### Step 1: Generate Output Path

```bash
HASH=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 5)
```

Path: `.claude/prompts/{slug}-{hash5}.md`

### Step 2: Launch Agent

Launch `prompt-creator-default` in background:

```
Enhance this rough prompt idea into a detailed, effective prompt.

Description: <user input>
Output file: <generated path>

Research the codebase for context, then write the enhanced prompt.
```

**REQUIRED Task tool parameters:**
```
subagent_type: "essentials:prompt-creator-default"
run_in_background: true
```

Wait with TaskOutput (block: true).

### Step 3: Report Result

```
Prompt created: <file path>

Ready to use. For edits, ask the main agent to modify the file.
```

## Example Usage

```bash
/prompt-creator "a prompt that reviews PRs for security issues"
/prompt-creator "help me analyze pentesting results"
/prompt-creator "debug my async code"
```
